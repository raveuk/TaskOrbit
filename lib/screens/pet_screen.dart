import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/pet.dart';
import '../providers/pet_provider.dart';

class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onInteraction() {
    _bounceController.forward().then((_) => _bounceController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<PetProvider>(
          builder: (context, provider, child) {
            final pet = provider.pet;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeader(context, pet),
                  const SizedBox(height: 24),
                  _buildPetAvatar(context, pet),
                  const SizedBox(height: 16),
                  _buildMoodBadge(context, pet),
                  const SizedBox(height: 24),
                  _buildStatsCard(context, pet),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, provider),
                  const SizedBox(height: 16),
                  _buildRewardsInfo(context, pet),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Pet pet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _showRenameDialog(context),
              child: Row(
                children: [
                  Text(
                    pet.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Level ${pet.level} Companion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        _buildCoinsDisplay(context, pet),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildCoinsDisplay(BuildContext context, Pet pet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(
            '${pet.coins}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetAvatar(BuildContext context, Pet pet) {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + (_bounceController.value * 0.1),
          child: child,
        );
      },
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.2),
              AppTheme.accentColor.withValues(alpha: 0.2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _getPetEmoji(pet.currentMood),
            style: const TextStyle(fontSize: 80),
          ),
        ),
      ).animate().scale(
        begin: const Offset(0.8, 0.8),
        end: const Offset(1, 1),
        duration: 600.ms,
        curve: Curves.elasticOut,
      ),
    );
  }

  String _getPetEmoji(PetMood mood) {
    switch (mood) {
      case PetMood.happy:
        return '😊';
      case PetMood.excited:
        return '🤩';
      case PetMood.neutral:
        return '😐';
      case PetMood.tired:
        return '😴';
      case PetMood.sad:
        return '😢';
      case PetMood.sleeping:
        return '💤';
    }
  }

  Widget _buildMoodBadge(BuildContext context, Pet pet) {
    final moodData = _getMoodData(pet.currentMood);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: moodData.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: moodData.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(moodData.icon, color: moodData.color, size: 20),
          const SizedBox(width: 8),
          Text(
            moodData.label,
            style: TextStyle(
              color: moodData.color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  ({Color color, IconData icon, String label}) _getMoodData(PetMood mood) {
    switch (mood) {
      case PetMood.happy:
        return (color: Colors.green, icon: Icons.sentiment_satisfied, label: 'Happy');
      case PetMood.excited:
        return (color: Colors.amber, icon: Icons.celebration, label: 'Excited');
      case PetMood.neutral:
        return (color: Colors.grey, icon: Icons.sentiment_neutral, label: 'Neutral');
      case PetMood.tired:
        return (color: Colors.orange, icon: Icons.bedtime, label: 'Tired');
      case PetMood.sad:
        return (color: Colors.blue, icon: Icons.sentiment_dissatisfied, label: 'Sad');
      case PetMood.sleeping:
        return (color: Colors.indigo, icon: Icons.nights_stay, label: 'Sleeping');
    }
  }

  Widget _buildStatsCard(BuildContext context, Pet pet) {
    final xpProgress = pet.xpProgress;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // XP Progress
          Row(
            children: [
              CircularPercentIndicator(
                radius: 35,
                lineWidth: 6,
                percent: xpProgress.clamp(0.0, 1.0),
                center: Text(
                  'Lv ${pet.level}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                progressColor: AppTheme.primaryColor,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Experience',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: xpProgress.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet.xpInCurrentLevel} / ${Pet.xpPerLevel} XP',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.favorite,
                  color: Colors.red,
                  label: 'Happiness',
                  value: pet.happiness,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.bolt,
                  color: Colors.amber,
                  label: 'Energy',
                  value: pet.energy,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required int value,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          '$value%',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, PetProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.restaurant,
            label: 'Feed',
            color: Colors.green,
            onTap: () {
              provider.feedPet();
              _onInteraction();
              _showFeedbackSnackBar(context, 'You fed ${provider.pet.name}! 🍎');
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.sports_esports,
            label: 'Play',
            color: Colors.purple,
            enabled: provider.pet.energy >= 20,
            onTap: () {
              provider.playWithPet();
              if (provider.lastInteraction == PetInteraction.tooTired) {
                _showFeedbackSnackBar(
                  context,
                  '${provider.pet.name} is too tired to play! 😴',
                  isError: true,
                );
              } else {
                _onInteraction();
                _showFeedbackSnackBar(context, 'You played with ${provider.pet.name}! 🎮');
              }
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Material(
      color: enabled ? color : Colors.grey.shade300,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardsInfo(BuildContext context, Pet pet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Earn Rewards',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRewardItem('Complete a task', '+${Pet.xpTaskComplete} XP'),
          _buildRewardItem('Complete a habit', '+${Pet.xpHabitComplete} XP'),
          _buildRewardItem('Finish Pomodoro', '+${Pet.xpPomodoroComplete} XP'),
          _buildRewardItem('Level up', '+coins (level × 10)'),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildRewardItem(String action, String reward) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            action,
            style: const TextStyle(fontSize: 13),
          ),
          const Spacer(),
          Text(
            reward,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: context.read<PetProvider>().pet.name,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Pet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<PetProvider>().renamePet(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
