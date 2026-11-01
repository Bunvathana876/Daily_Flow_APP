import '../../../core/utils/gamification_math.dart';

class UserProfile {
  final int? id;
  final String heroName;
  final String avatarId;
  final int totalXp;
  final int currentLevel;
  final DateTime createdAt;

  const UserProfile({
    this.id,
    required this.heroName,
    required this.avatarId,
    required this.totalXp,
    required this.currentLevel,
    required this.createdAt,
  });

  /// Thematic rank title computed from player level
  String get rankTitle => GamificationMath.rankTitleForLevel(currentLevel);

  /// XP earned within the current level
  int get xpInLevel => GamificationMath.xpInCurrentLevel(totalXp);

  /// Total XP needed to reach next level from current level base
  int get xpForNextLevel => GamificationMath.xpNeededForNextLevel(totalXp);

  /// Progress ratio (0.0 to 1.0) towards the next level
  double get levelProgress =>
      GamificationMath.progressRatioInCurrentLevel(totalXp);

  UserProfile copyWith({
    int? id,
    String? heroName,
    String? avatarId,
    int? totalXp,
    int? currentLevel,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      heroName: heroName ?? this.heroName,
      avatarId: avatarId ?? this.avatarId,
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'hero_name': heroName,
      'avatar_id': avatarId,
      'total_xp': totalXp,
      'current_level': currentLevel,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      heroName: (map['hero_name'] as String?) ?? 'DailyFlow Champion',
      avatarId: (map['avatar_id'] as String?) ?? 'knight_helm',
      totalXp: (map['total_xp'] as int?) ?? 0,
      currentLevel: (map['current_level'] as int?) ?? 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          heroName == other.heroName &&
          avatarId == other.avatarId &&
          totalXp == other.totalXp &&
          currentLevel == other.currentLevel;

  @override
  int get hashCode =>
      id.hashCode ^
      heroName.hashCode ^
      avatarId.hashCode ^
      totalXp.hashCode ^
      currentLevel.hashCode;
}
