import 'package:flutter/foundation.dart';

enum CelebrationType {
  taskComplete,
  habitComplete,
  streakMilestone,
  timerComplete,
  levelUp,
  epic,
}

class CelebrationProvider extends ChangeNotifier {
  CelebrationType? _currentCelebration;
  bool _shouldCelebrate = false;

  CelebrationType? get currentCelebration => _currentCelebration;
  bool get shouldCelebrate => _shouldCelebrate;

  void triggerCelebration(CelebrationType type) {
    _currentCelebration = type;
    _shouldCelebrate = true;
    notifyListeners();
  }

  void celebrateTaskComplete() {
    triggerCelebration(CelebrationType.taskComplete);
  }

  void celebrateHabitComplete() {
    triggerCelebration(CelebrationType.habitComplete);
  }

  void celebrateStreakMilestone() {
    triggerCelebration(CelebrationType.streakMilestone);
  }

  void celebrateTimerComplete() {
    triggerCelebration(CelebrationType.timerComplete);
  }

  void celebrateLevelUp() {
    triggerCelebration(CelebrationType.levelUp);
  }

  void celebrateEpic() {
    triggerCelebration(CelebrationType.epic);
  }

  void clearCelebration() {
    _currentCelebration = null;
    _shouldCelebrate = false;
    notifyListeners();
  }
}
