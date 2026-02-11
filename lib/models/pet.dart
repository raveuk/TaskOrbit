/// Pet mood states for different animations/expressions
enum PetMood {
  happy,
  excited,
  neutral,
  tired,
  sad,
  sleeping,
}

extension PetMoodExtension on PetMood {
  String get emoji {
    switch (this) {
      case PetMood.happy:
        return '😊';
      case PetMood.excited:
        return '🤩';
      case PetMood.neutral:
        return '😐';
      case PetMood.tired:
        return '😴';
      case PetMood.sad:
        return '😢';
      case PetMood.sleeping:
        return '💤';
    }
  }

  String get label {
    switch (this) {
      case PetMood.happy:
        return 'Happy';
      case PetMood.excited:
        return 'Excited';
      case PetMood.neutral:
        return 'Neutral';
      case PetMood.tired:
        return 'Tired';
      case PetMood.sad:
        return 'Sad';
      case PetMood.sleeping:
        return 'Sleeping';
    }
  }
}

/// Represents the user's virtual pet companion "Orbit"
class Pet {
  final String name;
  final int happiness; // 0-100 scale
  final int energy; // 0-100 scale
  final int level;
  final int experience;
  final int coins;
  final PetMood currentMood;
  final DateTime lastFedAt;
  final DateTime lastPlayedAt;
  final DateTime createdAt;

  static const int maxStat = 100;
  static const int minStat = 0;
  static const int xpPerLevel = 100;

  // XP rewards
  static const int xpTaskComplete = 10;
  static const int xpHabitComplete = 15;
  static const int xpPomodoroComplete = 20;
  static const int xpStreakBonus = 5;

  // Happiness changes
  static const int happinessTaskComplete = 5;
  static const int happinessHabitComplete = 8;
  static const int happinessPomodoroComplete = 10;
  static const int happinessDecayPerHour = 2;

  // Energy changes
  static const int energyPlay = -10;
  static const int energyRest = 20;
  static const int energyDecayPerHour = 1;

  Pet({
    this.name = 'Orbit',
    this.happiness = 50,
    this.energy = 50,
    this.level = 1,
    this.experience = 0,
    this.coins = 0,
    this.currentMood = PetMood.neutral,
    DateTime? lastFedAt,
    DateTime? lastPlayedAt,
    DateTime? createdAt,
  })  : lastFedAt = lastFedAt ?? DateTime.now(),
        lastPlayedAt = lastPlayedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Pet copyWith({
    String? name,
    int? happiness,
    int? energy,
    int? level,
    int? experience,
    int? coins,
    PetMood? currentMood,
    DateTime? lastFedAt,
    DateTime? lastPlayedAt,
    DateTime? createdAt,
  }) {
    return Pet(
      name: name ?? this.name,
      happiness: happiness ?? this.happiness,
      energy: energy ?? this.energy,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      coins: coins ?? this.coins,
      currentMood: currentMood ?? this.currentMood,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Calculate level based on total experience
  int calculateLevel() {
    return (experience ~/ xpPerLevel) + 1;
  }

  /// Get experience progress to next level (0-100)
  int getLevelProgress() {
    return experience % xpPerLevel;
  }

  /// XP within current level
  int get xpInCurrentLevel => experience % xpPerLevel;

  /// Progress to next level as a fraction (0.0 - 1.0)
  double get xpProgress => xpInCurrentLevel / xpPerLevel;

  /// Determine mood based on happiness and energy
  PetMood calculateMood() {
    if (happiness < 20) return PetMood.sad;
    if (happiness < 40) return PetMood.tired;
    if (happiness > 80 && energy > 60) return PetMood.excited;
    if (happiness > 60) return PetMood.happy;
    return PetMood.neutral;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'happiness': happiness,
      'energy': energy,
      'level': level,
      'experience': experience,
      'coins': coins,
      'currentMood': currentMood.index,
      'lastFedAt': lastFedAt.millisecondsSinceEpoch,
      'lastPlayedAt': lastPlayedAt.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      name: json['name'] ?? 'Orbit',
      happiness: json['happiness'] ?? 50,
      energy: json['energy'] ?? 50,
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      coins: json['coins'] ?? 0,
      currentMood: PetMood.values[json['currentMood'] ?? 2],
      lastFedAt: DateTime.fromMillisecondsSinceEpoch(json['lastFedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(json['lastPlayedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}
