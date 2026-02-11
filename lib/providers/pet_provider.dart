import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';

enum PetInteraction {
  taskReward,
  habitReward,
  pomodoroReward,
  fed,
  played,
  tooTired,
  levelUp,
}

class PetProvider extends ChangeNotifier {
  Pet _pet = Pet();
  PetInteraction? _lastInteraction;
  int? _levelUpTo;

  Pet get pet => _pet;
  PetInteraction? get lastInteraction => _lastInteraction;
  int? get levelUpTo => _levelUpTo;

  PetProvider() {
    _loadPet();
  }

  Future<void> _loadPet() async {
    final prefs = await SharedPreferences.getInstance();
    final petJson = prefs.getString('pet_data');
    if (petJson != null) {
      try {
        _pet = Pet.fromJson(jsonDecode(petJson));
        _applyTimeDecay();
      } catch (e) {
        debugPrint('Error loading pet: $e');
        _pet = Pet();
      }
    }
    notifyListeners();
  }

  Future<void> _savePet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pet_data', jsonEncode(_pet.toJson()));
  }

  void _applyTimeDecay() {
    final currentTime = DateTime.now();
    final hoursSinceLastFed = currentTime.difference(_pet.lastFedAt).inHours;
    final hoursSinceLastPlayed = currentTime.difference(_pet.lastPlayedAt).inHours;

    final happinessDecay = (hoursSinceLastFed * Pet.happinessDecayPerHour).clamp(0, _pet.happiness);
    final energyDecay = (hoursSinceLastPlayed * Pet.energyDecayPerHour).clamp(0, _pet.energy);

    if (happinessDecay > 0 || energyDecay > 0) {
      _pet = _pet.copyWith(
        happiness: (_pet.happiness - happinessDecay).clamp(Pet.minStat, Pet.maxStat),
        energy: (_pet.energy - energyDecay).clamp(Pet.minStat, Pet.maxStat),
      );
      _pet = _pet.copyWith(currentMood: _pet.calculateMood());
      _savePet();
    }
  }

  /// Called when user completes a task
  void onTaskCompleted() {
    _addExperienceAndHappiness(Pet.xpTaskComplete, Pet.happinessTaskComplete);
    _lastInteraction = PetInteraction.taskReward;
    notifyListeners();
  }

  /// Called when user completes a habit
  void onHabitCompleted() {
    _addExperienceAndHappiness(Pet.xpHabitComplete, Pet.happinessHabitComplete);
    _lastInteraction = PetInteraction.habitReward;
    notifyListeners();
  }

  /// Called when user completes a Pomodoro session
  void onPomodoroCompleted() {
    _addExperienceAndHappiness(Pet.xpPomodoroComplete, Pet.happinessPomodoroComplete);
    _lastInteraction = PetInteraction.pomodoroReward;
    notifyListeners();
  }

  /// Feed the pet (restore energy)
  void feedPet() {
    final newEnergy = (_pet.energy + Pet.energyRest).clamp(Pet.minStat, Pet.maxStat);
    _pet = _pet.copyWith(
      energy: newEnergy,
      lastFedAt: DateTime.now(),
    );
    _pet = _pet.copyWith(currentMood: _pet.calculateMood());
    _lastInteraction = PetInteraction.fed;
    _savePet();
    notifyListeners();
  }

  /// Play with the pet (uses energy, increases happiness)
  void playWithPet() {
    if (_pet.energy < 20) {
      _lastInteraction = PetInteraction.tooTired;
      notifyListeners();
      return;
    }

    final newEnergy = (_pet.energy + Pet.energyPlay).clamp(Pet.minStat, Pet.maxStat);
    final newHappiness = (_pet.happiness + 15).clamp(Pet.minStat, Pet.maxStat);

    _pet = _pet.copyWith(
      energy: newEnergy,
      happiness: newHappiness,
      lastPlayedAt: DateTime.now(),
    );
    _pet = _pet.copyWith(currentMood: _pet.calculateMood());
    _lastInteraction = PetInteraction.played;
    _savePet();
    notifyListeners();
  }

  void _addExperienceAndHappiness(int xp, int happiness) {
    final newXp = _pet.experience + xp;
    final newLevel = (newXp ~/ Pet.xpPerLevel) + 1;
    final newHappiness = (_pet.happiness + happiness).clamp(Pet.minStat, Pet.maxStat);

    final leveledUp = newLevel > _pet.level;

    _pet = _pet.copyWith(
      experience: newXp,
      level: newLevel,
      happiness: newHappiness,
      coins: leveledUp ? _pet.coins + (newLevel * 10) : _pet.coins,
    );
    _pet = _pet.copyWith(currentMood: _pet.calculateMood());

    if (leveledUp) {
      _levelUpTo = newLevel;
      _lastInteraction = PetInteraction.levelUp;
    }

    _savePet();
  }

  void clearInteraction() {
    _lastInteraction = null;
    _levelUpTo = null;
    notifyListeners();
  }

  /// Rename the pet
  void renamePet(String newName) {
    _pet = _pet.copyWith(name: newName);
    _savePet();
    notifyListeners();
  }
}
