import 'dart:math';
import 'package:flutter/material.dart';

enum LocationTrigger { onArrive, onLeave }

// Shared enum for Task and Habit location triggers
enum LocationTriggerType { onArrive, onLeave }

extension LocationTriggerExtension on LocationTrigger {
  String get label {
    switch (this) {
      case LocationTrigger.onArrive:
        return 'When I arrive';
      case LocationTrigger.onLeave:
        return 'When I leave';
    }
  }

  IconData get icon {
    switch (this) {
      case LocationTrigger.onArrive:
        return Icons.login;
      case LocationTrigger.onLeave:
        return Icons.logout;
    }
  }
}

class SavedLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final IconData icon;
  final Color color;
  final int radiusMeters; // Geofence radius
  final DateTime createdAt;

  SavedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.icon = Icons.location_on,
    this.color = Colors.blue,
    this.radiusMeters = 100,
    required this.createdAt,
  });

  SavedLocation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    IconData? icon,
    Color? color,
    int? radiusMeters,
    DateTime? createdAt,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.value,
      'radiusMeters': radiusMeters,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String?,
      icon: IconData(
        (json['iconCodePoint'] as int?) ?? Icons.location_on.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      color: Color((json['colorValue'] as int?) ?? Colors.blue.value),
      radiusMeters: (json['radiusMeters'] as int?) ?? 100,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value as String);
    } catch (_) {
      return DateTime.now();
    }
  }

  // Calculate distance from current position in meters using Haversine formula
  double distanceFrom(double lat, double lng) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat - latitude);
    final double dLng = _toRadians(lng - longitude);
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) * cos(_toRadians(lat)) *
        sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  bool isWithinRadius(double lat, double lng) {
    // Reject invalid coordinates (0.0, 0.0 typically means failed GPS)
    if (lat == 0.0 && lng == 0.0) return false;
    return distanceFrom(lat, lng) <= radiusMeters;
  }

  static double _toRadians(double degree) => degree * pi / 180;
}

// Preset locations with icons
class LocationPresets {
  static const List<LocationPreset> presets = [
    LocationPreset(name: 'Home', icon: Icons.home, color: Color(0xFF6366F1)),
    LocationPreset(name: 'Work', icon: Icons.work, color: Color(0xFF10B981)),
    LocationPreset(name: 'Gym', icon: Icons.fitness_center, color: Color(0xFFEF4444)),
    LocationPreset(name: 'School', icon: Icons.school, color: Color(0xFFF59E0B)),
    LocationPreset(name: 'Library', icon: Icons.local_library, color: Color(0xFF8B5CF6)),
    LocationPreset(name: 'Coffee Shop', icon: Icons.local_cafe, color: Color(0xFF78350F)),
    LocationPreset(name: 'Park', icon: Icons.park, color: Color(0xFF059669)),
    LocationPreset(name: 'Custom', icon: Icons.location_on, color: Color(0xFF3B82F6)),
  ];
}

class LocationPreset {
  final String name;
  final IconData icon;
  final Color color;

  const LocationPreset({
    required this.name,
    required this.icon,
    required this.color,
  });
}
