import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/planned_task.dart';
import '../models/task.dart';

class PlannerProvider extends ChangeNotifier {
  List<PlannedTask> _plannedTasks = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Getters
  List<PlannedTask> get plannedTasks => List.unmodifiable(_plannedTasks);
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;

  // Get tasks for today
  List<PlannedTask> get todayPlanned {
    final now = DateTime.now();
    return _plannedTasks.where((task) {
      return task.scheduledStart.year == now.year &&
          task.scheduledStart.month == now.month &&
          task.scheduledStart.day == now.day;
    }).toList()
      ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
  }

  // Get tasks for selected date
  List<PlannedTask> get selectedDatePlanned {
    return _plannedTasks.where((task) {
      return task.scheduledStart.year == _selectedDate.year &&
          task.scheduledStart.month == _selectedDate.month &&
          task.scheduledStart.day == _selectedDate.day;
    }).toList()
      ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
  }

  // Get total scheduled minutes for a date
  int getTotalScheduledMinutes(DateTime date) {
    return getTasksForDate(date).fold(0, (sum, task) => sum + task.durationMinutes);
  }

  // Get tasks for any specific date
  List<PlannedTask> getTasksForDate(DateTime date) {
    return _plannedTasks.where((task) {
      return task.scheduledStart.year == date.year &&
          task.scheduledStart.month == date.month &&
          task.scheduledStart.day == date.day;
    }).toList()
      ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
  }

  // Get tasks for a week
  List<PlannedTask> getTasksForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _plannedTasks.where((task) {
      return task.scheduledStart.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          task.scheduledStart.isBefore(weekEnd);
    }).toList()
      ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
  }

  // Get currently active task (if any)
  PlannedTask? get currentlyActiveTask {
    try {
      return _plannedTasks.firstWhere((task) => task.isCurrentlyActive && !task.isCompleted);
    } catch (_) {
      return null;
    }
  }

  // Get next upcoming task
  PlannedTask? get nextUpcomingTask {
    final now = DateTime.now();
    final upcoming = _plannedTasks
        .where((task) => task.scheduledStart.isAfter(now) && !task.isCompleted)
        .toList()
      ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  PlannerProvider() {
    _loadPlannedTasks();
  }

  // Set selected date
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Go to today
  void goToToday() {
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  // Navigate days
  void nextDay() {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    notifyListeners();
  }

  void previousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    notifyListeners();
  }

  // Load from SharedPreferences
  Future<void> _loadPlannedTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString('planned_tasks');
      if (tasksJson != null) {
        final List<dynamic> decoded = json.decode(tasksJson);
        _plannedTasks = decoded.map((e) => PlannedTask.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading planned tasks: $e');
      _plannedTasks = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Save to SharedPreferences
  Future<void> _savePlannedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(_plannedTasks.map((e) => e.toJson()).toList());
      await prefs.setString('planned_tasks', encoded);
    } catch (e) {
      debugPrint('Error saving planned tasks: $e');
    }
  }

  // CRUD Operations
  Future<void> addPlannedTask(PlannedTask task) async {
    _plannedTasks.add(task);
    await _savePlannedTasks();
    notifyListeners();
  }

  Future<void> updatePlannedTask(PlannedTask task) async {
    final index = _plannedTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _plannedTasks[index] = task;
      await _savePlannedTasks();
      notifyListeners();
    }
  }

  Future<void> deletePlannedTask(String id) async {
    _plannedTasks.removeWhere((t) => t.id == id);
    await _savePlannedTasks();
    notifyListeners();
  }

  // Toggle completion
  Future<void> toggleCompletion(String id) async {
    final index = _plannedTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _plannedTasks[index];
      _plannedTasks[index] = task.copyWith(isCompleted: !task.isCompleted);
      await _savePlannedTasks();
      notifyListeners();
    }
  }

  // Complete a planned task
  Future<void> completePlannedTask(String id) async {
    final index = _plannedTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _plannedTasks[index] = _plannedTasks[index].copyWith(isCompleted: true);
      await _savePlannedTasks();
      notifyListeners();
    }
  }

  // Complete linked planned task when Task is completed
  Future<void> completeLinkedPlanned(String taskId) async {
    bool changed = false;
    for (int i = 0; i < _plannedTasks.length; i++) {
      if (_plannedTasks[i].taskId == taskId && !_plannedTasks[i].isCompleted) {
        _plannedTasks[i] = _plannedTasks[i].copyWith(isCompleted: true);
        changed = true;
      }
    }
    if (changed) {
      await _savePlannedTasks();
      notifyListeners();
    }
  }

  // Schedule an existing Task
  Future<PlannedTask> scheduleTask({
    required Task task,
    required DateTime start,
    required DateTime end,
  }) async {
    final planned = PlannedTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: task.id,
      title: task.title,
      scheduledStart: start,
      scheduledEnd: end,
      color: _priorityToColor(task.priority),
      notes: task.description,
    );
    await addPlannedTask(planned);
    return planned;
  }

  Color _priorityToColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return const Color(0xFFEF4444); // Red
      case Priority.medium:
        return const Color(0xFFF59E0B); // Amber
      case Priority.low:
        return const Color(0xFF10B981); // Green
    }
  }

  // Reschedule a planned task
  Future<void> rescheduleTask({
    required String id,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    final index = _plannedTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _plannedTasks[index] = _plannedTasks[index].copyWith(
        scheduledStart: newStart,
        scheduledEnd: newEnd,
      );
      await _savePlannedTasks();
      notifyListeners();
    }
  }

  // Check for time conflicts
  bool hasConflict(DateTime start, DateTime end, {String? excludeId}) {
    return _plannedTasks.any((task) {
      if (task.id == excludeId) return false;
      // Check if the times overlap
      return start.isBefore(task.scheduledEnd) && end.isAfter(task.scheduledStart);
    });
  }

  // Get free time slots for a date
  List<TimeSlot> getFreeSlots(DateTime date, {int workdayStart = 8, int workdayEnd = 18}) {
    final List<TimeSlot> freeSlots = [];
    final dayTasks = getTasksForDate(date);

    final dayStart = DateTime(date.year, date.month, date.day, workdayStart);
    final dayEnd = DateTime(date.year, date.month, date.day, workdayEnd);

    if (dayTasks.isEmpty) {
      return [TimeSlot(start: dayStart, end: dayEnd)];
    }

    // Sort tasks by start time
    dayTasks.sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));

    // Check gap before first task
    if (dayTasks.first.scheduledStart.isAfter(dayStart)) {
      freeSlots.add(TimeSlot(start: dayStart, end: dayTasks.first.scheduledStart));
    }

    // Check gaps between tasks
    for (int i = 0; i < dayTasks.length - 1; i++) {
      final currentEnd = dayTasks[i].scheduledEnd;
      final nextStart = dayTasks[i + 1].scheduledStart;
      if (nextStart.isAfter(currentEnd)) {
        freeSlots.add(TimeSlot(start: currentEnd, end: nextStart));
      }
    }

    // Check gap after last task
    if (dayTasks.last.scheduledEnd.isBefore(dayEnd)) {
      freeSlots.add(TimeSlot(start: dayTasks.last.scheduledEnd, end: dayEnd));
    }

    return freeSlots;
  }

  // AI Schedule Generation (uses existing task list)
  Future<List<PlannedTask>> generateAISchedule(List<Task> unscheduledTasks) async {
    final List<PlannedTask> suggestions = [];
    final today = DateTime.now();
    final freeSlots = getFreeSlots(today);

    // Sort tasks by priority (high first)
    final sortedTasks = List<Task>.from(unscheduledTasks)
      ..sort((a, b) {
        final priorityOrder = {Priority.high: 0, Priority.medium: 1, Priority.low: 2};
        return (priorityOrder[a.priority] ?? 2).compareTo(priorityOrder[b.priority] ?? 2);
      });

    DateTime currentTime = DateTime(today.year, today.month, today.day, 9); // Start at 9 AM

    for (final task in sortedTasks) {
      // Estimate duration (default 30 min if not specified)
      final durationMinutes = task.estimatedMinutes ?? 30;
      final end = currentTime.add(Duration(minutes: durationMinutes));

      // Skip if past work hours (6 PM)
      if (end.hour >= 18) break;

      suggestions.add(PlannedTask(
        id: 'suggestion_${DateTime.now().millisecondsSinceEpoch}_${task.id}',
        taskId: task.id,
        title: task.title,
        scheduledStart: currentTime,
        scheduledEnd: end,
        color: _priorityToColor(task.priority),
        notes: task.description,
      ));

      // Add 15 min buffer between tasks
      currentTime = end.add(const Duration(minutes: 15));
    }

    return suggestions;
  }

  // Apply AI schedule suggestions
  Future<void> applyAISchedule(List<PlannedTask> suggestions) async {
    for (final suggestion in suggestions) {
      // Create a real planned task from suggestion
      final planned = suggestion.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      _plannedTasks.add(planned);
    }
    await _savePlannedTasks();
    notifyListeners();
  }

  // Clear all completed tasks older than a week
  Future<void> clearOldCompletedTasks() async {
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    _plannedTasks.removeWhere((task) =>
        task.isCompleted && task.scheduledEnd.isBefore(oneWeekAgo));
    await _savePlannedTasks();
    notifyListeners();
  }

  // Get statistics
  Map<String, dynamic> getStatistics() {
    final today = DateTime.now();
    final todayTasks = getTasksForDate(today);
    final completed = todayTasks.where((t) => t.isCompleted).length;
    final total = todayTasks.length;

    return {
      'todayTotal': total,
      'todayCompleted': completed,
      'todayRemaining': total - completed,
      'todayMinutesScheduled': getTotalScheduledMinutes(today),
      'completionRate': total > 0 ? (completed / total * 100).round() : 0,
    };
  }
}
