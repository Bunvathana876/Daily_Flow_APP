import 'package:daily_flow/core/utils/gamification_math.dart';
import 'package:daily_flow/features/gamification/data/gamification_repository.dart';
import 'package:daily_flow/features/gamification/models/achievement.dart';
import 'package:daily_flow/features/gamification/models/hero_rank_tier.dart';
import 'package:daily_flow/features/gamification/models/user_profile.dart';
import 'package:daily_flow/features/gamification/models/xp_entry.dart';
import 'package:daily_flow/features/habits/data/habit_repository.dart';
import 'package:daily_flow/features/habits/models/habit.dart';
import 'package:daily_flow/features/profile/screen/profile_screen.dart';
import 'package:daily_flow/features/profile/widgets/achievement_details_dialog.dart';
import 'package:daily_flow/features/profile/widgets/hero_customization_dialog.dart';
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
            totalXp: 500,
            currentLevel: 4,
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
  Future<int> getTotalFocusMinutes() async => 45;

  @override
  Future<int> getTotalFocusSessions() async => 2;

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
    final current = achievements[badgeKey];
    final isNowUnlocked = progress >= def.targetValue;
    achievements[badgeKey] = Achievement(
      badgeKey: badgeKey,
      currentProgress: progress,
      isUnlocked: isNowUnlocked,
      unlockedAt: isNowUnlocked
          ? (current?.unlockedAt ?? DateTime.now())
          : null,
    );
  }

  @override
  Future<bool> unlockAchievement(String badgeKey) async {
    final def = Achievement.definitions[badgeKey];
    if (def == null) return false;
    final current = achievements[badgeKey];
    if (current?.isUnlocked == true) return false;

    achievements[badgeKey] = Achievement(
      badgeKey: badgeKey,
      currentProgress: def.targetValue,
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
    return true;
  }

  @override
  Future<List<Achievement>> evaluateAndSyncAchievements({
    required List<Habit> habits,
  }) async {
    return achievements.values.toList();
  }

  @override
  Future<Map<String, int>> getXpBreakdown() async => {
    'HABIT_CHECKIN': 300,
    'FOCUS_SESSION': 150,
    'ACHIEVEMENT': 50,
  };

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
  }) async => throw UnimplementedError();

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

  late MockGamificationRepository mockGamificationRepo;
  late MockHabitRepository mockHabitRepo;

  final sampleHabits = [
    Habit(
      id: 1,
      title: 'Dawn Blade Mastery',
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

  setUp(() {
    mockGamificationRepo = MockGamificationRepository(
      initialProfile: UserProfile(
        heroName: 'Solar Knight',
        avatarId: 'paladin_crest',
        totalXp: 650,
        currentLevel: 5,
        createdAt: DateTime.now(),
      ),
    );
    mockGamificationRepo.achievements['flame_keeper'] = Achievement(
      badgeKey: 'flame_keeper',
      currentProgress: 7,
      isUnlocked: true,
      unlockedAt: DateTime(2026, 11, 1),
    );
    mockGamificationRepo.achievements['iron_will'] = const Achievement(
      badgeKey: 'iron_will',
      currentProgress: 14,
      isUnlocked: false,
    );

    mockHabitRepo = MockHabitRepository(sampleHabits);
  });

  Widget createProfileApp({
    Size screenSize = const Size(800, 1000),
    bool disableAnimations = false,
  }) {
    return ProviderScope(
      overrides: [
        gamificationRepositoryProvider.overrideWithValue(mockGamificationRepo),
        habitRepositoryProvider.overrideWithValue(mockHabitRepo),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            disableAnimations: disableAnimations,
          ),
          child: const ProfileScreen(),
        ),
      ),
    );
  }

  group('Phase D Epic Hero Armory UI Tests', () {
    testWidgets('1. Hero Profile renders crest, name, rank, and tier frame', (
      tester,
    ) async {
      await tester.pumpWidget(createProfileApp());
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Solar Knight'), findsOneWidget);
      expect(find.text('Flow Adept'), findsOneWidget);
      expect(find.text('GOLD TIER'), findsOneWidget);
      expect(find.text('650 Total XP'), findsOneWidget);
      expect(find.text('Active Habits'), findsOneWidget);
      expect(find.text('Total Check-ins'), findsOneWidget);
      expect(find.text('Best Streak'), findsOneWidget);
      expect(find.text('7 d'), findsOneWidget);
    });

    testWidgets('2. Rank-Based Visual Frames map deterministically to levels', (
      tester,
    ) async {
      expect(HeroRankTier.fromLevel(1), HeroRankTier.bronze);
      expect(HeroRankTier.fromLevel(2), HeroRankTier.bronze);
      expect(HeroRankTier.fromLevel(3), HeroRankTier.silver);
      expect(HeroRankTier.fromLevel(4), HeroRankTier.silver);
      expect(HeroRankTier.fromLevel(5), HeroRankTier.gold);
      expect(HeroRankTier.fromLevel(7), HeroRankTier.gold);
      expect(HeroRankTier.fromLevel(8), HeroRankTier.platinum);
      expect(HeroRankTier.fromLevel(11), HeroRankTier.platinum);
      expect(HeroRankTier.fromLevel(12), HeroRankTier.diamond);
      expect(HeroRankTier.fromLevel(25), HeroRankTier.diamond);
    });

    testWidgets(
      '3. Avatar Customization Dialog shows preview and updates hero',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createProfileApp());
        await tester.pumpAndSettle();

        // Tap edit hero name
        await tester.tap(find.byTooltip('Edit Hero Name'));
        await tester.pumpAndSettle();

        expect(find.byType(HeroCustomizationDialog), findsOneWidget);
        expect(find.text('Customize Hero'), findsOneWidget);
        expect(find.text('HERO NAME'), findsOneWidget);
        expect(find.text('• Live Preview'), findsOneWidget);

        // Select 'Arcane Sorcerer'
        await tester.tap(find.text('Arcane Sorcerer'));
        await tester.pumpAndSettle();

        // Enter new hero name
        await tester.enterText(find.byType(TextField), 'Grand Magus');

        // Tap Save Hero
        await tester.tap(find.text('Save Hero'));
        await tester.pumpAndSettle();

        expect(find.byType(HeroCustomizationDialog), findsNothing);
        expect(find.text('Grand Magus'), findsOneWidget);
        expect(mockGamificationRepo.profile.heroName, 'Grand Magus');
        expect(mockGamificationRepo.profile.avatarId, 'arcane_mage');
      },
    );

    testWidgets('4. Locked and Unlocked Trophy States in Trophy Case', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createProfileApp());
      await tester.pumpAndSettle();

      // Unlocked badge 'Flame Keeper'
      expect(find.text('Flame Keeper'), findsOneWidget);
      expect(find.text('+100 XP'), findsOneWidget);
      expect(find.text('RARE'), findsWidgets);

      // Locked badge 'Iron Will'
      expect(find.text('Iron Will'), findsOneWidget);
      expect(find.text('+250 XP'), findsOneWidget);
      expect(find.text('14/30'), findsOneWidget);
      expect(find.text('EPIC'), findsWidgets);
    });

    testWidgets(
      '5. Achievement Details Dialog provides lore and requirements',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createProfileApp());
        await tester.pumpAndSettle();

        // Tap 'Flame Keeper' tile
        await tester.tap(find.text('Flame Keeper'));
        await tester.pumpAndSettle();

        expect(find.byType(AchievementDetailsDialog), findsOneWidget);
        expect(find.text("THE WARRIOR'S PATH"), findsOneWidget);
        expect(find.text('COMPLETED (7 / 7)'), findsOneWidget);
        expect(find.text('Unlocked 2026-11-01'), findsOneWidget);
        expect(find.text('+100 XP Reward'), findsOneWidget);

        // Dismiss
        await tester.tap(find.text('Claim Honor'));
        await tester.pumpAndSettle();
        expect(find.byType(AchievementDetailsDialog), findsNothing);
      },
    );

    testWidgets('6. Small screen responsiveness (320px screen width)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createProfileApp(screenSize: const Size(320, 640)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Solar Knight'), findsOneWidget);
    });

    testWidgets('7. Reduced motion mode disables animation without errors', (
      tester,
    ) async {
      await tester.pumpWidget(createProfileApp(disableAnimations: true));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
