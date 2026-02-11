import 'package:flutter/material.dart';
import 'saved_location.dart' show LocationTriggerType;

enum Priority { high, medium, low }

extension PriorityExtension on Priority {
  String get label {
    switch (this) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case Priority.high:
        return const Color(0xFFEF4444);
      case Priority.medium:
        return const Color(0xFFF59E0B);
      case Priority.low:
        return const Color(0xFF10B981);
    }
  }

  IconData get icon {
    switch (this) {
      case Priority.high:
        return Icons.keyboard_double_arrow_up;
      case Priority.medium:
        return Icons.remove;
      case Priority.low:
        return Icons.keyboard_double_arrow_down;
    }
  }
}

class Task {
  final String id;
  final String title;
  final String? description;
  final Priority priority;
  final String? category;
  final DateTime? dueDate;
  final int? estimatedMinutes;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<String> subtasks;
  final List<bool> subtaskCompleted;
  // Location reminder fields
  final String? locationId;
  final LocationTriggerType? locationTrigger;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.priority = Priority.medium,
    this.category,
    this.dueDate,
    this.estimatedMinutes,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.subtasks = const [],
    this.subtaskCompleted = const [],
    this.locationId,
    this.locationTrigger,
  });

  bool get hasLocationReminder => locationId != null;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    Priority? priority,
    String? category,
    DateTime? dueDate,
    int? estimatedMinutes,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    List<String>? subtasks,
    List<bool>? subtaskCompleted,
    String? locationId,
    LocationTriggerType? locationTrigger,
    bool clearLocation = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt,
      subtasks: subtasks ?? this.subtasks,
      subtaskCompleted: subtaskCompleted ?? this.subtaskCompleted,
      locationId: clearLocation ? null : (locationId ?? this.locationId),
      locationTrigger: clearLocation ? null : (locationTrigger ?? this.locationTrigger),
    );
  }

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  int get completedSubtaskCount =>
      subtaskCompleted.where((completed) => completed).length;

  double get subtaskProgress {
    if (subtasks.isEmpty) return 0;
    return completedSubtaskCount / subtasks.length;
  }
}
