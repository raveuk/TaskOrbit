import 'package:flutter/material.dart';
import 'saved_location.dart' show LocationTriggerType;

enum HabitFrequency { daily, weekly, custom }

extension HabitFrequencyExtension on HabitFrequency {
  String get label {
    switch (this) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }
}

class Habit {
  final String id;
  final String name;
  final String? description;
  final HabitFrequency frequency;
  final List<int>? customDays; // 1-7 for custom frequency
  final IconData icon;
  final Color color;
  final bool isActive;
  final DateTime createdAt;
  final List<DateTime> completedDates;
  final TimeOfDay? reminderTime;
  // Location reminder fields
  final String? locationId;
  final LocationTriggerType? locationTrigger;

  Habit({
    required this.id,
    required this.name,
    this.description,
    this.frequency = HabitFrequency.daily,
    this.customDays,
    this.icon = Icons.check_circle,
    this.color = Colors.blue,
    this.isActive = true,
    required this.createdAt,
    this.completedDates = const [],
    this.reminderTime,
    this.locationId,
    this.locationTrigger,
  });

  bool get hasLocationReminder => locationId != null;

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    HabitFrequency? frequency,
    List<int>? customDays,
    IconData? icon,
    Color? color,
    bool? isActive,
    DateTime? createdAt,
    List<DateTime>? completedDates,
    TimeOfDay? reminderTime,
    String? locationId,
    LocationTriggerType? locationTrigger,
    bool clearLocation = false,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
      reminderTime: reminderTime ?? this.reminderTime,
      locationId: clearLocation ? null : (locationId ?? this.locationId),
      locationTrigger: clearLocation ? null : (locationTrigger ?? this.locationTrigger),
    );
  }

  bool get isCompletedToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return completedDates.any((date) {
      final d = DateTime(date.year, date.month, date.day);
      return d.isAtSameMomentAs(today);
    });
  }

  bool get isDueToday {
    if (!isActive) return false;
    final now = DateTime.now();
    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        // Check if today is the same weekday as when habit was created
        return now.weekday == createdAt.weekday;
      case HabitFrequency.custom:
        return customDays?.contains(now.weekday) ?? false;
    }
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    // Sort dates in descending order
    final sortedDates = List<DateTime>.from(completedDates)
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime checkDate = DateTime.now();

    // If not completed today, start checking from yesterday
    if (!isCompletedToday) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    for (final date in sortedDates) {
      final d = DateTime(date.year, date.month, date.day);
      final check = DateTime(checkDate.year, checkDate.month, checkDate.day);

      if (d.isAtSameMomentAs(check)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (d.isBefore(check)) {
        break;
      }
    }

    return streak;
  }

  int get longestStreak {
    if (completedDates.isEmpty) return 0;

    // Sort dates in ascending order
    final sortedDates = List<DateTime>.from(completedDates)
      ..sort((a, b) => a.compareTo(b));

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final prev = DateTime(
        sortedDates[i - 1].year,
        sortedDates[i - 1].month,
        sortedDates[i - 1].day,
      );
      final curr = DateTime(
        sortedDates[i].year,
        sortedDates[i].month,
        sortedDates[i].day,
      );

      if (curr.difference(prev).inDays == 1) {
        currentStreak++;
        maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
      } else if (curr.difference(prev).inDays > 1) {
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  int get totalCompletions => completedDates.length;

  double get completionRate {
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays + 1;
    if (daysSinceCreation <= 0) return 0;
    return (totalCompletions / daysSinceCreation).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'frequency': frequency.name,
      'customDays': customDays,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.value,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
      'reminderTimeHour': reminderTime?.hour,
      'reminderTimeMinute': reminderTime?.minute,
      'locationId': locationId,
      'locationTrigger': locationTrigger?.name,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    TimeOfDay? reminderTime;
    if (json['reminderTimeHour'] != null && json['reminderTimeMinute'] != null) {
      reminderTime = TimeOfDay(
        hour: json['reminderTimeHour'] as int,
        minute: json['reminderTimeMinute'] as int,
      );
    }

    LocationTriggerType? trigger;
    if (json['locationTrigger'] != null) {
      trigger = LocationTriggerType.values.firstWhere(
        (e) => e.name == json['locationTrigger'],
        orElse: () => LocationTriggerType.onArrive,
      );
    }

    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      customDays: (json['customDays'] as List<dynamic>?)?.cast<int>(),
      icon: IconData(
        (json['iconCodePoint'] as int?) ?? Icons.check_circle.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      color: Color((json['colorValue'] as int?) ?? Colors.blue.value),
      isActive: (json['isActive'] as bool?) ?? true,
      createdAt: _parseDateTime(json['createdAt']),
      completedDates: (json['completedDates'] as List<dynamic>?)
              ?.map((d) => DateTime.tryParse(d as String) ?? DateTime.now())
              .toList() ??
          [],
      reminderTime: reminderTime,
      locationId: json['locationId'] as String?,
      locationTrigger: trigger,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value as String);
    } catch (_) {
      return DateTime.now();
    }
  }
}
