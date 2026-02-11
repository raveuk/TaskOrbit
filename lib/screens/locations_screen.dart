import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/saved_location.dart';
import '../providers/location_provider.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().checkPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved Locations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTrackingToggle(context, locationProvider),
                  const SizedBox(height: 24),
                  _buildLocationsList(context, locationProvider),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLocationDialog(context),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add Location'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTrackingToggle(BuildContext context, LocationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: provider.continuousTracking
            ? AppTheme.primaryGradient
            : null,
        color: provider.continuousTracking
            ? null
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: provider.continuousTracking
              ? Colors.transparent
              : Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: provider.continuousTracking
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  provider.continuousTracking
                      ? Icons.location_on
                      : Icons.location_off,
                  color: provider.continuousTracking
                      ? Colors.white
                      : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Tracking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: provider.continuousTracking
                            ? Colors.white
                            : null,
                      ),
                    ),
                    Text(
                      provider.continuousTracking
                          ? 'Active - Reminders enabled'
                          : 'Off - Turn on for location reminders',
                      style: TextStyle(
                        fontSize: 13,
                        color: provider.continuousTracking
                            ? Colors.white70
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: provider.continuousTracking,
                onChanged: (value) async {
                  if (value) {
                    _showBatteryWarningDialog(context, provider);
                  } else {
                    provider.stopContinuousTracking();
                  }
                },
                activeTrackColor: Colors.white.withValues(alpha: 0.3),
                activeColor: Colors.white,
              ),
            ],
          ),
          if (provider.continuousTracking) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.battery_alert, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'GPS is active. This may use more battery.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildLocationsList(BuildContext context, LocationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.place, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Your Locations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.savedLocations.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_location,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  'No saved locations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Add locations like Home, Work, or Gym\nto get location-based reminders',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.savedLocations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final location = provider.savedLocations[index];
              return _buildLocationCard(context, location, provider, index);
            },
          ),
      ],
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    SavedLocation location,
    LocationProvider provider,
    int index,
  ) {
    return Dismissible(
      key: Key(location.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        provider.deleteLocation(location.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${location.name} deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: location.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(location.icon, color: location.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (location.address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      location.address!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.radar, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${location.radiusMeters}m radius',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.grey),
              onPressed: () => _showEditLocationDialog(context, location),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: 400.ms,
      delay: Duration(milliseconds: 200 + (index * 100)),
    ).slideX(begin: 0.2);
  }

  void _showBatteryWarningDialog(BuildContext context, LocationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.battery_alert, color: AppTheme.warningColor),
            const SizedBox(width: 12),
            const Text('Battery Usage'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Continuous GPS tracking will use more battery power.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.warningColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Battery usage depends on how often you move between locations.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.startContinuousTracking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enable Tracking'),
          ),
        ],
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddLocationSheet(),
    );
  }

  void _showEditLocationDialog(BuildContext context, SavedLocation location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddLocationSheet(editLocation: location),
    );
  }
}

class AddLocationSheet extends StatefulWidget {
  final SavedLocation? editLocation;

  const AddLocationSheet({super.key, this.editLocation});

  @override
  State<AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends State<AddLocationSheet> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  LocationPreset _selectedPreset = LocationPresets.presets.first;
  double? _latitude;
  double? _longitude;
  String? _address;
  int _radius = 100;
  bool _isLoadingLocation = false;
  Timer? _debounceTimer;

  bool get isEditing => widget.editLocation != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final loc = widget.editLocation!;
      _nameController.text = loc.name;
      _addressController.text = loc.address ?? '';
      _latitude = loc.latitude;
      _longitude = loc.longitude;
      _address = loc.address;
      _radius = loc.radiusMeters;
      // Find matching preset
      _selectedPreset = LocationPresets.presets.firstWhere(
        (p) => p.name == loc.name,
        orElse: () => LocationPresets.presets.last,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onAddressChanged(String value) {
    _debounceTimer?.cancel();
    if (value.length >= 3) {
      _debounceTimer = Timer(const Duration(milliseconds: 800), () {
        _searchAddress();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Location' : 'Add Location',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Preset Selection
              if (!isEditing) ...[
                Text(
                  'Quick Select',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LocationPresets.presets.map((preset) {
                    final isSelected = _selectedPreset.name == preset.name;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPreset = preset;
                          if (preset.name != 'Custom') {
                            _nameController.text = preset.name;
                          }
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? preset.color.withValues(alpha: 0.15)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? preset.color : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(preset.icon, size: 18, color: preset.color),
                            const SizedBox(width: 6),
                            Text(
                              preset.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : null,
                                color: isSelected ? preset.color : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Name Field
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Location Name',
                  hintText: 'e.g., Home, Office, Gym',
                  prefixIcon: Icon(_selectedPreset.icon, color: _selectedPreset.color),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Address / Get Current Location
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter address, postcode, or use GPS',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoadingLocation)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                        tooltip: 'Use current location',
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _onAddressChanged,
                onSubmitted: (_) => _searchAddress(),
              ),
              const SizedBox(height: 16),

              // Coordinates Display
              if (_latitude != null && _longitude != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Location set: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Radius Slider
              Text(
                'Trigger Radius: ${_radius}m',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Slider(
                value: _radius.toDouble(),
                min: 50,
                max: 500,
                divisions: 9,
                label: '${_radius}m',
                activeColor: _selectedPreset.color,
                onChanged: (value) {
                  setState(() => _radius = value.toInt());
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _latitude != null ? _saveLocation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedPreset.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Update Location' : 'Save Location',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Check if coordinates match Google HQ (emulator mock location)
  bool _isMockLocation(double lat, double lng) {
    const googleHqLat = 37.4220;
    const googleHqLng = -122.0841;
    const tolerance = 0.001; // ~100 meters tolerance
    return (lat - googleHqLat).abs() < tolerance &&
           (lng - googleHqLng).abs() < tolerance;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    final provider = context.read<LocationProvider>();
    final position = await provider.getCurrentPosition();

    if (position != null) {
      // Check for mock/emulator location
      if (_isMockLocation(position.latitude, position.longitude)) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mock location detected (emulator). Please enter address manually or use a real device.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      _latitude = position.latitude;
      _longitude = position.longitude;
      _address = await provider.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      _addressController.text = _address ?? 'Current Location';
    } else {
      // GPS failed - show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_off, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Could not get GPS location. Please enter address manually.'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _searchAddress() async {
    if (_addressController.text.isEmpty) return;

    setState(() => _isLoadingLocation = true);
    final provider = context.read<LocationProvider>();
    final locations = await provider.getCoordinatesFromAddress(_addressController.text);

    if (locations.isNotEmpty) {
      _latitude = locations.first.latitude;
      _longitude = locations.first.longitude;
      _address = _addressController.text;
    }

    if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _saveLocation() {
    if (_nameController.text.isEmpty || _latitude == null || _longitude == null) return;

    final provider = context.read<LocationProvider>();
    final location = SavedLocation(
      id: isEditing ? widget.editLocation!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      latitude: _latitude!,
      longitude: _longitude!,
      address: _address,
      icon: _selectedPreset.icon,
      color: _selectedPreset.color,
      radiusMeters: _radius,
      createdAt: isEditing ? widget.editLocation!.createdAt : DateTime.now(),
    );

    if (isEditing) {
      provider.updateLocation(location);
    } else {
      provider.addLocation(location);
    }

    Navigator.pop(context);
    HapticFeedback.mediumImpact();
  }
}
