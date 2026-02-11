import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../theme/app_theme.dart';
import '../providers/timer_provider.dart';
import '../providers/task_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/planner_provider.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/task_preview_card.dart';
import '../widgets/habit_preview_card.dart';
import '../widgets/ai_tips_card.dart';
import '../widgets/time_block_card.dart';
import '../models/task.dart';
import 'breathing_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildTodayOverview(context),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildTodayPlanSection(context),
                  const SizedBox(height: 24),
                  const AITipsCard(),
                  const SizedBox(height: 24),
                  _buildTasksSection(context),
                  const SizedBox(height: 24),
                  _buildHabitsSection(context),
                  const SizedBox(height: 100), // Bottom padding for nav bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;

    if (hour < 12) {
      greeting = 'Good Morning';
      icon = Icons.wb_sunny_outlined;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      icon = Icons.wb_sunny;
    } else {
      greeting = 'Good Evening';
      icon = Icons.nights_stay_outlined;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.warningColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
            const SizedBox(height: 4),
            Text(
              'Ready to focus?',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideX(begin: -0.2),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms).scale(),
      ],
    );
  }

  Widget _buildTodayOverview(BuildContext context) {
    return Consumer3<TimerProvider, TaskProvider, HabitProvider>(
      builder: (context, timer, tasks, habits, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Progress",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${timer.todayCompletedSessions} Sessions',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${timer.todayCompletedSessions * 25} minutes focused',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  CircularPercentIndicator(
                    radius: 45,
                    lineWidth: 8,
                    percent: (timer.todayCompletedSessions / 8).clamp(0.0, 1.0),
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${((timer.todayCompletedSessions / 8) * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Goal',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    progressColor: Colors.white,
                    backgroundColor: Colors.white24,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat(
                      Icons.check_circle_outline,
                      '${tasks.completedTodayCount}',
                      'Tasks Done',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white24,
                  ),
                  Expanded(
                    child: _buildMiniStat(
                      Icons.loop,
                      '${habits.completedTodayCount}/${habits.todayHabits.length}',
                      'Habits',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white24,
                  ),
                  Expanded(
                    child: _buildMiniStat(
                      Icons.local_fire_department,
                      '${timer.completedSessions}',
                      'Streak',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.2);
      },
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                icon: Icons.play_arrow_rounded,
                label: 'Start Focus',
                color: AppTheme.primaryColor,
                onTap: () {
                  // Navigate to timer tab (index 1)
                  onNavigateToTab?.call(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                icon: Icons.add_task,
                label: 'Add Task',
                color: AppTheme.successColor,
                onTap: () {
                  // Navigate to tasks tab (index 2)
                  onNavigateToTab?.call(2);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                icon: Icons.self_improvement,
                label: 'Breathe',
                color: AppTheme.accentColor,
                onTap: () {
                  // Navigate to breathing screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BreathingScreen()),
                  );
                },
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms, delay: 500.ms).slideY(begin: 0.2),
      ],
    );
  }

  Widget _buildTodayPlanSection(BuildContext context) {
    return Consumer<PlannerProvider>(
      builder: (context, plannerProvider, child) {
        final todayPlanned = plannerProvider.todayPlanned.take(3).toList();
        final currentTask = plannerProvider.currentlyActiveTask;
        final nextTask = plannerProvider.nextUpcomingTask;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Plan",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to planner tab (index 3)
                    onNavigateToTab?.call(3);
                  },
                  child: const Text('See All'),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms, delay: 550.ms),
            const SizedBox(height: 12),
            if (todayPlanned.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
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
                      Icons.calendar_today,
                      size: 48,
                      color: AppTheme.accentColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No plan for today',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Schedule tasks to see them here',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => onNavigateToTab?.call(3),
                      icon: const Icon(Icons.add),
                      label: const Text('Plan My Day'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 600.ms)
            else
              Column(
                children: [
                  // Current/Next task highlight
                  if (currentTask != null || nextTask != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: currentTask != null
                            ? AppTheme.primaryGradient
                            : null,
                        color: currentTask == null
                            ? AppTheme.accentColor.withValues(alpha: 0.1)
                            : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: currentTask != null
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : AppTheme.accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              currentTask != null
                                  ? Icons.play_circle_filled
                                  : Icons.schedule,
                              color: currentTask != null
                                  ? Colors.white
                                  : AppTheme.accentColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentTask != null ? 'NOW' : 'UP NEXT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: currentTask != null
                                        ? Colors.white70
                                        : AppTheme.accentColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (currentTask ?? nextTask)!.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: currentTask != null
                                        ? Colors.white
                                        : null,
                                  ),
                                ),
                                Text(
                                  (currentTask ?? nextTask)!.timeRangeString,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: currentTask != null
                                        ? Colors.white70
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (currentTask != null)
                            IconButton(
                              onPressed: () => onNavigateToTab?.call(1),
                              icon: const Icon(
                                Icons.timer,
                                color: Colors.white,
                              ),
                              tooltip: 'Start Timer',
                            ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 600.ms).slideX(begin: 0.1),

                  // Task list
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todayPlanned.take(3).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final task = todayPlanned[index];
                      return TimeBlockCard(
                        task: task,
                        height: 60,
                        onTap: () => onNavigateToTab?.call(3),
                        onComplete: () =>
                            plannerProvider.toggleCompletion(task.id),
                      ).animate().fadeIn(
                            duration: 400.ms,
                            delay: Duration(milliseconds: 650 + (index * 100)),
                          ).slideX(begin: 0.1);
                    },
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildTasksSection(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final pendingTasks = taskProvider.pendingTasks.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Tasks',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to tasks tab (index 2)
                    onNavigateToTab?.call(2);
                  },
                  child: const Text('See All'),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
            const SizedBox(height: 12),
            if (pendingTasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
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
                      Icons.check_circle,
                      size: 48,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'All caught up!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No pending tasks. Add a new one?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 700.ms)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingTasks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return TaskPreviewCard(
                    task: pendingTasks[index],
                    onTap: () {
                      // Navigate to task detail
                    },
                    onComplete: () {
                      taskProvider.toggleTaskCompletion(pendingTasks[index].id);
                    },
                  ).animate().fadeIn(
                        duration: 400.ms,
                        delay: Duration(milliseconds: 700 + (index * 100)),
                      ).slideX(begin: 0.2);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildHabitsSection(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final todayHabits = habitProvider.todayHabits.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Habits",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to habits tab (index 4)
                    onNavigateToTab?.call(4);
                  },
                  child: const Text('See All'),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms, delay: 800.ms),
            const SizedBox(height: 12),
            if (todayHabits.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
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
                      Icons.loop,
                      size: 48,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No habits for today',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a habit to get started',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 900.ms)
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: todayHabits.length,
                itemBuilder: (context, index) {
                  return HabitPreviewCard(
                    habit: todayHabits[index],
                    onTap: () {
                      habitProvider.toggleHabitCompletion(todayHabits[index].id);
                    },
                  ).animate().fadeIn(
                        duration: 400.ms,
                        delay: Duration(milliseconds: 900 + (index * 100)),
                      ).scale(begin: const Offset(0.9, 0.9));
                },
              ),
          ],
        );
      },
    );
  }
}
