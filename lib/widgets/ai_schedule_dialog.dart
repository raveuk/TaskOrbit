import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../models/planned_task.dart';
import '../providers/planner_provider.dart';
import '../theme/app_theme.dart';

class AIScheduleDialog extends StatefulWidget {
  final List<Task> tasks;
  final Function(List<PlannedTask>)? onApply;

  const AIScheduleDialog({
    super.key,
    required this.tasks,
    this.onApply,
  });

  @override
  State<AIScheduleDialog> createState() => _AIScheduleDialogState();
}

class _AIScheduleDialogState extends State<AIScheduleDialog> {
  bool _isGenerating = true;
  List<PlannedTask> _suggestions = [];
  String _aiTip = '';

  @override
  void initState() {
    super.initState();
    _generateSchedule();
  }

  Future<void> _generateSchedule() async {
    setState(() => _isGenerating = true);

    // Simulate AI thinking
    await Future.delayed(const Duration(milliseconds: 800));

    final provider = context.read<PlannerProvider>();
    final suggestions = await provider.generateAISchedule(widget.tasks);

    // Generate AI tip based on task priorities
    final highPriorityCount = widget.tasks.where((t) => t.priority == Priority.high).length;
    if (highPriorityCount > 0) {
      _aiTip = 'I scheduled $highPriorityCount high-priority tasks in the morning when focus is typically best.';
    } else {
      _aiTip = 'I spread your tasks throughout the day with breaks in between for optimal focus.';
    }

    setState(() {
      _suggestions = suggestions;
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: _isGenerating ? _buildLoadingState() : _buildResultState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.auto_fix_high,
            color: Colors.white,
            size: 40,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1.seconds, color: Colors.white.withValues(alpha: 0.3))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 800.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              begin: const Offset(1.1, 1.1),
              end: const Offset(1, 1),
              duration: 800.ms,
              curve: Curves.easeInOut,
            ),
        const SizedBox(height: 24),
        Text(
          'Planning your day...',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Analyzing ${widget.tasks.length} tasks',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        const LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildResultState() {
    if (_suggestions.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No schedule suggestions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adding some tasks first or check available time slots.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_fix_high,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan My Day',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${_suggestions.length} tasks scheduled',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 16),

        // AI Tip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _aiTip,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

        const SizedBox(height: 16),

        // Suggestions list
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final task = _suggestions[index];
              return _buildSuggestionItem(task, index);
            },
          ),
        ),

        const SizedBox(height: 16),

        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Adjust'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onApply?.call(_suggestions);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Scheduled ${_suggestions.length} tasks'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Apply Schedule'),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
      ],
    );
  }

  Widget _buildSuggestionItem(PlannedTask task, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(task.scheduledStart),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${task.durationMinutes}min',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Color indicator
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: task.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Task info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.notes != null && task.notes!.isNotEmpty)
                  Text(
                    task.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 300 + (index * 50)),
          duration: 300.ms,
        ).slideX(begin: 0.1);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
