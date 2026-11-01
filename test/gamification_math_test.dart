import 'package:daily_flow/core/utils/gamification_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GamificationMath.calculateLevel', () {
    test('0 or negative XP returns Level 1', () {
      expect(GamificationMath.calculateLevel(0), 1);
      expect(GamificationMath.calculateLevel(-50), 1);
    });

    test('XP below 100 remains Level 1', () {
      expect(GamificationMath.calculateLevel(1), 1);
      expect(GamificationMath.calculateLevel(50), 1);
      expect(GamificationMath.calculateLevel(99), 1);
    });

    test('100 XP unlocks Level 2', () {
      expect(GamificationMath.calculateLevel(100), 2);
      expect(GamificationMath.calculateLevel(150), 2);
      expect(GamificationMath.calculateLevel(263), 2);
    });

    test('Milestone XP values map accurately to calculated levels', () {
      // Level 3 requires 100 * 2^1.4 ≈ 263.9 -> 264 XP
      expect(GamificationMath.calculateLevel(264), 3);
      // Level 4 requires 100 * 3^1.4 ≈ 465.5 -> 466 XP
      expect(GamificationMath.calculateLevel(466), 4);
      // Level 5 requires 100 * 4^1.4 ≈ 696.4 -> 701 XP
      expect(GamificationMath.calculateLevel(701), 5);
      // Level 10 requires ~ 2298 XP
      expect(GamificationMath.calculateLevel(2298), 10);
    });

    test('Monotonicity check: Level never decreases as XP increases', () {
      int prevLevel = 1;
      for (int xp = 0; xp <= 10000; xp += 20) {
        final level = GamificationMath.calculateLevel(xp);
        expect(
          level >= prevLevel,
          isTrue,
          reason: 'Level decreased at XP: $xp',
        );
        prevLevel = level;
      }
    });
  });

  group('GamificationMath.xpRequiredForLevel', () {
    test('Level 1 requires 0 XP', () {
      expect(GamificationMath.xpRequiredForLevel(1), 0);
      expect(GamificationMath.xpRequiredForLevel(0), 0);
    });

    test('Level 2 requires 100 XP', () {
      expect(GamificationMath.xpRequiredForLevel(2), 100);
    });

    test(
      'Level calculation and required XP are mutually consistent inverses',
      () {
        for (int level = 1; level <= 30; level++) {
          final reqXp = GamificationMath.xpRequiredForLevel(level);
          final calculatedLevel = GamificationMath.calculateLevel(reqXp);
          expect(
            calculatedLevel,
            level,
            reason: 'Mismatch at level: $level with reqXp: $reqXp',
          );
        }
      },
    );
  });

  group('GamificationMath.calculateStreakBonus', () {
    test('0, 1 or negative streak awards 0 bonus XP', () {
      expect(GamificationMath.calculateStreakBonus(0), 0);
      expect(GamificationMath.calculateStreakBonus(1), 0);
      expect(GamificationMath.calculateStreakBonus(-5), 0);
    });

    test('Awards 2 XP per streak day starting at streak 2', () {
      expect(GamificationMath.calculateStreakBonus(2), 4);
      expect(GamificationMath.calculateStreakBonus(3), 6);
      expect(GamificationMath.calculateStreakBonus(5), 10);
      expect(GamificationMath.calculateStreakBonus(7), 14);
    });

    test('Caps at +15 XP for streaks >= 8 days', () {
      expect(GamificationMath.calculateStreakBonus(8), 15);
      expect(GamificationMath.calculateStreakBonus(9), 15);
      expect(GamificationMath.calculateStreakBonus(30), 15);
      expect(GamificationMath.calculateStreakBonus(100), 15);
    });
  });

  group('GamificationMath.calculateCheckinXp', () {
    test('Awards 20 base XP for streak 0', () {
      expect(GamificationMath.calculateCheckinXp(0), 20);
    });

    test('Awards base 20 + streak bonus', () {
      expect(GamificationMath.calculateCheckinXp(3), 26);
      expect(GamificationMath.calculateCheckinXp(7), 34);
      expect(GamificationMath.calculateCheckinXp(8), 35);
      expect(GamificationMath.calculateCheckinXp(100), 35);
    });
  });

  group('GamificationMath.calculateFocusSessionXp', () {
    test('Awards 1 XP per minute', () {
      expect(GamificationMath.calculateFocusSessionXp(15), 15);
      expect(GamificationMath.calculateFocusSessionXp(25), 25);
      expect(GamificationMath.calculateFocusSessionXp(60), 60);
    });

    test('Caps at 180 XP max', () {
      expect(GamificationMath.calculateFocusSessionXp(180), 180);
      expect(GamificationMath.calculateFocusSessionXp(240), 180);
    });

    test('Negative or 0 minutes returns 0 XP', () {
      expect(GamificationMath.calculateFocusSessionXp(0), 0);
      expect(GamificationMath.calculateFocusSessionXp(-10), 0);
    });
  });

  group('GamificationMath Level Progress Helpers', () {
    test('Computes XP in current level and needed for next level', () {
      // Level 1: 0 to 100 XP
      expect(GamificationMath.xpInCurrentLevel(40), 40);
      expect(GamificationMath.xpNeededForNextLevel(40), 100);
      expect(
        GamificationMath.progressRatioInCurrentLevel(40),
        closeTo(0.4, 0.001),
      );

      // Level 2: 100 to 264 XP (164 needed)
      expect(GamificationMath.xpInCurrentLevel(100), 0);
      expect(GamificationMath.xpInCurrentLevel(182), 82);
      expect(
        GamificationMath.progressRatioInCurrentLevel(182),
        closeTo(0.5, 0.01),
      );
    });
  });

  group('GamificationMath.rankTitleForLevel', () {
    test('Returns correct thematic title for level tiers', () {
      expect(GamificationMath.rankTitleForLevel(1), 'Novice Wanderer');
      expect(GamificationMath.rankTitleForLevel(2), 'Novice Wanderer');
      expect(GamificationMath.rankTitleForLevel(3), 'Routine Apprentice');
      expect(GamificationMath.rankTitleForLevel(4), 'Routine Apprentice');
      expect(GamificationMath.rankTitleForLevel(5), 'Flow Adept');
      expect(GamificationMath.rankTitleForLevel(9), 'Flow Adept');
      expect(GamificationMath.rankTitleForLevel(10), 'Consistency Knight');
      expect(GamificationMath.rankTitleForLevel(19), 'Consistency Knight');
      expect(GamificationMath.rankTitleForLevel(20), 'Master of Will');
      expect(GamificationMath.rankTitleForLevel(30), 'Grand Flow Archon');
      expect(GamificationMath.rankTitleForLevel(50), 'Legendary Champion');
      expect(GamificationMath.rankTitleForLevel(100), 'Legendary Champion');
    });
  });
}
