import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/update_provider.dart';
import '../widgets/update_dialog.dart';
import '../providers/location_provider.dart';
import 'locations_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppearanceSection(context),
              const SizedBox(height: 24),
              _buildTimerSection(context),
              const SizedBox(height: 24),
              _buildLocationSection(context),
              const SizedBox(height: 24),
              _buildUpdateSection(context),
              const SizedBox(height: 24),
              _buildAboutSection(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Appearance',
      icon: Icons.palette_outlined,
      children: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return _buildSettingTile(
              context,
              icon: themeProvider.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              title: 'Dark Mode',
              subtitle: themeProvider.themeMode == ThemeMode.system
                  ? 'System default'
                  : themeProvider.themeMode == ThemeMode.dark
                      ? 'On'
                      : 'Off',
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
                activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                activeThumbColor: AppTheme.primaryColor,
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildTimerSection(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timer, child) {
        return _buildSection(
          context,
          title: 'Timer',
          icon: Icons.timer_outlined,
          children: [
            _buildSettingTile(
              context,
              icon: Icons.work_outline,
              title: 'Focus Duration',
              subtitle: '${timer.workDuration ~/ 60} minutes',
              onTap: () => _showDurationPicker(
                context,
                title: 'Focus Duration',
                currentValue: timer.workDuration ~/ 60,
                onChanged: (value) {
                  timer.updateDurations(workMinutes: value);
                },
              ),
            ),
            _buildSettingTile(
              context,
              icon: Icons.coffee_outlined,
              title: 'Short Break',
              subtitle: '${timer.shortBreakDuration ~/ 60} minutes',
              onTap: () => _showDurationPicker(
                context,
                title: 'Short Break Duration',
                currentValue: timer.shortBreakDuration ~/ 60,
                onChanged: (value) {
                  timer.updateDurations(shortBreakMinutes: value);
                },
              ),
            ),
            _buildSettingTile(
              context,
              icon: Icons.weekend_outlined,
              title: 'Long Break',
              subtitle: '${timer.longBreakDuration ~/ 60} minutes',
              onTap: () => _showDurationPicker(
                context,
                title: 'Long Break Duration',
                currentValue: timer.longBreakDuration ~/ 60,
                onChanged: (value) {
                  timer.updateDurations(longBreakMinutes: value);
                },
              ),
            ),
          ],
        );
      },
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildLocationSection(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final locationCount = locationProvider.savedLocations.length;
        final isTracking = locationProvider.continuousTracking;

        return _buildSection(
          context,
          title: 'Location Reminders',
          icon: Icons.location_on_outlined,
          children: [
            _buildSettingTile(
              context,
              icon: isTracking ? Icons.location_on : Icons.location_off,
              title: 'Location Tracking',
              subtitle: isTracking
                  ? 'Active - GPS enabled'
                  : 'Off - Enable for location reminders',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isTracking
                      ? AppTheme.successColor.withValues(alpha: 0.15)
                      : AppTheme.errorColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isTracking ? 'ON' : 'OFF',
                  style: TextStyle(
                    color: isTracking ? AppTheme.successColor : AppTheme.errorColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildSettingTile(
              context,
              icon: Icons.place_outlined,
              title: 'Saved Locations',
              subtitle: locationCount == 0
                  ? 'Add locations like Home, Work, Gym'
                  : '$locationCount location${locationCount == 1 ? '' : 's'} saved',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationsScreen()),
                );
              },
            ),
          ],
        );
      },
    ).animate().fadeIn(duration: 500.ms, delay: 220.ms).slideY(begin: 0.1);
  }

  Widget _buildUpdateSection(BuildContext context) {
    return Consumer<UpdateProvider>(
      builder: (context, updateProvider, child) {
        return _buildSection(
          context,
          title: 'Updates',
          icon: Icons.system_update_outlined,
          children: [
            _buildSettingTile(
              context,
              icon: Icons.info_outline,
              title: 'Current Version',
              subtitle: updateProvider.currentVersion,
            ),
            _buildSettingTile(
              context,
              icon: updateProvider.hasUpdate
                  ? Icons.download_rounded
                  : Icons.check_circle_outline,
              title: updateProvider.hasUpdate ? 'Update Available' : 'Check for Updates',
              subtitle: updateProvider.isChecking
                  ? 'Checking...'
                  : updateProvider.hasUpdate
                      ? 'Version ${(updateProvider.updateResult as UpdateAvailable).version} available'
                      : 'You\'re on the latest version',
              trailing: updateProvider.isChecking
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : updateProvider.hasUpdate
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
              onTap: updateProvider.isChecking
                  ? null
                  : () async {
                      if (updateProvider.hasUpdate) {
                        showUpdateDialog(
                          context,
                          updateProvider.updateResult as UpdateAvailable,
                        );
                      } else {
                        final result = await updateProvider.checkForUpdate(force: true);
                        if (context.mounted && result is UpdateAvailable) {
                          showUpdateDialog(context, result);
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('You\'re on the latest version!'),
                                ],
                              ),
                              backgroundColor: AppTheme.successColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      }
                    },
            ),
          ],
        );
      },
    ).animate().fadeIn(duration: 500.ms, delay: 250.ms).slideY(begin: 0.1);
  }

  Widget _buildAboutSection(BuildContext context) {
    final currentYear = DateTime.now().year;

    return _buildSection(
      context,
      title: 'About',
      icon: Icons.info_outlined,
      children: [
        _buildSettingTile(
          context,
          icon: Icons.rocket_launch_outlined,
          title: 'TaskOrbit',
          subtitle: 'Version 1.3.0',
        ),
        _buildSettingTile(
          context,
          icon: Icons.language_outlined,
          title: 'Author',
          subtitle: 'zimbabeats.com',
        ),
        _buildSettingTile(
          context,
          icon: Icons.code_outlined,
          title: 'Developer',
          subtitle: 'R M',
        ),
        _buildSettingTile(
          context,
          icon: Icons.copyright_outlined,
          title: 'Copyright',
          subtitle: '\u00A9 $currentYear ZimbaBeats. All rights reserved.',
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (trailing == null && onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDurationPicker(
    BuildContext context, {
    required String title,
    required int currentValue,
    required Function(int) onChanged,
  }) {
    int selectedValue = currentValue;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (selectedValue > 1) {
                              setState(() => selectedValue--);
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 36,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '$selectedValue min',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          onPressed: () {
                            if (selectedValue < 60) {
                              setState(() => selectedValue++);
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 36,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          onChanged(selectedValue);
                          Navigator.pop(context);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
