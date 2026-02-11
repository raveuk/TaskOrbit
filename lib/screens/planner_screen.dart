import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/planned_task.dart';
import '../providers/planner_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_schedule_dialog.dart';
import 'daily_planner_view.dart';
import 'weekly_planner_view.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Planner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // AI Schedule button
          IconButton(
            onPressed: () => _showAIScheduleDialog(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_fix_high,
                color: Colors.white,
                size: 20,
              ),
            ),
            tooltip: 'AI Schedule',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(
              icon: Icon(Icons.view_day),
              text: 'Daily',
            ),
            Tab(
              icon: Icon(Icons.view_week),
              text: 'Weekly',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const DailyPlannerView(),
          WeeklyPlannerView(
            onDayTap: (date) {
              // Switch to daily view when tapping a day
              _tabController.animateTo(0);
            },
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddBlockDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('Add Block'),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
    ).animate().scale(
          delay: 300.ms,
          duration: 300.ms,
          curve: Curves.elasticOut,
        );
  }

  void _showAIScheduleDialog(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    final plannerProvider = context.read<PlannerProvider>();
    final unscheduledTasks = taskProvider.pendingTasks;

    if (unscheduledTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending tasks to schedule'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AIScheduleDialog(
        tasks: unscheduledTasks,
        onApply: (suggestions) async {
          await plannerProvider.applyAISchedule(suggestions);
          HapticFeedback.mediumImpact();
        },
      ),
    );
  }

  void _showAddBlockDialog(BuildContext context) {
    final plannerProvider = context.read<PlannerProvider>();
    final selectedDate = plannerProvider.selectedDate;

    String title = '';
    TimeOfDay startTime = TimeOfDay.now();
    int duration = 30;
    Color selectedColor = AppTheme.primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      'Add Time Block',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Title
                TextField(
                  onChanged: (val) => title = val,
                  decoration: InputDecoration(
                    labelText: 'What are you planning?',
                    hintText: 'e.g., Deep work, Meeting, Exercise',
                    prefixIcon: const Icon(Icons.edit),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // Time picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.access_time, color: AppTheme.primaryColor),
                  ),
                  title: const Text('Start time'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        setState(() => startTime = picked);
                      }
                    },
                    child: Text(
                      startTime.format(context),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                // Duration picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.timelapse, color: AppTheme.accentColor),
                  ),
                  title: const Text('Duration'),
                  trailing: DropdownButton<int>(
                    value: duration,
                    underline: const SizedBox(),
                    items: [15, 30, 45, 60, 90, 120, 180]
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m < 60 ? '$m min' : '${m ~/ 60}h ${m % 60 > 0 ? "${m % 60}m" : ""}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => duration = val ?? 30),
                  ),
                ),

                // Color picker
                const SizedBox(height: 16),
                Text(
                  'Color',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    AppTheme.primaryColor,
                    AppTheme.accentColor,
                    AppTheme.successColor,
                    AppTheme.warningColor,
                    AppTheme.errorColor,
                    const Color(0xFF8B5CF6),
                    const Color(0xFFEC4899),
                    const Color(0xFF78350F),
                  ].map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Add button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: title.isEmpty
                        ? null
                        : () {
                            final start = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              startTime.hour,
                              startTime.minute,
                            );
                            final end = start.add(Duration(minutes: duration));

                            plannerProvider.addPlannedTask(
                              PlannedTask(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: title,
                                scheduledStart: start,
                                scheduledEnd: end,
                                color: selectedColor,
                              ),
                            );

                            Navigator.pop(context);
                            HapticFeedback.mediumImpact();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added "$title" to your plan'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                    child: const Text('Add to Plan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
