import 'package:flutter/material.dart';

class PlannedTask {
  final String id;
  final String? taskId; // Links to existing Task (nullable for standalone blocks)
  final String title;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final bool isCompleted;
  final String? notes;
  final Color color;
  final bool isRecurring;
  final String? recurrenceRule; // RRULE format for recurring blocks
  final DateTime createdAt;

  PlannedTask({
    required this.id,
    this.taskId,
    required this.title,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.isCompleted = false,
    this.notes,
    this.color = Colors.blue,
    this.isRecurring = false,
    this.recurrenceRule,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Computed properties
  Duration get duration => scheduledEnd.difference(scheduledStart);
  int get durationMinutes => duration.inMinutes;
  bool get isAllDay => duration.inHours >= 12;

  // Check if this planned task is for today
  bool get isToday {
    final now = DateTime.now();
    return scheduledStart.year == now.year &&
        scheduledStart.month == now.month &&
        scheduledStart.day == now.day;
  }

  // Check if currently active (now is between start and end)
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return now.isAfter(scheduledStart) && now.isBefore(scheduledEnd);
  }

  // Check if in the past
  bool get isPast => DateTime.now().isAfter(scheduledEnd);

  // Get hour of day (0-23) for timeline positioning
  double get startHour => scheduledStart.hour + (scheduledStart.minute / 60);
  double get endHour => scheduledEnd.hour + (scheduledEnd.minute / 60);

  // Format time range as string
  String get timeRangeString {
    final startStr = _formatTime(scheduledStart);
    final endStr = _formatTime(scheduledEnd);
    return '$startStr - $endStr';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  PlannedTask copyWith({
    String? id,
    String? taskId,
    String? title,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    bool? isCompleted,
    String? notes,
    Color? color,
    bool? isRecurring,
    String? recurrenceRule,
    DateTime? createdAt,
  }) {
    return PlannedTask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'title': title,
      'scheduledStart': scheduledStart.millisecondsSinceEpoch,
      'scheduledEnd': scheduledEnd.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
      'notes': notes,
      'colorValue': color.value,
      'isRecurring': isRecurring ? 1 : 0,
      'recurrenceRule': recurrenceRule,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PlannedTask.fromJson(Map<String, dynamic> json) {
    return PlannedTask(
      id: json['id'] as String? ?? '',
      taskId: json['taskId'] as String?,
      title: json['title'] as String? ?? 'Untitled',
      scheduledStart: DateTime.fromMillisecondsSinceEpoch(
        (json['scheduledStart'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      scheduledEnd: DateTime.fromMillisecondsSinceEpoch(
        (json['scheduledEnd'] as int?) ?? DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
      ),
      isCompleted: (json['isCompleted'] as int?) == 1,
      notes: json['notes'] as String?,
      color: Color((json['colorValue'] as int?) ?? Colors.blue.value),
      isRecurring: (json['isRecurring'] as int?) == 1,
      recurrenceRule: json['recurrenceRule'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  String toString() {
    return 'PlannedTask(id: $id, title: $title, start: $scheduledStart, end: $scheduledEnd)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlannedTask && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Time slot helper for finding free time
class TimeSlot {
  final DateTime start;
  final DateTime end;

  TimeSlot({required this.start, required this.end});

  Duration get duration => end.difference(start);
  int get durationMinutes => duration.inMinutes;

  bool canFit(int minutes) => durationMinutes >= minutes;

  @override
  String toString() => 'TimeSlot($start - $end)';
}
