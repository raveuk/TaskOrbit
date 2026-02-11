import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/saved_location.dart';

enum LocationStatus {
  disabled,
  denied,
  deniedForever,
  granted,
  unknown,
}

class LocationProvider extends ChangeNotifier {
  List<SavedLocation> _savedLocations = [];
  Position? _currentPosition;
  bool _isTracking = false;
  bool _continuousTracking = false;
  LocationStatus _permissionStatus = LocationStatus.unknown;
  StreamSubscription<Position>? _positionStreamSubscription;
  final Map<String, bool> _locationStates = {}; // Track if user is inside each location
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Getters
  List<SavedLocation> get savedLocations => _savedLocations;
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  bool get continuousTracking => _continuousTracking;
  LocationStatus get permissionStatus => _permissionStatus;

  LocationProvider() {
    _initNotifications();
    _loadSavedLocations();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(initSettings);
  }

  Future<void> _loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString('saved_locations');
    if (locationsJson != null) {
      try {
        final List<dynamic> decoded = json.decode(locationsJson);
        _savedLocations = decoded.map((e) => SavedLocation.fromJson(e)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading saved locations: $e');
        _savedLocations = [];
      }
    }
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_savedLocations.map((e) => e.toJson()).toList());
    await prefs.setString('saved_locations', encoded);
  }

  Future<LocationStatus> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _permissionStatus = LocationStatus.disabled;
      notifyListeners();
      return _permissionStatus;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.denied:
        _permissionStatus = LocationStatus.denied;
        break;
      case LocationPermission.deniedForever:
        _permissionStatus = LocationStatus.deniedForever;
        break;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        _permissionStatus = LocationStatus.granted;
        break;
      default:
        _permissionStatus = LocationStatus.unknown;
    }
    notifyListeners();
    return _permissionStatus;
  }

  Future<LocationStatus> requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    switch (permission) {
      case LocationPermission.denied:
        _permissionStatus = LocationStatus.denied;
        break;
      case LocationPermission.deniedForever:
        _permissionStatus = LocationStatus.deniedForever;
        break;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        _permissionStatus = LocationStatus.granted;
        break;
      default:
        _permissionStatus = LocationStatus.unknown;
    }
    notifyListeners();
    return _permissionStatus;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final status = await checkPermission();
      if (status != LocationStatus.granted) {
        final newStatus = await requestPermission();
        if (newStatus != LocationStatus.granted) return null;
      }

      // Force fresh GPS location (not cached)
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: false,
        timeLimit: const Duration(seconds: 15),
      );
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}';
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
    return null;
  }

  Future<List<Location>> getCoordinatesFromAddress(String address) async {
    try {
      return await locationFromAddress(address);
    } catch (e) {
      debugPrint('Error getting coordinates: $e');
      return [];
    }
  }

  // Saved Locations Management
  Future<void> addLocation(SavedLocation location) async {
    _savedLocations.add(location);
    await _saveLocations();
    notifyListeners();
  }

  Future<void> updateLocation(SavedLocation location) async {
    final index = _savedLocations.indexWhere((l) => l.id == location.id);
    if (index != -1) {
      _savedLocations[index] = location;
      await _saveLocations();
      notifyListeners();
    }
  }

  Future<void> deleteLocation(String id) async {
    _savedLocations.removeWhere((l) => l.id == id);
    _locationStates.remove(id); // Clean up geofence state to prevent memory leak
    await _saveLocations();
    notifyListeners();
  }

  SavedLocation? getLocationById(String id) {
    try {
      return _savedLocations.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }

  // Continuous Location Tracking with Battery Warning
  Future<bool> startContinuousTracking({bool showWarning = true}) async {
    if (_isTracking) return true;

    final status = await checkPermission();
    if (status != LocationStatus.granted) {
      final newStatus = await requestPermission();
      if (newStatus != LocationStatus.granted) return false;
    }

    _isTracking = true;
    _continuousTracking = true;

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('continuous_tracking', true);

    // Use platform-specific location settings
    late LocationSettings locationSettings;
    if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.other,
        distanceFilter: 50,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 10),
      );
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onPositionUpdate);

    notifyListeners();
    return true;
  }

  Future<void> stopContinuousTracking() async {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    _continuousTracking = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('continuous_tracking', false);

    notifyListeners();
  }

  void _onPositionUpdate(Position position) {
    _currentPosition = position;
    _checkGeofences(position);
    notifyListeners();
  }

  void _checkGeofences(Position position) {
    for (final location in _savedLocations) {
      final wasInside = _locationStates[location.id] ?? false;
      final isInside = location.isWithinRadius(position.latitude, position.longitude);

      if (!wasInside && isInside) {
        // User entered the location
        _onEnterLocation(location);
      } else if (wasInside && !isInside) {
        // User left the location
        _onLeaveLocation(location);
      }

      _locationStates[location.id] = isInside;
    }
  }

  void _onEnterLocation(SavedLocation location) {
    _showLocationNotification(
      title: 'Arrived at ${location.name}',
      body: 'You have arrived at ${location.name}. Any tasks or habits linked to this location will be reminded.',
      location: location,
    );
  }

  void _onLeaveLocation(SavedLocation location) {
    _showLocationNotification(
      title: 'Left ${location.name}',
      body: 'You have left ${location.name}.',
      location: location,
    );
  }

  Future<void> _showLocationNotification({
    required String title,
    required String body,
    required SavedLocation location,
  }) async {
    await _notifications.show(
      location.id.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'location_reminders',
          'Location Reminders',
          channelDescription: 'Reminders based on your location',
          importance: Importance.high,
          priority: Priority.high,
          color: location.color,
        ),
      ),
    );
  }

  // Check if tracking preference is enabled on startup
  Future<void> restoreTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldTrack = prefs.getBool('continuous_tracking') ?? false;
    if (shouldTrack) {
      await startContinuousTracking(showWarning: false);
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
