import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/grok_ai_provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class AITaskBreakdownDialog extends StatefulWidget {
  final Task task;

  const AITaskBreakdownDialog({super.key, required this.task});

  @override
  State<AITaskBreakdownDialog> createState() => _AITaskBreakdownDialogState();
}

class _AITaskBreakdownDialogState extends State<AITaskBreakdownDialog> {
  List<String> _subtasks = [];
  List<bool> _selectedSubtasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Schedule subtask loading after the first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubtasks();
    });
  }

  Future<void> _loadSubtasks() async {
    if (!mounted) return;
    final grokProvider = context.read<GrokAIProvider>();
    final subtasks = await grokProvider.chunkTask(
      widget.task.title,
      taskDescription: widget.task.description,
    );

    if (!mounted) return;
    setState(() {
      _subtasks = subtasks;
      _selectedSubtasks = List.filled(subtasks.length, true);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: _buildContent()),
            _buildActions(),
          ],
        ),
      ).animate().scale(
            duration: 300.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Break It Down',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.task.title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Breaking it down...',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: _subtasks.length,
      itemBuilder: (context, index) {
        return _buildSubtaskItem(index);
      },
    );
  }

  Widget _buildSubtaskItem(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedSubtasks[index] = !_selectedSubtasks[index];
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedSubtasks[index]
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedSubtasks[index]
                    ? AppTheme.primaryColor
                    : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                width: _selectedSubtasks[index] ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _selectedSubtasks[index]
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedSubtasks[index]
                          ? AppTheme.primaryColor
                          : Theme.of(context).dividerColor,
                      width: 2,
                    ),
                  ),
                  child: _selectedSubtasks[index]
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _subtasks[index],
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().slideX(begin: 0.1),
    );
  }

  Widget _buildActions() {
    final selectedCount = _selectedSubtasks.where((s) => s).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '$selectedCount selected',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: selectedCount > 0 ? _addSelectedAsSubtasks : null,
            icon: const Icon(Icons.add_task, size: 18),
            label: const Text('Add as Tasks'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _addSelectedAsSubtasks() {
    final taskProvider = context.read<TaskProvider>();

    for (int i = 0; i < _subtasks.length; i++) {
      if (_selectedSubtasks[i]) {
        taskProvider.addTask(
          Task(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            title: _subtasks[i],
            description: 'Part of: ${widget.task.title}',
            priority: widget.task.priority,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white),
            const SizedBox(width: 12),
            Text('Added ${_selectedSubtasks.where((s) => s).length} subtasks'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Helper function to show the dialog
Future<void> showAITaskBreakdownDialog(BuildContext context, Task task) {
  return showDialog(
    context: context,
    builder: (context) => AITaskBreakdownDialog(task: task),
  );
}
