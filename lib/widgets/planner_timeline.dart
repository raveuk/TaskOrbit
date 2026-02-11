import 'dart:async';
import 'package:flutter/material.dart';

import '../models/planned_task.dart';
import '../theme/app_theme.dart';
import 'time_block_card.dart';

class PlannerTimeline extends StatefulWidget {
  final List<PlannedTask> tasks;
  final int startHour;
  final int endHour;
  final double hourHeight;
  final Function(PlannedTask)? onTaskTap;
  final Function(PlannedTask)? onTaskLongPress;
  final Function(PlannedTask)? onTaskComplete;
  final Function(int hour)? onEmptySlotTap;
  final bool showCurrentTime;

  const PlannerTimeline({
    super.key,
    required this.tasks,
    this.startHour = 6,
    this.endHour = 23,
    this.hourHeight = 60,
    this.onTaskTap,
    this.onTaskLongPress,
    this.onTaskComplete,
    this.onEmptySlotTap,
    this.showCurrentTime = true,
  });

  @override
  State<PlannerTimeline> createState() => _PlannerTimelineState();
}

class _PlannerTimelineState extends State<PlannerTimeline> {
  Timer? _timer;
  double _currentTimePosition = 0;

  @override
  void initState() {
    super.initState();
    _updateCurrentTimePosition();
    // Update every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateCurrentTimePosition();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCurrentTimePosition() {
    final now = DateTime.now();
    final currentHour = now.hour + (now.minute / 60);

    if (currentHour >= widget.startHour && currentHour <= widget.endHour) {
      setState(() {
        _currentTimePosition = (currentHour - widget.startHour) * widget.hourHeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = widget.endHour - widget.startHour;
    final totalHeight = totalHours * widget.hourHeight;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          // Hour lines and labels
          ...List.generate(totalHours + 1, (index) {
            final hour = widget.startHour + index;
            final yPosition = index * widget.hourHeight;
            return Positioned(
              top: yPosition,
              left: 0,
              right: 0,
              child: _buildHourLine(context, hour),
            );
          }),

          // Task blocks
          ...widget.tasks.map((task) => _buildTaskBlock(task)),

          // Current time indicator
          if (widget.showCurrentTime && _isCurrentTimeVisible())
            Positioned(
              top: _currentTimePosition,
              left: 0,
              right: 0,
              child: _buildCurrentTimeIndicator(),
            ),
        ],
      ),
    );
  }

  bool _isCurrentTimeVisible() {
    final now = DateTime.now();
    final currentHour = now.hour + (now.minute / 60);
    return currentHour >= widget.startHour && currentHour <= widget.endHour;
  }

  Widget _buildHourLine(BuildContext context, int hour) {
    final isCurrentHour = DateTime.now().hour == hour;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hour label
        SizedBox(
          width: 50,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              _formatHour(hour),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.normal,
                color: isCurrentHour
                    ? AppTheme.primaryColor
                    : Colors.grey,
              ),
            ),
          ),
        ),
        // Line
        Expanded(
          child: Container(
            height: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskBlock(PlannedTask task) {
    // Calculate position
    final taskStartHour = task.scheduledStart.hour + (task.scheduledStart.minute / 60);
    final taskEndHour = task.scheduledEnd.hour + (task.scheduledEnd.minute / 60);

    // Clamp to visible range
    final visibleStart = taskStartHour.clamp(widget.startHour.toDouble(), widget.endHour.toDouble());
    final visibleEnd = taskEndHour.clamp(widget.startHour.toDouble(), widget.endHour.toDouble());

    if (visibleStart >= visibleEnd) return const SizedBox.shrink();

    final yPosition = (visibleStart - widget.startHour) * widget.hourHeight;
    final height = (visibleEnd - visibleStart) * widget.hourHeight;

    return Positioned(
      top: yPosition,
      left: 58, // Account for hour label width
      right: 8,
      height: height.clamp(30, double.infinity),
      child: TimeBlockCard(
        task: task,
        height: height.clamp(30, double.infinity),
        onTap: () => widget.onTaskTap?.call(task),
        onLongPress: () => widget.onTaskLongPress?.call(task),
        onComplete: () => widget.onTaskComplete?.call(task),
      ),
    );
  }

  Widget _buildCurrentTimeIndicator() {
    return Row(
      children: [
        // Time label
        Container(
          width: 50,
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            _formatCurrentTime(),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.errorColor,
            ),
          ),
        ),
        // Red dot
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppTheme.errorColor,
            shape: BoxShape.circle,
          ),
        ),
        // Red line
        Expanded(
          child: Container(
            height: 2,
            color: AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour > 12) return '${hour - 12} PM';
    return '$hour AM';
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute';
  }
}

// Day capacity indicator widget
class DayCapacityIndicator extends StatelessWidget {
  final int scheduledMinutes;
  final int maxMinutes;
  final Color? color;

  const DayCapacityIndicator({
    super.key,
    required this.scheduledMinutes,
    this.maxMinutes = 480, // 8 hours default
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (scheduledMinutes / maxMinutes).clamp(0.0, 1.0);
    final hours = scheduledMinutes / 60;

    Color barColor;
    if (percentage > 0.9) {
      barColor = AppTheme.errorColor;
    } else if (percentage > 0.7) {
      barColor = AppTheme.warningColor;
    } else {
      barColor = color ?? AppTheme.successColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${hours.toStringAsFixed(1)}h scheduled',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              '${(percentage * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
