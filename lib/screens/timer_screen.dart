import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/timer_provider.dart';
import '../providers/focus_sound_provider.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<TimerProvider>(
        builder: (context, timer, child) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                _buildHeader(context, timer),
                const Spacer(),
                // Timer display
                _buildTimerDisplay(context, timer),
                const SizedBox(height: 40),
                // Timer controls
                _buildTimerControls(context, timer),
                const Spacer(),
                // Presets
                _buildPresets(context, timer),
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TimerProvider timer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timer.phaseLabel,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Session ${timer.completedSessions + 1}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        Row(
          children: [
            // Sound button
            Consumer<FocusSoundProvider>(
              builder: (context, soundProvider, child) {
                return GestureDetector(
                  onTap: () => _showSoundPicker(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: soundProvider.isPlaying
                          ? AppTheme.primaryColor.withValues(alpha: 0.2)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      soundProvider.isPlaying
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: soundProvider.isPlaying
                          ? AppTheme.primaryColor
                          : Colors.grey.shade600,
                      size: 22,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${timer.todayCompletedSessions}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  void _showSoundPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const FocusSoundPicker(),
    );
  }

  Widget _buildTimerDisplay(BuildContext context, TimerProvider timer) {
    final phaseColor = timer.currentPhase == TimerPhase.work
        ? AppTheme.primaryColor
        : AppTheme.successColor;

    return Column(
      children: [
        // Circular timer
        Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: phaseColor.withValues(alpha: 0.1),
              ),
            ),
            // Progress indicator
            SizedBox(
              width: 280,
              height: 280,
              child: CircularProgressIndicator(
                value: timer.progress,
                strokeWidth: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
                strokeCap: StrokeCap.round,
              ),
            ),
            // Time display
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timer.timeLeftFormatted,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: phaseColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    timer.isRunning ? 'In Progress' : 'Paused',
                    style: TextStyle(
                      color: phaseColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        ).custom(
          duration: 2.seconds,
          builder: (context, value, child) {
            return Transform.scale(
              scale: timer.isRunning ? 1.0 + (value * 0.02) : 1.0,
              child: child,
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildTimerControls(BuildContext context, TimerProvider timer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset button
        _buildControlButton(
          context,
          icon: Icons.refresh,
          label: 'Reset',
          onTap: timer.resetTimer,
          color: AppTheme.textSecondaryLight,
        ),
        const SizedBox(width: 24),
        // Play/Pause button
        GestureDetector(
          onTap: timer.toggleTimer,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: timer.isRunning
                  ? LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    )
                  : AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: (timer.isRunning ? Colors.orange : AppTheme.primaryColor)
                      .withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              timer.isRunning ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
          ),
        ).animate().scale(delay: 400.ms),
        const SizedBox(width: 24),
        // Skip button
        _buildControlButton(
          context,
          icon: Icons.skip_next,
          label: 'Skip',
          onTap: timer.skipPhase,
          color: AppTheme.textSecondaryLight,
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresets(BuildContext context, TimerProvider timer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPresetButton(
            context,
            label: 'Pomodoro',
            minutes: 25,
            isSelected: timer.currentPhase == TimerPhase.work && !timer.isRunning,
            onTap: () => timer.setPreset(TimerPreset.pomodoro),
            color: AppTheme.primaryColor,
          ),
          _buildPresetButton(
            context,
            label: 'Short Break',
            minutes: 5,
            isSelected: timer.currentPhase == TimerPhase.shortBreak && !timer.isRunning,
            onTap: () => timer.setPreset(TimerPreset.shortBreak),
            color: AppTheme.successColor,
          ),
          _buildPresetButton(
            context,
            label: 'Long Break',
            minutes: 15,
            isSelected: timer.currentPhase == TimerPhase.longBreak && !timer.isRunning,
            onTap: () => timer.setPreset(TimerPreset.longBreak),
            color: AppTheme.accentColor,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 500.ms).slideY(begin: 0.3);
  }

  Widget _buildPresetButton(
    BuildContext context, {
    required String label,
    required int minutes,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$minutes min',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? color : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FocusSoundPicker extends StatelessWidget {
  const FocusSoundPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FocusSoundProvider>(
      builder: (context, soundProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Focus Sounds',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose ambient sounds for focus',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  // Volume slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.volume_down,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        Expanded(
                          child: Slider(
                            value: soundProvider.volume,
                            onChanged: (value) => soundProvider.setVolume(value),
                            activeColor: AppTheme.primaryColor,
                          ),
                        ),
                        Icon(
                          Icons.volume_up,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Sound list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Silent option
                        _buildSoundTile(context, FocusSound.silent, soundProvider),
                        const SizedBox(height: 16),
                        // Categories
                        for (final category in SoundCategory.values.where((c) => c != SoundCategory.none)) ...[
                          _buildCategoryHeader(context, category),
                          const SizedBox(height: 8),
                          ...soundProvider.getSoundsByCategory(category).map(
                            (sound) => _buildSoundTile(context, sound, soundProvider),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryHeader(BuildContext context, SoundCategory category) {
    IconData icon;
    switch (category) {
      case SoundCategory.brainwave:
        icon = Icons.psychology;
        break;
      case SoundCategory.noise:
        icon = Icons.graphic_eq;
        break;
      case SoundCategory.nature:
        icon = Icons.park;
        break;
      case SoundCategory.environmental:
        icon = Icons.location_city;
        break;
      default:
        icon = Icons.music_note;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 8),
        Text(
          category.displayName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSoundTile(BuildContext context, FocusSound sound, FocusSoundProvider provider) {
    final isSelected = provider.currentSound == sound;
    final isPlaying = isSelected && provider.isPlaying;

    return GestureDetector(
      onTap: () {
        if (sound == FocusSound.silent) {
          provider.stopSound();
          provider.playSound(sound);
        } else {
          provider.playSound(sound);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.2)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: sound.icon.isEmpty
                    ? Icon(
                        sound == FocusSound.silent ? Icons.volume_off : Icons.music_note,
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                      )
                    : Text(
                        sound.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sound.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isSelected ? AppTheme.primaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sound.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Playing indicator
            if (isPlaying)
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.equalizer,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              )
            else if (isSelected)
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
