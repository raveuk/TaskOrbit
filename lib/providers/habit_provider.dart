import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

class HabitProvider extends ChangeNotifier {
  static const String _storageKey = 'habits_data';

  List<Habit> _habits = [];
  bool _isLoading = true;

  List<Habit> get habits => List.unmodifiable(_habits);
  bool get isLoading => _isLoading;

  List<Habit> get activeHabits =>
      _habits.where((habit) => habit.isActive).toList();

  List<Habit> get todayHabits {
    return _habits.where((habit) => habit.isActive && habit.isDueToday).toList();
  }

  int get completedTodayCount {
    return todayHabits.where((habit) => habit.isCompletedToday).length;
  }

  HabitProvider() {
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final habitsJson = prefs.getString(_storageKey);

      if (habitsJson != null && habitsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(habitsJson);
        _habits = decoded.map((json) => Habit.fromJson(json)).toList();
      } else {
        // Load sample habits for first-time users
        _loadSampleHabits();
        await _saveHabits(); // Save samples so they persist
      }
    } catch (e) {
      debugPrint('Error loading habits: $e');
      // If there's an error, start fresh with samples
      _loadSampleHabits();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final habitsJson = jsonEncode(_habits.map((h) => h.toJson()).toList());
      await prefs.setString(_storageKey, habitsJson);
    } catch (e) {
      debugPrint('Error saving habits: $e');
    }
  }

  void _loadSampleHabits() {
    _habits = [
      Habit(
        id: '1',
        name: 'Morning meditation',
        description: 'Start the day with 10 minutes of mindfulness',
        frequency: HabitFrequency.daily,
        icon: Icons.self_improvement,
        color: Colors.purple,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Habit(
        id: '2',
        name: 'Exercise',
        description: 'Move your body for at least 30 minutes',
        frequency: HabitFrequency.daily,
        icon: Icons.fitness_center,
        color: Colors.orange,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      Habit(
        id: '3',
        name: 'Read for 30 mins',
        description: 'Read something educational or inspiring',
        frequency: HabitFrequency.daily,
        icon: Icons.menu_book,
        color: Colors.blue,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Habit(
        id: '4',
        name: 'Weekly review',
        description: 'Review your goals and progress for the week',
        frequency: HabitFrequency.weekly,
        icon: Icons.calendar_month,
        color: Colors.green,
        createdAt: DateTime.now().subtract(const Duration(days: 21)),
      ),
    ];
  }

  Future<void> addHabit(Habit habit) async {
    _habits.add(habit);
    notifyListeners();
    await _saveHabits();
  }

  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = habit;
      notifyListeners();
      await _saveHabits();
    }
  }

  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((habit) => habit.id == habitId);
    notifyListeners();
    await _saveHabits();
  }

  Future<void> toggleHabitCompletion(String habitId) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      final habit = _habits[index];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      List<DateTime> newCompletedDates = List.from(habit.completedDates);

      if (habit.isCompletedToday) {
        // Remove today's completion
        newCompletedDates.removeWhere((date) {
          final d = DateTime(date.year, date.month, date.day);
          return d.isAtSameMomentAs(today);
        });
      } else {
        // Add today's completion
        newCompletedDates.add(now);
      }

      _habits[index] = habit.copyWith(completedDates: newCompletedDates);
      notifyListeners();
      await _saveHabits();
    }
  }

  Future<void> toggleHabitActive(String habitId) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      final habit = _habits[index];
      _habits[index] = habit.copyWith(isActive: !habit.isActive);
      notifyListeners();
      await _saveHabits();
    }
  }

  int getStreak(String habitId) {
    final habit = _habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => throw Exception('Habit not found'),
    );
    return habit.currentStreak;
  }

  // Get habits that need location-based reminders
  List<Habit> get habitsWithLocationReminders {
    return _habits.where((h) => h.hasLocationReminder && h.isActive).toList();
  }

  // Clear all habits (for testing/reset)
  Future<void> clearAllHabits() async {
    _habits.clear();
    notifyListeners();
    await _saveHabits();
  }

  // Reset to sample habits
  Future<void> resetToSampleHabits() async {
    _loadSampleHabits();
    notifyListeners();
    await _saveHabits();
  }
}
