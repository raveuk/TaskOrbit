import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/planned_task.dart';
import '../providers/planner_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/time_block_card.dart';

class WeeklyPlannerView extends StatefulWidget {
  final Function(DateTime)? onDayTap;

  const WeeklyPlannerView({super.key, this.onDayTap});

  @override
  State<WeeklyPlannerView> createState() => _WeeklyPlannerViewState();
}

class _WeeklyPlannerViewState extends State<WeeklyPlannerView> {
  late DateTime _weekStart;
  final PageController _pageController = PageController(initialPage: 100);

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday % 7)); // Sunday start
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlannerProvider>(
      builder: (context, plannerProvider, child) {
        return Column(
          children: [
            // Week navigation header
            _buildWeekHeader(context),

            const SizedBox(height: 8),

            // Day labels
            _buildDayLabels(context),

            const SizedBox(height: 8),

            // Week grid
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  final weekOffset = page - 100;
                  setState(() {
                    _weekStart = _getWeekStart(DateTime.now())
                        .add(Duration(days: weekOffset * 7));
                  });
                },
                itemBuilder: (context, index) {
                  final weekOffset = index - 100;
                  final weekStart = _getWeekStart(DateTime.now())
                      .add(Duration(days: weekOffset * 7));
                  return _buildWeekGrid(context, plannerProvider, weekStart);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeekHeader(BuildContext context) {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final monthFormat = DateFormat('MMM d');
    final isCurrentWeek = _isCurrentWeek();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            },
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          Column(
            children: [
              Text(
                '${monthFormat.format(_weekStart)} - ${monthFormat.format(weekEnd)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!isCurrentWeek)
                TextButton(
                  onPressed: () {
                    _pageController.animateToPage(
                      100,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: const Text('Go to this week'),
                ),
            ],
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            },
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildDayLabels(BuildContext context) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(7, (index) {
          final date = _weekStart.add(Duration(days: index));
          final isToday = _isSameDay(date, today);

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isToday ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? AppTheme.primaryColor : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isToday ? AppTheme.primaryColor : null,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isToday ? Colors.white : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWeekGrid(
    BuildContext context,
    PlannerProvider provider,
    DateTime weekStart,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final dayTasks = provider.getTasksForDate(date);
          final isToday = _isSameDay(date, DateTime.now());
          final isSelected = _isSameDay(date, provider.selectedDate);

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                provider.setSelectedDate(date);
                widget.onDayTap?.call(date);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : isToday
                            ? AppTheme.primaryColor.withValues(alpha: 0.3)
                            : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Tasks
                    Expanded(
                      child: dayTasks.isEmpty
                          ? Center(
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: dayTasks
                                    .take(4)
                                    .map((task) => MiniTimeBlockCard(
                                          task: task,
                                          onTap: () {
                                            provider.setSelectedDate(date);
                                            widget.onDayTap?.call(date);
                                          },
                                        ))
                                    .toList(),
                              ),
                            ),
                    ),

                    // Day summary
                    const SizedBox(height: 4),
                    _buildDaySummary(context, provider, date, dayTasks),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDaySummary(
    BuildContext context,
    PlannerProvider provider,
    DateTime date,
    List<PlannedTask> tasks,
  ) {
    final totalMinutes = provider.getTotalScheduledMinutes(date);
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final totalCount = tasks.length;

    if (tasks.isEmpty) {
      return const SizedBox(height: 24);
    }

    final hours = totalMinutes / 60;
    Color capacityColor;
    if (hours > 6) {
      capacityColor = AppTheme.errorColor;
    } else if (hours > 4) {
      capacityColor = AppTheme.warningColor;
    } else {
      capacityColor = AppTheme.successColor;
    }

    return Column(
      children: [
        // Hours indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 10, color: capacityColor),
            const SizedBox(width: 2),
            Text(
              '${hours.toStringAsFixed(1)}h',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: capacityColor,
              ),
            ),
          ],
        ),

        // Completion indicator
        if (totalCount > 0) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$completedCount/$totalCount',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool _isCurrentWeek() {
    final now = DateTime.now();
    final currentWeekStart = _getWeekStart(now);
    return _isSameDay(_weekStart, currentWeekStart);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// Week statistics card
class WeekStatsCard extends StatelessWidget {
  final DateTime weekStart;

  const WeekStatsCard({super.key, required this.weekStart});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlannerProvider>(
      builder: (context, provider, child) {
        final weekTasks = provider.getTasksForWeek(weekStart);
        final totalTasks = weekTasks.length;
        final completedTasks = weekTasks.where((t) => t.isCompleted).length;
        final totalMinutes = weekTasks.fold(0, (sum, t) => sum + t.durationMinutes);
        final completedMinutes = weekTasks
            .where((t) => t.isCompleted)
            .fold(0, (sum, t) => sum + t.durationMinutes);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Tasks',
                '$completedTasks/$totalTasks',
                Icons.check_circle_outline,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                'Focus Time',
                '${(completedMinutes / 60).toStringAsFixed(1)}h',
                Icons.timer_outlined,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                'Completion',
                totalTasks > 0
                    ? '${(completedTasks / totalTasks * 100).round()}%'
                    : '0%',
                Icons.trending_up,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
