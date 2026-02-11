import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import 'package:confetti/confetti.dart';

import '../theme/app_theme.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/celebration_provider.dart';
import '../providers/planner_provider.dart';
import '../widgets/ai_task_breakdown_dialog.dart';
import '../widgets/voice_task_dialog.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onTaskCompleted() {
    _confettiController.play();
    context.read<PetProvider>().onTaskCompleted();
    context.read<CelebrationProvider>().celebrateTaskComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildTabBar(context),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(context, showCompleted: false),
                    _buildTaskList(context, showCompleted: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFF6366F1), // Indigo
              Color(0xFF8B5CF6), // Violet
              Color(0xFFEC4899), // Pink
              Color(0xFFF59E0B), // Amber
              Color(0xFF10B981), // Emerald
              Color(0xFF3B82F6), // Blue
            ],
            numberOfParticles: 30,
            gravity: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasks',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Consumer<TaskProvider>(
              builder: (context, provider, child) {
                return Text(
                  '${provider.pendingTaskCount} pending',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              },
            ),
          ],
        ),
        Row(
          children: [
            // Voice input button
            FloatingActionButton.small(
              heroTag: 'voiceTask',
              onPressed: () => showVoiceTaskDialog(context, (task) {
                context.read<TaskProvider>().addTask(task);
              }),
              backgroundColor: AppTheme.accentColor,
              child: const Icon(Icons.mic, color: Colors.white),
            ),
            const SizedBox(width: 12),
            // Add task button
            FloatingActionButton(
              heroTag: 'addTask',
              onPressed: () => _showAddTaskDialog(context),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Completed'),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
  }

  Widget _buildTaskList(BuildContext context, {required bool showCompleted}) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final tasks =
            showCompleted ? provider.completedTasks : provider.pendingTasks;

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  showCompleted ? Icons.check_circle : Icons.task_alt,
                  size: 64,
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  showCompleted ? 'No completed tasks' : 'No pending tasks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  showCompleted
                      ? 'Complete some tasks to see them here'
                      : 'Tap + to add a new task',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ).animate().fadeIn();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: tasks.length + 1, // +1 for bottom padding
          itemBuilder: (context, index) {
            if (index == tasks.length) {
              return const SizedBox(height: 100);
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTaskItem(context, tasks[index], provider),
            ).animate().fadeIn(
                  duration: 400.ms,
                  delay: Duration(milliseconds: 100 * index),
                ).slideX(begin: 0.1);
          },
        );
      },
    );
  }

  Widget _buildTaskItem(
      BuildContext context, Task task, TaskProvider provider) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => provider.deleteTask(task.id),
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () {
                final wasCompleted = task.isCompleted;
                provider.toggleTaskCompletion(task.id);
                // Trigger celebration when completing (not uncompleting)
                if (!wasCompleted) {
                  _onTaskCompleted();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isCompleted ? AppTheme.successColor : Colors.transparent,
                  border: Border.all(
                    color: task.isCompleted
                        ? AppTheme.successColor
                        : task.priority.color,
                    width: 2,
                  ),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTag(
                        task.priority.label,
                        task.priority.color,
                        task.priority.icon,
                      ),
                      if (task.category != null) ...[
                        const SizedBox(width: 8),
                        _buildTag(task.category!, AppTheme.accentColor, Icons.folder),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Schedule and AI buttons (only for pending tasks)
            if (!task.isCompleted) ...[
              // Schedule button
              IconButton(
                onPressed: () => _showScheduleTaskDialog(context, task),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: AppTheme.accentColor,
                    size: 18,
                  ),
                ),
                tooltip: 'Schedule task',
              ),
              // AI Breakdown button
              IconButton(
                onPressed: () => showAITaskBreakdownDialog(context, task),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                tooltip: 'Break down with AI',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    Priority selectedPriority = Priority.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add New Task',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Task title',
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Description (optional)',
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Priority',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: Priority.values.map((priority) {
                        final isSelected = selectedPriority == priority;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => selectedPriority = priority);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? priority.color.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? priority.color : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(priority.icon, color: priority.color),
                                  const SizedBox(height: 4),
                                  Text(
                                    priority.label,
                                    style: TextStyle(
                                      color: priority.color,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isNotEmpty) {
                            context.read<TaskProvider>().addTask(
                                  Task(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    title: titleController.text,
                                    description: descriptionController.text.isEmpty
                                        ? null
                                        : descriptionController.text,
                                    priority: selectedPriority,
                                    createdAt: DateTime.now(),
                                  ),
                                );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Add Task'),
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

  void _showScheduleTaskDialog(BuildContext context, Task task) {
    final plannerProvider = context.read<PlannerProvider>();
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calendar_today, color: AppTheme.accentColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Task',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Time picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Start time'),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setState(() => selectedTime = picked);
                    }
                  },
                  child: Text(
                    selectedTime.format(context),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),

              // Duration
              ListTile(
                contentPadding: EdgeInsets.zero,
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
                child: ElevatedButton.icon(
                  onPressed: () {
                    final today = DateTime.now();
                    final start = DateTime(
                      today.year,
                      today.month,
                      today.day,
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

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Scheduled "${task.title}" for ${selectedTime.format(context)}'),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'View Plan',
                          onPressed: () {
                            // Navigate to planner (index 3)
                            // This would require accessing the main navigation
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Schedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
