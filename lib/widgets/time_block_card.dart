import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/planned_task.dart';
import '../theme/app_theme.dart';

class TimeBlockCard extends StatelessWidget {
  final PlannedTask task;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final double height;
  final bool showTimeRange;
  final bool isDragging;

  const TimeBlockCard({
    super.key,
    required this.task,
    this.onTap,
    this.onLongPress,
    this.onComplete,
    this.onDelete,
    this.height = 60,
    this.showTimeRange = true,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.isCompleted;
    final isActive = task.isCurrentlyActive && !isCompleted;
    final isPast = task.isPast && !isCompleted;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isCompleted
              ? task.color.withValues(alpha: 0.2)
              : isActive
                  ? task.color
                  : task.color.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: Colors.white, width: 2)
              : isDragging
                  ? Border.all(color: task.color, width: 2)
                  : null,
          boxShadow: isActive || isDragging
              ? [
                  BoxShadow(
                    color: task.color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Completion checkbox
                if (onComplete != null)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onComplete?.call();
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: task.color,
                            )
                          : null,
                    ),
                  ),

                // Task info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: isCompleted
                              ? task.color.withValues(alpha: 0.7)
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: height > 50 ? 14 : 12,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showTimeRange && height > 40) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.timeRangeString,
                          style: TextStyle(
                            color: isCompleted
                                ? task.color.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Duration badge
                if (height > 50)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isCompleted ? 0.2 : 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDuration(task.durationMinutes),
                      style: TextStyle(
                        color: isCompleted
                            ? task.color.withValues(alpha: 0.7)
                            : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Active indicator
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],

                // Overdue indicator
                if (isPast) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.warning_amber,
                      color: AppTheme.errorColor,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate(
      effects: isDragging
          ? [
              const ScaleEffect(
                begin: Offset(1, 1),
                end: Offset(1.02, 1.02),
                duration: Duration(milliseconds: 150),
              ),
            ]
          : [],
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }
}

// Compact version for weekly view
class MiniTimeBlockCard extends StatelessWidget {
  final PlannedTask task;
  final VoidCallback? onTap;

  const MiniTimeBlockCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? task.color.withValues(alpha: 0.3)
              : task.color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          task.title,
          style: TextStyle(
            color: task.isCompleted
                ? task.color.withValues(alpha: 0.7)
                : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// Empty slot card for adding new tasks
class EmptyTimeSlot extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final VoidCallback? onTap;

  const EmptyTimeSlot({
    super.key,
    required this.start,
    required this.end,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              'Add task',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
