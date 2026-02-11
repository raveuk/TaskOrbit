import 'dart:async';
import 'package:flutter/material.dart';

enum TimerPhase { work, shortBreak, longBreak }

enum TimerPreset { pomodoro, shortBreak, longBreak, custom }

class TimerProvider extends ChangeNotifier {
  // Timer durations in seconds
  int _workDuration = 25 * 60; // 25 minutes
  int _shortBreakDuration = 5 * 60; // 5 minutes
  int _longBreakDuration = 15 * 60; // 15 minutes
  int _sessionsBeforeLongBreak = 4;

  // Current timer state
  int _timeLeft = 25 * 60;
  bool _isRunning = false;
  TimerPhase _currentPhase = TimerPhase.work;
  int _completedSessions = 0;
  int _todayCompletedSessions = 0;

  Timer? _timer;

  // Getters
  int get workDuration => _workDuration;
  int get shortBreakDuration => _shortBreakDuration;
  int get longBreakDuration => _longBreakDuration;
  int get timeLeft => _timeLeft;
  bool get isRunning => _isRunning;
  TimerPhase get currentPhase => _currentPhase;
  int get completedSessions => _completedSessions;
  int get todayCompletedSessions => _todayCompletedSessions;

  double get progress {
    final total = _getDurationForPhase(_currentPhase);
    return 1.0 - (_timeLeft / total);
  }

  String get timeLeftFormatted {
    final minutes = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get phaseLabel {
    switch (_currentPhase) {
      case TimerPhase.work:
        return 'Focus Time';
      case TimerPhase.shortBreak:
        return 'Short Break';
      case TimerPhase.longBreak:
        return 'Long Break';
    }
  }

  int _getDurationForPhase(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.work:
        return _workDuration;
      case TimerPhase.shortBreak:
        return _shortBreakDuration;
      case TimerPhase.longBreak:
        return _longBreakDuration;
    }
  }

  void toggleTimer() {
    if (_isRunning) {
      pauseTimer();
    } else {
      startTimer();
    }
  }

  void startTimer() {
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        notifyListeners();
      } else {
        _handlePhaseComplete();
      }
    });
    notifyListeners();
  }

  void pauseTimer() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void resetTimer() {
    pauseTimer();
    _timeLeft = _getDurationForPhase(_currentPhase);
    notifyListeners();
  }

  void skipPhase() {
    _handlePhaseComplete();
  }

  void _handlePhaseComplete() {
    pauseTimer();

    if (_currentPhase == TimerPhase.work) {
      _completedSessions++;
      _todayCompletedSessions++;

      // Determine next break type
      if (_completedSessions % _sessionsBeforeLongBreak == 0) {
        _currentPhase = TimerPhase.longBreak;
        _timeLeft = _longBreakDuration;
      } else {
        _currentPhase = TimerPhase.shortBreak;
        _timeLeft = _shortBreakDuration;
      }
    } else {
      // After break, start work phase
      _currentPhase = TimerPhase.work;
      _timeLeft = _workDuration;
    }

    notifyListeners();
  }

  void setPreset(TimerPreset preset) {
    pauseTimer();
    switch (preset) {
      case TimerPreset.pomodoro:
        _currentPhase = TimerPhase.work;
        _timeLeft = _workDuration;
        break;
      case TimerPreset.shortBreak:
        _currentPhase = TimerPhase.shortBreak;
        _timeLeft = _shortBreakDuration;
        break;
      case TimerPreset.longBreak:
        _currentPhase = TimerPhase.longBreak;
        _timeLeft = _longBreakDuration;
        break;
      case TimerPreset.custom:
        // Handle custom preset
        break;
    }
    notifyListeners();
  }

  void updateDurations({
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
  }) {
    if (workMinutes != null) _workDuration = workMinutes * 60;
    if (shortBreakMinutes != null) _shortBreakDuration = shortBreakMinutes * 60;
    if (longBreakMinutes != null) _longBreakDuration = longBreakMinutes * 60;
    if (sessionsBeforeLongBreak != null) {
      _sessionsBeforeLongBreak = sessionsBeforeLongBreak;
    }

    // Reset current timer if not running
    if (!_isRunning) {
      _timeLeft = _getDurationForPhase(_currentPhase);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
