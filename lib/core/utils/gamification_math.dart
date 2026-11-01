import 'dart:math';

/// Mathematical models, progression formulas, and XP reward economics for DailyFlow RPG.
class GamificationMath {
  static const int baseCheckinXp = 20;
  static const int maxStreakBonusXp = 15;
  static const int cleanSheetBonusXp = 50;
  static const int maxFocusSessionXpPerDay = 180;

  /// Calculates cumulative XP required to reach a specific [level].
  /// Formula: ceil(100 * (level - 1)^1.4)
  static int xpRequiredForLevel(int level) {
    if (level <= 1) return 0;
    return (100 * pow(level - 1, 1.4)).ceil();
  }

  /// Calculates the player's level from their [totalXp].
  /// Inverse formula: floor((totalXp / 100)^(1 / 1.4)) + 1
  static int calculateLevel(int totalXp) {
    if (totalXp <= 0) return 1;
    final level = (pow(totalXp / 100.0, 1.0 / 1.4)).floor() + 1;
    return max(1, level);
  }

  /// Calculates streak momentum bonus XP.
  /// Day 1 (streak <= 1) has 0 bonus.
  /// Streaks >= 2 earn streak * 2 bonus XP, capped at 15 XP.
  static int calculateStreakBonus(int streak) {
    if (streak <= 1) return 0;
    return min(maxStreakBonusXp, streak * 2);
  }

  /// Calculates total check-in XP for a habit given its current [streak].
  static int calculateCheckinXp(int streak) {
    return baseCheckinXp + calculateStreakBonus(streak);
  }

  /// Calculates XP awarded for a Pomodoro focus session of [durationMinutes].
  /// Awards 1 XP per minute, capped at 180 XP.
  static int calculateFocusSessionXp(int durationMinutes) {
    if (durationMinutes <= 0) return 0;
    return min(maxFocusSessionXpPerDay, durationMinutes);
  }

  /// Returns XP accumulated within the current level.
  static int xpInCurrentLevel(int totalXp) {
    final currentLevel = calculateLevel(totalXp);
    final levelStartXp = xpRequiredForLevel(currentLevel);
    return max(0, totalXp - levelStartXp);
  }

  /// Returns total XP required to advance from the current level to the next.
  static int xpNeededForNextLevel(int totalXp) {
    final currentLevel = calculateLevel(totalXp);
    final levelStartXp = xpRequiredForLevel(currentLevel);
    final nextLevelTargetXp = xpRequiredForLevel(currentLevel + 1);
    return max(1, nextLevelTargetXp - levelStartXp);
  }

  /// Returns progress ratio (0.0 to 1.0) towards the next level.
  static double progressRatioInCurrentLevel(int totalXp) {
    final needed = xpNeededForNextLevel(totalXp);
    if (needed <= 0) return 1.0;
    final current = xpInCurrentLevel(totalXp);
    return (current / needed).clamp(0.0, 1.0);
  }

  /// Returns thematic RPG title for a given [level].
  static String rankTitleForLevel(int level) {
    if (level < 3) return 'Novice Wanderer';
    if (level < 5) return 'Routine Apprentice';
    if (level < 10) return 'Flow Adept';
    if (level < 20) return 'Consistency Knight';
    if (level < 30) return 'Master of Will';
    if (level < 50) return 'Grand Flow Archon';
    return 'Legendary Champion';
  }
}
