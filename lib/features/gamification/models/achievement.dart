class AchievementDefinition {
  final int deterministicId;
  final String key;
  final String title;
  final String description;
  final String category;
  final int targetValue;
  final int xpReward;
  final String iconKey;

  const AchievementDefinition({
    required this.deterministicId,
    required this.key,
    required this.title,
    required this.description,
    required this.category,
    required this.targetValue,
    required this.xpReward,
    required this.iconKey,
  });
}

class Achievement {
  final int? id;
  final String badgeKey;
  final int currentProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    this.id,
    required this.badgeKey,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  AchievementDefinition get definition =>
      definitions[badgeKey] ??
      AchievementDefinition(
        deterministicId: deterministicIdFor(badgeKey),
        key: badgeKey,
        title: badgeKey,
        description: 'Mystery achievement',
        category: 'General',
        targetValue: 1,
        xpReward: 50,
        iconKey: 'star',
      );

  String get title => definition.title;
  String get description => definition.description;
  String get category => definition.category;
  int get targetValue => definition.targetValue;
  int get xpReward => definition.xpReward;
  String get iconKey => definition.iconKey;
  int get deterministicId => definition.deterministicId;

  /// Deterministic integer IDs for achievements to ensure stable, platform-independent
  /// persistence in the SQLite XP ledger.
  static const Map<String, int> deterministicIds = {
    'first_spark': 1001,
    'flame_keeper': 1002,
    'iron_will': 1003,
    'centurion': 1004,
    'single_spark': 1005,
    'deep_delver': 1006,
    'guild_founder': 1007,
    'polymath': 1008,
    'clean_sheet': 1009,
    'century_flow': 1010,
  };

  /// Returns the deterministic persistent integer ID for any [badgeKey].
  static int deterministicIdFor(String badgeKey) {
    if (deterministicIds.containsKey(badgeKey)) {
      return deterministicIds[badgeKey]!;
    }
    // FNV-1a 32-bit positive integer hash fallback for unknown/custom badges
    var hash = 0x811c9dc5;
    for (var i = 0; i < badgeKey.length; i++) {
      hash ^= badgeKey.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }

  double get progressRatio {
    if (targetValue <= 0) return 0.0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  Achievement copyWith({
    int? id,
    String? badgeKey,
    int? currentProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      badgeKey: badgeKey ?? this.badgeKey,
      currentProgress: currentProgress ?? this.currentProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'badge_key': badgeKey,
      'current_progress': currentProgress,
      'is_unlocked': isUnlocked ? 1 : 0,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as int?,
      badgeKey: map['badge_key'] as String,
      currentProgress: (map['current_progress'] as int?) ?? 0,
      isUnlocked: (map['is_unlocked'] as int?) == 1,
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.parse(map['unlocked_at'] as String)
          : null,
    );
  }

  static const Map<String, AchievementDefinition> definitions = {
    'first_spark': AchievementDefinition(
      deterministicId: 1001,
      key: 'first_spark',
      title: 'First Spark',
      description: 'Complete your first habit check-in.',
      category: 'Streaks',
      targetValue: 1,
      xpReward: 50,
      iconKey: 'local_fire_department',
    ),
    'flame_keeper': AchievementDefinition(
      deterministicId: 1002,
      key: 'flame_keeper',
      title: 'Flame Keeper',
      description: 'Maintain any habit for a 7-day streak.',
      category: 'Streaks',
      targetValue: 7,
      xpReward: 100,
      iconKey: 'military_tech',
    ),
    'iron_will': AchievementDefinition(
      deterministicId: 1003,
      key: 'iron_will',
      title: 'Iron Will',
      description: 'Maintain any habit for a 30-day streak.',
      category: 'Streaks',
      targetValue: 30,
      xpReward: 250,
      iconKey: 'shield',
    ),
    'centurion': AchievementDefinition(
      deterministicId: 1004,
      key: 'centurion',
      title: 'Centurion of Routine',
      description: 'Maintain any habit for 100 consecutive days.',
      category: 'Streaks',
      targetValue: 100,
      xpReward: 1000,
      iconKey: 'workspace_premium',
    ),
    'single_spark': AchievementDefinition(
      deterministicId: 1005,
      key: 'single_spark',
      title: 'Single Spark',
      description: 'Complete your first Pomodoro Focus session.',
      category: 'Focus',
      targetValue: 1,
      xpReward: 50,
      iconKey: 'hourglass_top',
    ),
    'deep_delver': AchievementDefinition(
      deterministicId: 1006,
      key: 'deep_delver',
      title: 'Deep Delver',
      description: 'Accumulate 5 hours (300 mins) of total Focus time.',
      category: 'Focus',
      targetValue: 300,
      xpReward: 150,
      iconKey: 'timer',
    ),
    'guild_founder': AchievementDefinition(
      deterministicId: 1007,
      key: 'guild_founder',
      title: 'Guild Founder',
      description: 'Create 3 active habits.',
      category: 'Habits',
      targetValue: 3,
      xpReward: 50,
      iconKey: 'group_work',
    ),
    'polymath': AchievementDefinition(
      deterministicId: 1008,
      key: 'polymath',
      title: 'Polymath',
      description: 'Create habits covering 5 different categories.',
      category: 'Habits',
      targetValue: 5,
      xpReward: 150,
      iconKey: 'category',
    ),
    'clean_sheet': AchievementDefinition(
      deterministicId: 1009,
      key: 'clean_sheet',
      title: 'Flawless Victory',
      description: 'Complete all active habits in a single day.',
      category: 'Mastery',
      targetValue: 1,
      xpReward: 100,
      iconKey: 'check_circle',
    ),
    'century_flow': AchievementDefinition(
      deterministicId: 1010,
      key: 'century_flow',
      title: 'Century Flow',
      description: 'Record 100 total habit check-ins all-time.',
      category: 'Mastery',
      targetValue: 100,
      xpReward: 500,
      iconKey: 'auto_stories',
    ),
  };
}
