import 'package:daily_flow/core/utils/date_utils.dart';
import 'package:daily_flow/core/utils/gamification_math.dart';
import 'package:daily_flow/features/gamification/data/gamification_repository.dart';
import 'package:daily_flow/features/gamification/models/achievement.dart';
import 'package:daily_flow/features/gamification/models/user_profile.dart';
import 'package:daily_flow/features/gamification/models/xp_entry.dart';
import 'package:daily_flow/features/gamification/widgets/hero_avatar_badge.dart';
import 'package:daily_flow/features/habits/data/habit_repository.dart';
import 'package:daily_flow/features/habits/models/habit.dart';
import 'package:daily_flow/features/profile/screen/profile_screen.dart';
import 'package:daily_flow/features/profile/widgets/achievement_badge_tile.dart';
import 'package:daily_flow/features/profile/widgets/achievement_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockGamificationRepository implements GamificationRepository {
  UserProfile profile;
  final List<XpEntry> ledger = [];
  final Map<String, Achievement> achievements = {};

  MockGamificationRepository({UserProfile? initialProfile})
    : profile =
          initialProfile ??
          UserProfile(
            heroName: 'Valiant Paladin',
            avatarId: 'knight_helm',
            totalXp: 200,
            currentLevel: 2,
            createdAt: DateTime.now(),
          ) {
    for (final def in Achievement.definitions.values) {
      achievements[def.key] = Achievement(
        badgeKey: def.key,
        currentProgress: 0,
        isUnlocked: false,
      );
    }
  }

  @override
  Future<UserProfile> getUserProfile() async => profile;

  @override
  Future<void> updateUserProfile({String? heroName, String? avatarId}) async {
    profile = profile.copyWith(
      heroName: heroName ?? profile.heroName,
      avatarId: avatarId ?? profile.avatarId,
    );
  }

  @override
  Future<List<XpEntry>> getXpEntries({int limit = 50, int offset = 0}) async =>
      ledger;

  @override
  Future<int> getTotalActiveXp() async => ledger
      .where((e) => e.status == XpStatus.active)
      .fold<int>(0, (sum, e) => sum + e.xpAmount);

  @override
  Future<int> getCurrentLevel() async {
    final xp = await getTotalActiveXp();
    return GamificationMath.calculateLevel(xp);
  }

  @override
  Future<int> getTotalFocusMinutes() async => 0;

  @override
  Future<int> getTotalFocusSessions() async => 0;

  @override
  Future<int> awardHabitCheckin({
    required int habitId,
    required String dateStr,
    required int currentStreak,
  }) async => 20;

  @override
  Future<int> revokeHabitCheckin({
    required int habitId,
    required String dateStr,
  }) async => 0;

  @override
  Future<int> awardFocusSession({
    required int durationMinutes,
    int? habitId,
    required String dateStr,
  }) async => durationMinutes;

  @override
  Future<List<Achievement>> getAchievements() async =>
      achievements.values.toList();

  @override
  Future<void> updateAchievementProgress(String badgeKey, int progress) async {
    final def = Achievement.definitions[badgeKey];
    if (def == null) return;

    final existing =
        achievements[badgeKey] ??
        Achievement(badgeKey: badgeKey, currentProgress: 0);

    final isNowUnlocked = progress >= def.targetValue;
    final wasUnlocked = existing.isUnlocked;

    achievements[badgeKey] = existing.copyWith(
      currentProgress: progress,
      isUnlocked: wasUnlocked || isNowUnlocked,
      unlockedAt: wasUnlocked
          ? existing.unlockedAt
          : (isNowUnlocked ? DateTime.now() : null),
    );

    // If newly unlocked, award XP into ledger with deduplication check
    if (!wasUnlocked && isNowUnlocked) {
      final deterministicId = Achievement.deterministicIdFor(badgeKey);
      final alreadyAwarded = ledger.any(
        (e) =>
            e.sourceType == XpSourceType.achievement &&
            (e.sourceId == deterministicId ||
                e.sourceId == badgeKey.hashCode.abs()) &&
            e.status == XpStatus.active,
      );

      if (!alreadyAwarded) {
        ledger.add(
          XpEntry(
            id: ledger.length + 1,
            sourceType: XpSourceType.achievement,
            sourceId: deterministicId,
            eventDate: AppDateUtils.todayString,
            xpAmount: def.xpReward,
            status: XpStatus.active,
            createdAt: DateTime.now(),
          ),
        );
        final total = await getTotalActiveXp();
        final level = GamificationMath.calculateLevel(total);
        profile = profile.copyWith(totalXp: total, currentLevel: level);
      }
    }
  }

  @override
  Future<Map<String, int>> getXpBreakdown() async {
    return {
      XpSourceType.habitCheckin: 150,
      XpSourceType.focusSession: 50,
      XpSourceType.achievement: 100,
      XpSourceType.cleanSheet: 50,
    };
  }

  @override
  Future<bool> unlockAchievement(String badgeKey) async {
    final def = Achievement.definitions[badgeKey];
    if (def == null) return false;
    await updateAchievementProgress(badgeKey, def.targetValue);
    return true;
  }

  @override
  Future<List<Achievement>> evaluateAndSyncAchievements({
    required List<Habit> habits,
  }) async {
    final totalCheckins = habits.fold<int>(
      0,
      (sum, h) => sum + h.completedDates.length,
    );
    final bestStreak = habits.isEmpty
        ? 0
        : habits
              .map((h) => AppDateUtils.calculateBestStreak(h.completedDates))
              .fold<int>(0, (m, s) => s > m ? s : m);
    final totalHabits = habits.length;
    final distinctCategories = habits.map((h) => h.category).toSet().length;
    final isCleanSheetToday =
        habits.isNotEmpty && habits.every((h) => h.isCompletedToday);

    final evaluations = <String, int>{
      'first_spark': totalCheckins,
      'flame_keeper': bestStreak,
      'iron_will': bestStreak,
      'centurion': bestStreak,
      'guild_founder': totalHabits,
      'polymath': distinctCategories,
      'clean_sheet': isCleanSheetToday ? 1 : 0,
      'century_flow': totalCheckins,
    };

    for (final entry in evaluations.entries) {
      await updateAchievementProgress(entry.key, entry.value);
    }

    return await getAchievements();
  }

  @override
  Future<void> recalculateTotalXpAndLevel() async {}
}

class MockHabitRepository implements HabitRepository {
  final List<Habit> _habits = [];

  MockHabitRepository([List<Habit>? initial]) {
    if (initial != null) _habits.addAll(initial);
  }

  @override
  Future<List<Habit>> getHabits() async => List.unmodifiable(_habits);

  @override
  Future<Habit> createHabit({
    required String title,
    String category = 'General',
    int colorValue = 0xFF4F46E5,
  }) async {
    final habit = Habit(
      id: _habits.length + 1,
      title: title,
      createdAt: DateTime.now(),
      completedDates: const {},
    );
    _habits.add(habit);
    return habit;
  }

  @override
  Future<void> updateHabit({
    required int id,
    required String title,
    String? category,
    int? colorValue,
    bool? isArchived,
  }) async {}

  @override
  Future<void> deleteHabit(int id) async {}

  @override
  Future<void> toggleHabitLog({
    required int habitId,
    required String dateStr,
    required bool isCompleted,
  }) async {}

  @override
  Future<void> restoreHabit(Habit habit) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("Hero's Armory Profile Screen Tests", () {
    testWidgets(
      'renders hero name, level badge, rank title, and KPI stats accurately',
      (tester) async {
        final mockGamificationRepo = MockGamificationRepository(
          initialProfile: UserProfile(
            heroName: 'Arthur of Camelot',
            avatarId: 'knight_helm',
            totalXp: 350,
            currentLevel: 3,
            createdAt: DateTime.now(),
          ),
        );

        final habits = [
          Habit(
            id: 1,
            title: 'Train Swordsmanship',
            category: 'Fitness',
            colorValue: 0xFFF59E0B,
            createdAt: DateTime.now(),
            completedDates: {
              '2026-10-25',
              '2026-10-26',
              '2026-10-27',
              '2026-10-28',
              '2026-10-29',
              '2026-10-30',
              '2026-10-31',
            },
          ),
        ];

        final mockHabitRepo = MockHabitRepository(habits);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gamificationRepositoryProvider.overrideWithValue(
                mockGamificationRepo,
              ),
              habitRepositoryProvider.overrideWithValue(mockHabitRepo),
            ],
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Arthur of Camelot'), findsOneWidget);
        expect(find.text('Lv. 3'), findsOneWidget);
        expect(find.text('Routine Apprentice'), findsOneWidget);
        expect(find.text('350 Total XP'), findsOneWidget);
        expect(find.text('Active Habits'), findsOneWidget);
        expect(find.text('Total Check-ins'), findsOneWidget);
        expect(find.text('Best Streak'), findsOneWidget);
        expect(find.text('7 d'), findsOneWidget);
      },
    );

    testWidgets('HeroCustomizationDialog updates name and avatar crest', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockGamificationRepo = MockGamificationRepository(
        initialProfile: UserProfile(
          heroName: 'Novice Hero',
          avatarId: 'knight_helm',
          totalXp: 50,
          currentLevel: 1,
          createdAt: DateTime.now(),
        ),
      );

      final mockHabitRepo = MockHabitRepository([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamificationRepositoryProvider.overrideWithValue(
              mockGamificationRepo,
            ),
            habitRepositoryProvider.overrideWithValue(mockHabitRepo),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Novice Hero'), findsOneWidget);

      // Open customization dialog via edit button
      await tester.tap(find.byTooltip('Edit Hero Name'));
      await tester.pumpAndSettle();

      expect(find.text('Customize Hero'), findsOneWidget);
      expect(find.text('HERO NAME'), findsOneWidget);

      // Enter new hero name
      await tester.enterText(find.byType(TextField), 'Grand Champion');

      // Tap 'Arcane Sorcerer' crest
      await tester.tap(find.text('Arcane Sorcerer'));
      await tester.pumpAndSettle();

      // Tap Save Hero
      await tester.tap(find.text('Save Hero'));
      await tester.pumpAndSettle();

      // Profile updated
      expect(mockGamificationRepo.profile.heroName, 'Grand Champion');
      expect(mockGamificationRepo.profile.avatarId, 'arcane_mage');
      expect(find.text('Grand Champion'), findsOneWidget);
    });
  });

  group('Achievement Tree & Evaluation Engine Tests', () {
    testWidgets('evaluates achievements from habits and prevents duplicate XP', (
      tester,
    ) async {
      final mockGamificationRepo = MockGamificationRepository();

      // 3 habits across 3 categories with a 7-day streak
      final habits = [
        Habit(
          id: 1,
          title: 'Morning Yoga',
          category: 'Health',
          createdAt: DateTime.now(),
          completedDates: {
            '2026-10-25',
            '2026-10-26',
            '2026-10-27',
            '2026-10-28',
            '2026-10-29',
            '2026-10-30',
            '2026-10-31',
          },
        ),
        Habit(
          id: 2,
          title: 'Study Flutter',
          category: 'Study',
          createdAt: DateTime.now(),
          completedDates: {'2026-10-31'},
        ),
        Habit(
          id: 3,
          title: 'Write Code',
          category: 'Coding',
          createdAt: DateTime.now(),
          completedDates: const {},
        ),
      ];

      // 1. Initial evaluation
      await mockGamificationRepo.evaluateAndSyncAchievements(habits: habits);

      // 'first_spark' (+50 XP), 'flame_keeper' (+100 XP), 'guild_founder' (+50 XP) should unlock!
      expect(
        mockGamificationRepo.achievements['first_spark']!.isUnlocked,
        isTrue,
      );
      expect(
        mockGamificationRepo.achievements['flame_keeper']!.isUnlocked,
        isTrue,
      );
      expect(
        mockGamificationRepo.achievements['guild_founder']!.isUnlocked,
        isTrue,
      );

      // 'iron_will' (30-day streak) remains locked with progress 7
      expect(
        mockGamificationRepo.achievements['iron_will']!.isUnlocked,
        isFalse,
      );
      expect(
        mockGamificationRepo.achievements['iron_will']!.currentProgress,
        7,
      );

      final totalXpAfterFirstEval = await mockGamificationRepo
          .getTotalActiveXp();
      expect(totalXpAfterFirstEval, 200); // 50 + 100 + 50 = 200 XP

      // 2. Re-evaluating must be strictly idempotent (0 duplicate XP)
      await mockGamificationRepo.evaluateAndSyncAchievements(habits: habits);
      final totalXpAfterSecondEval = await mockGamificationRepo
          .getTotalActiveXp();
      expect(totalXpAfterSecondEval, 200);
      expect(mockGamificationRepo.ledger.length, 3);
    });

    testWidgets(
      'AchievementBadgeTile displays badge and opens AchievementDetailsDialog',
      (tester) async {
        final achievement = Achievement(
          badgeKey: 'flame_keeper',
          currentProgress: 7,
          isUnlocked: true,
          unlockedAt: DateTime(2026, 11, 1),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AchievementBadgeTile(achievement: achievement),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Flame Keeper'), findsOneWidget);
        expect(find.text('+100 XP'), findsOneWidget);

        // Tap tile to open details modal
        await tester.tap(find.text('Flame Keeper'));
        await tester.pumpAndSettle();

        expect(find.byType(AchievementDetailsDialog), findsOneWidget);
        expect(find.text("THE WARRIOR'S PATH"), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AchievementDetailsDialog),
            matching: find.text('Maintain any habit for a 7-day streak.'),
          ),
          findsOneWidget,
        );
        expect(find.text('COMPLETED (7 / 7)'), findsOneWidget);
        expect(find.text('Unlocked 2026-11-01'), findsOneWidget);

        // Dismiss dialog
        await tester.tap(find.text('Claim Honor'));
        await tester.pumpAndSettle();
        expect(find.byType(AchievementDetailsDialog), findsNothing);
      },
    );

    testWidgets('HeroAvatarBadge renders custom crests without layout errors', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                HeroAvatarBadge(avatarId: 'knight_helm', size: 48),
                HeroAvatarBadge(avatarId: 'arcane_mage', size: 48),
                HeroAvatarBadge(avatarId: 'valkyrie_wings', size: 48),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HeroAvatarBadge), findsNWidgets(3));
    });
  });
}
