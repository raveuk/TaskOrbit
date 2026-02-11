import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/planned_task.dart';
import '../models/task.dart';
import '../providers/planner_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/planner_timeline.dart';
import '../widgets/time_block_card.dart';

class DailyPlannerView extends StatefulWidget {
  const DailyPlannerView({super.key});

  @override
  State<DailyPlannerView> createState() => _DailyPlannerViewState();
}

class _DailyPlannerViewState extends State<DailyPlannerView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to current time on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final hourOffset = (now.hour - 6) * 60.0; // Start at 6 AM
    if (hourOffset > 0 && _scrollController.hasClients) {
      _scrollController.animateTo(
        hourOffset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlannerProvider, TaskProvider>(
      builder: (context, plannerProvider, taskProvider, child) {
        final selectedDate = plannerProvider.selectedDate;
        final dayTasks = plannerProvider.selectedDatePlanned;
        final unscheduledTasks = taskProvider.pendingTasks
            .where((t) => !dayTasks.any((pt) => pt.taskId == t.id))
            .toList();

        return Column(
          children: [
            // Date header
            _buildDateHeader(context, plannerProvider, selectedDate),

            // Capacity indicator
            if (dayTasks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DayCapacityIndicator(
                  scheduledMinutes: plannerProvider.getTotalScheduledMinutes(selectedDate),
                ).animate().fadeIn(duration: 300.ms),
              ),

            const SizedBox(height: 12),

            // Timeline
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    PlannerTimeline(
                      tasks: dayTasks,
                      startHour: 6,
                      endHour: 23,
                      hourHeight: 60,
                      onTaskTap: (task) => _showTaskDetails(context, task),
                      onTaskLongPress: (task) => _showTaskOptions(context, task, plannerProvider),
                      onTaskComplete: (task) => _toggleCompletion(plannerProvider, taskProvider, task),
                      onEmptySlotTap: (hour) => _showAddTaskDialog(context, hour),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Unscheduled tasks section
            if (unscheduledTasks.isNotEmpty)
              _buildUnscheduledSection(context, unscheduledTasks, plannerProvider),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(
    BuildContext context,
    PlannerProvider provider,
    DateTime selectedDate,
  ) {
    final isToday = _isToday(selectedDate);
    final dateFormat = DateFormat('EEEE, MMM d');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous day button
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              provider.previousDay();
            },
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),

          // Date display
          GestureDetector(
            onTap: () => _selectDate(context, provider),
            child: Column(
              children: [
                Text(
                  isToday ? 'Today' : dateFormat.format(selectedDate),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (!isToday)
                  TextButton(
                    onPressed: provider.goToToday,
                    child: const Text('Go to Today'),
                  ),
              ],
            ),
          ),

          // Next day button
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              provider.nextDay();
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

  Widget _buildUnscheduledSection(
    BuildContext context,
    List<Task> tasks,
    PlannerProvider plannerProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Unscheduled Tasks (${tasks.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: () => _showScheduleAllDialog(context, tasks, plannerProvider),
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Auto Schedule'),
                ),
              ],
            ),
          ),

          // Task list
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildUnscheduledTaskCard(context, task, plannerProvider);
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    ).animate().slideY(begin: 0.5, duration: 400.ms).fadeIn();
  }

  Widget _buildUnscheduledTaskCard(
    BuildContext context,
    Task task,
    PlannerProvider plannerProvider,
  ) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _priorityToColor(task.priority),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            task.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _unscheduledCardContent(context, task),
      ),
      child: GestureDetector(
        onTap: () => _showQuickScheduleDialog(context, task, plannerProvider),
        child: _unscheduledCardContent(context, task),
      ),
    );
  }

  Widget _unscheduledCardContent(BuildContext context, Task task) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _priorityToColor(task.priority).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _priorityToColor(task.priority),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                task.priority.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _priorityToColor(task.priority),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                task.estimatedMinutes != null
                    ? '${task.estimatedMinutes}min'
                    : '30min',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _priorityToColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return AppTheme.errorColor;
      case Priority.medium:
        return AppTheme.warningColor;
      case Priority.low:
        return AppTheme.successColor;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _selectDate(BuildContext context, PlannerProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      provider.setSelectedDate(picked);
    }
  }

  void _showTaskDetails(BuildContext context, PlannedTask task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskDetailsSheet(task: task),
    );
  }

  void _showTaskOptions(
    BuildContext context,
    PlannedTask task,
    PlannerProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                task.isCompleted ? Icons.replay : Icons.check_circle,
                color: AppTheme.successColor,
              ),
              title: Text(task.isCompleted ? 'Mark as pending' : 'Mark as complete'),
              onTap: () {
                provider.toggleCompletion(task.id);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
              title: const Text('Edit time'),
              onTap: () {
                Navigator.pop(context);
                _showRescheduleDialog(context, task, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Remove from schedule'),
              onTap: () {
                provider.deletePlannedTask(task.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleCompletion(
    PlannerProvider plannerProvider,
    TaskProvider taskProvider,
    PlannedTask task,
  ) {
    HapticFeedback.mediumImpact();
    plannerProvider.toggleCompletion(task.id);

    // Also toggle the linked task if exists
    if (task.taskId != null) {
      taskProvider.toggleTaskCompletion(task.taskId!);
    }
  }

  void _showAddTaskDialog(BuildContext context, int hour) {
    // TODO: Implement add task at specific time dialog
  }

  void _showQuickScheduleDialog(
    BuildContext context,
    Task task,
    PlannerProvider plannerProvider,
  ) {
    final now = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay(hour: now.hour + 1, minute: 0);
    int duration = task.estimatedMinutes ?? 30;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule "${task.title}"',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),

              // Time picker
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Start time'),
                trailing: Text(selectedTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setState(() => selectedTime = picked);
                  }
                },
              ),

              // Duration
              ListTile(
                leading: const Icon(Icons.timelapse),
                title: const Text('Duration'),
                trailing: DropdownButton<int>(
                  value: duration,
                  underline: const SizedBox(),
                  items: [15, 30, 45, 60, 90, 120]
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text('$m min'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => duration = val ?? 30),
                ),
              ),

              const SizedBox(height: 24),

              // Schedule button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final start = DateTime(
                      plannerProvider.selectedDate.year,
                      plannerProvider.selectedDate.month,
                      plannerProvider.selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    final end = start.add(Duration(minutes: duration));

                    plannerProvider.scheduleTask(
                      task: task,
                      start: start,
                      end: end,
                    );

                    Navigator.pop(context);
                    HapticFeedback.mediumImpact();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Scheduled "${task.title}"'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Schedule'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRescheduleDialog(
    BuildContext context,
    PlannedTask task,
    PlannerProvider provider,
  ) {
    // Similar to quick schedule but for existing task
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(task.scheduledStart);
    int duration = task.durationMinutes;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reschedule "${task.title}"',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),

              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Start time'),
                trailing: Text(selectedTime.format(context)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setState(() => selectedTime = picked);
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.timelapse),
                title: const Text('Duration'),
                trailing: DropdownButton<int>(
                  value: duration,
                  underline: const SizedBox(),
                  items: [15, 30, 45, 60, 90, 120]
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text('$m min'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => duration = val ?? 30),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final start = DateTime(
                      provider.selectedDate.year,
                      provider.selectedDate.month,
                      provider.selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    final end = start.add(Duration(minutes: duration));

                    provider.rescheduleTask(
                      id: task.id,
                      newStart: start,
                      newEnd: end,
                    );

                    Navigator.pop(context);
                    HapticFeedback.mediumImpact();
                  },
                  child: const Text('Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScheduleAllDialog(
    BuildContext context,
    List<Task> tasks,
    PlannerProvider provider,
  ) {
    // Use AI scheduling
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto Schedule'),
        content: Text(
          'Would you like to automatically schedule ${tasks.length} tasks for today?\n\n'
          'High priority tasks will be scheduled in the morning.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final suggestions = await provider.generateAISchedule(tasks);
              await provider.applyAISchedule(suggestions);

              if (context.mounted) {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Scheduled ${suggestions.length} tasks'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }
}

class _TaskDetailsSheet extends StatelessWidget {
  final PlannedTask task;

  const _TaskDetailsSheet({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: task.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        decoration:
                            task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                ),
              ),
              if (task.isCompleted)
                const Icon(Icons.check_circle, color: AppTheme.successColor),
            ],
          ),
          const SizedBox(height: 16),

          // Time
          Row(
            children: [
              const Icon(Icons.access_time, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                task.timeRangeString,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: task.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${task.durationMinutes} min',
                  style: TextStyle(
                    color: task.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          if (task.notes != null && task.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              task.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
