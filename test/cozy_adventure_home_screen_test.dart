import 'package:daily_flow/core/theme/cozy_artwork.dart';
import 'package:daily_flow/core/utils/date_utils.dart';
import 'package:daily_flow/core/utils/gamification_math.dart';
import 'package:daily_flow/core/widgets/cozy_background.dart';
import 'package:daily_flow/core/widgets/hero_avatar_frame.dart';
import 'package:daily_flow/features/gamification/data/gamification_repository.dart';
import 'package:daily_flow/features/gamification/models/achievement.dart';
import 'package:daily_flow/features/gamification/models/user_profile.dart';
import 'package:daily_flow/features/gamification/models/xp_entry.dart';
import 'package:daily_flow/features/habits/data/habit_repository.dart';
import 'package:daily_flow/features/habits/models/habit.dart';
import 'package:daily_flow/features/habits/screen/home_screen.dart';
import 'package:daily_flow/features/habits/screen/widgets/daily_bounty_card.dart';
import 'package:daily_flow/features/habits/screen/widgets/habit_tile.dart';
import 'package:daily_flow/features/habits/screen/widgets/hero_xp_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockGamificationRepo implements GamificationRepository {
  UserProfile profile;
  final List<XpEntry> ledger = [];

  _MockGamificationRepo({UserProfile? initialProfile})
    : profile =
          initialProfile ??
          UserProfile(
            heroName: 'Bun Vathana',
            avatarId: 'hero_default',
            totalXp: 350,
            currentLevel: 3,
            createdAt: DateTime.now(),
          );

  @override
  Future<UserProfile> getUserProfile() async => profile;

  @override
  Future<void> updateUserProfile({String? heroName, String? avatarId}) async {
    profile = profile.copyWith(heroName: heroName, avatarId: avatarId);
  }

  @override
  Future<List<XpEntry>> getXpEntries({int limit = 50, int offset = 0}) async =>
      ledger;

  @override
  Future<int> getTotalActiveXp() async {
    return ledger
        .where((e) => e.status == XpStatus.active)
        .fold<int>(0, (sum, e) => sum + e.xpAmount);
  }

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
  Future<List<Achievement>> evaluateAndSyncAchievements({
    required List<Habit> habits,
  }) async => [];

  @override
  Future<int> awardHabitCheckin({
    required int habitId,
    required String dateStr,
    required int currentStreak,
  }) async {
    final xp = GamificationMath.calculateCheckinXp(currentStreak);
    ledger.add(
      XpEntry(
        id: ledger.length + 1,
        sourceType: XpSourceType.habitCheckin,
        sourceId: habitId,
        eventDate: dateStr,
        xpAmount: xp,
        status: XpStatus.active,
        createdAt: DateTime.now(),
      ),
    );
    final total = await getTotalActiveXp();
    final level = GamificationMath.calculateLevel(total);
    profile = profile.copyWith(totalXp: total, currentLevel: level);
    return xp;
  }

  @override
  Future<int> revokeHabitCheckin({
    required int habitId,
    required String dateStr,
  }) async {
    int revoked = 0;
    for (int i = 0; i < ledger.length; i++) {
      if (ledger[i].sourceType == XpSourceType.habitCheckin &&
          ledger[i].sourceId == habitId &&
          ledger[i].eventDate == dateStr &&
          ledger[i].status == XpStatus.active) {
        revoked = ledger[i].xpAmount;
        ledger[i] = ledger[i].copyWith(status: XpStatus.revoked);
      }
    }
    final total = await getTotalActiveXp();
    final level = GamificationMath.calculateLevel(total);
    profile = profile.copyWith(totalXp: total, currentLevel: level);
    return revoked;
  }

  @override
  Future<int> awardFocusSession({
    required int durationMinutes,
    int? habitId,
    required String dateStr,
  }) async => durationMinutes;

  @override
  Future<List<Achievement>> getAchievements() async => [];

  @override
  Future<void> updateAchievementProgress(String badgeKey, int progress) async {}

  @override
  Future<bool> unlockAchievement(String badgeKey) async => false;

  @override
  Future<Map<String, int>> getXpBreakdown() async => {};

  @override
  Future<void> recalculateTotalXpAndLevel() async {}
}

class _MockHabitRepo implements HabitRepository {
  final List<Habit> _habits = [];

  _MockHabitRepo([List<Habit>? initial]) {
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
      category: category,
      colorValue: colorValue,
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
  }) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habits[index] = _habits[index].copyWith(
        title: title,
        category: category ?? _habits[index].category,
        colorValue: colorValue ?? _habits[index].colorValue,
      );
    }
  }

  @override
  Future<void> deleteHabit(int id) async {
    _habits.removeWhere((h) => h.id == id);
  }

  Future<void> toggleHabitCompletion({
    required int id,
    required String dateStr,
  }) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final h = _habits[index];
      final newDates = Set<String>.from(h.completedDates);
      if (newDates.contains(dateStr)) {
        newDates.remove(dateStr);
      } else {
        newDates.add(dateStr);
      }
      _habits[index] = h.copyWith(completedDates: newDates);
    }
  }

  @override
  Future<void> restoreHabit(Habit habit) async {
    _habits.add(habit);
  }

  @override
  Future<void> toggleHabitLog({
    required int habitId,
    required String dateStr,
    required bool isCompleted,
  }) async {
    await toggleHabitCompletion(id: habitId, dateStr: dateStr);
  }

  Future<Habit?> getHabitById(int id) async {
    return _habits.firstWhere((h) => h.id == id);
  }
}

void main() {
  final todayStr = AppDateUtils.todayString;
  final yesterdayStr = AppDateUtils.formatDate(
    DateTime.now().subtract(const Duration(days: 1)),
  );

  Widget createTestWidget({
    required _MockGamificationRepo gamificationRepo,
    required _MockHabitRepo habitRepo,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return ProviderScope(
      overrides: [
        gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
        habitRepositoryProvider.overrideWithValue(habitRepo),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          );
        },
        home: const HomeScreen(),
      ),
    );
  }

  group('Phase 2 Cozy Adventure Home Screen Widget Tests', () {
    testWidgets(
      '1. Hero artwork rendering with golden laurel frame & village background',
      (tester) async {
        final mockGamification = _MockGamificationRepo();
        final mockHabit = _MockHabitRepo();

        await tester.pumpWidget(
          createTestWidget(
            gamificationRepo: mockGamification,
            habitRepo: mockHabit,
          ),
        );
        await tester.pumpAndSettle();

        // Check CozyBackgroundScaffold.village backdrop
        expect(find.byType(CozyBackgroundScaffold), findsOneWidget);

        // Check HeroAvatarFrame with canonical hero default artwork
        expect(find.byType(HeroAvatarFrame), findsOneWidget);
        final heroFrame = tester.widget<HeroAvatarFrame>(
          find.byType(HeroAvatarFrame),
        );
        expect(heroFrame.size, 56.0);
        expect(heroFrame.showFlourish, isTrue);
        expect(heroFrame.imageAsset, CozyArtwork.heroPortraitDefault);
      },
    );

    testWidgets(
      '2. Real XP, player level, rank title, and stats values displayed accurately',
      (tester) async {
        final profile = UserProfile(
          heroName: 'Bun Vathana',
          avatarId: 'hero_default',
          totalXp: 350,
          currentLevel: 3,
          createdAt: DateTime.now(),
        );
        final mockGamification = _MockGamificationRepo(initialProfile: profile);
        final mockHabit = _MockHabitRepo();

        await tester.pumpWidget(
          createTestWidget(
            gamificationRepo: mockGamification,
            habitRepo: mockHabit,
          ),
        );
        await tester.pumpAndSettle();

        // Player name and RPG rank
        expect(find.text('Bun Vathana'), findsOneWidget);
        expect(
          find.text(GamificationMath.rankTitleForLevel(3)),
          findsOneWidget,
        );

        // Real level badge Lv. 3
        expect(find.text('Lv. 3'), findsOneWidget);

        // Real total XP in KPI card
        expect(find.text('350 Total XP'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Quest completion and undo toggling updates XP and bounty counters in real time',
      (tester) async {
        final habit = Habit(
          id: 101,
          title: 'Daily Meditation',
          category: 'Health',
          colorValue: 0xFF10B981,
          createdAt: DateTime.now(),
          completedDates: const {},
        );
        final mockGamification = _MockGamificationRepo(
          initialProfile: UserProfile(
            heroName: 'Adventurer',
            avatarId: 'hero_default',
            totalXp: 0,
            currentLevel: 1,
            createdAt: DateTime.now(),
          ),
        );
        final mockHabit = _MockHabitRepo([habit]);

        await tester.pumpWidget(
          createTestWidget(
            gamificationRepo: mockGamification,
            habitRepo: mockHabit,
          ),
        );
        await tester.pumpAndSettle();

        // Initial bounty: 0 / 1 Done
        expect(find.text('0 / 1 Done'), findsOneWidget);
        expect(find.text('0 Total XP'), findsOneWidget);

        // Tap crest checkmark to complete quest
        final checkmark = find
            .byKey(const Key('habit_tile_checkmark_btn'))
            .first;
        await tester.tap(checkmark);
        await tester.pumpAndSettle();

        // Bounty & XP updated: 1 / 1 Done, +20 XP awarded
        expect(find.text('1 / 1 Done'), findsOneWidget);
        expect(find.text('20 Total XP'), findsOneWidget);

        // Tap again to uncomplete quest (undo)
        await tester.tap(checkmark);
        await tester.pumpAndSettle();

        // Reverted to 0 / 1 Done, 0 Total XP
        expect(find.text('0 / 1 Done'), findsOneWidget);
        expect(find.text('0 Total XP'), findsOneWidget);
      },
    );

    testWidgets(
      '4. One-habit and multiple-habit layouts render correctly with bounty stats',
      (tester) async {
        final habit1 = Habit(
          id: 1,
          title: 'Study Flutter Architecture',
          category: 'Coding',
          colorValue: 0xFF6366F1,
          createdAt: DateTime.now(),
          completedDates: {todayStr},
        );
        final habit2 = Habit(
          id: 2,
          title: 'Morning Yoga Flow',
          category: 'Health',
          colorValue: 0xFF10B981,
          createdAt: DateTime.now(),
          completedDates: {todayStr},
        );
        final habit3 = Habit(
          id: 3,
          title: 'Read Fantasy Novel',
          category: 'Study',
          colorValue: 0xFFF59E0B,
          createdAt: DateTime.now(),
          completedDates: const {},
        );

        final mockGamification = _MockGamificationRepo();
        final mockHabit = _MockHabitRepo([habit1, habit2, habit3]);

        await tester.pumpWidget(
          createTestWidget(
            gamificationRepo: mockGamification,
            habitRepo: mockHabit,
          ),
        );
        await tester.pumpAndSettle();

        // 3 quest cards rendered (allowing for scrollable viewport)
        expect(find.byType(HabitTile, skipOffstage: false), findsNWidgets(3));
        expect(find.text('Study Flutter Architecture'), findsOneWidget);
        expect(find.text('Morning Yoga Flow'), findsOneWidget);
        // Scroll down to see 3rd habit if necessary
        await tester.scrollUntilVisible(
          find.text('Read Fantasy Novel'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Read Fantasy Novel'), findsOneWidget);

        // Bounty indicates 2 / 3 Done
        expect(find.text('2 / 3 Done'), findsOneWidget);
        expect(find.text('1 left for bounty'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Empty quest state renders with Adventure Codex guidance and CTA',
      (tester) async {
        final mockGamification = _MockGamificationRepo();
        final mockHabit = _MockHabitRepo(); // No habits

        await tester.pumpWidget(
          createTestWidget(
            gamificationRepo: mockGamification,
            habitRepo: mockHabit,
          ),
        );
        await tester.pumpAndSettle();

        // No quest cards
        expect(find.byType(HabitTile), findsNothing);

        // Empty state message
        expect(find.text('No habits yet.'), findsOneWidget);
        expect(
          find.text('Forge a new quest below to embark on your adventure!'),
          findsOneWidget,
        );

        // Daily bounty shows No Quests / No quests milestone
        expect(find.text('No Quests'), findsOneWidget);
        expect(find.text('No quests'), findsOneWidget);
      },
    );

    testWidgets(
      '6. 320px screen width responsiveness without RenderFlex overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final sampleHabit = Habit(
          id: 1,
          title: 'Responsive Compact Hero Quest',
          category: 'Study',
          colorValue: 0xFF6366F1,
          createdAt: DateTime.now(),
          completedDates: {todayStr, yesterdayStr},
        );
        final mockGamification = _MockGamificationRepo();
        final mockHabit = _MockHabitRepo([sampleHabit]);

        await tester.pumpWidget(
          createTestWidget(
            gamificationRepo: mockGamification,
            habitRepo: mockHabit,
          ),
        );
        await tester.pumpAndSettle();

        // No layout exceptions or overflows on narrow 320px viewport
        expect(tester.takeException(), isNull);
        expect(find.byType(HeroXpHud), findsOneWidget);
        expect(find.byType(DailyBountyCard), findsOneWidget);
        expect(find.byType(HabitTile), findsOneWidget);
      },
    );

    testWidgets(
      '7. 2.0x Text Scaling renders safely without unbounded errors',
      (tester) async {
        final sampleHabit = Habit(
          id: 1,
          title: 'High Text Scale Quest',
          category: 'Fitness',
          colorValue: 0xFFEF4444,
          createdAt: DateTime.now(),
          completedDates: const {},
        );
        final mockGamification = _MockGamificationRepo();
        final mockHabit = _MockHabitRepo([sampleHabit]);

        await tester.pumpWidget(
          createTestWidget(
            gamificationRepo: mockGamification,
            habitRepo: mockHabit,
            textScaler: const TextScaler.linear(2.0),
          ),
        );
        await tester.pumpAndSettle();

        // Verified no crashing under 2.0x large accessibility text scaling
        expect(tester.takeException(), isNull);
        expect(find.byType(HeroXpHud), findsOneWidget);
        expect(find.byType(DailyBountyCard), findsOneWidget);
        expect(find.byType(HabitTile, skipOffstage: false), findsOneWidget);
      },
    );

    testWidgets('8. Reduced motion setting executes without animation errors', (
      tester,
    ) async {
      final sampleHabit = Habit(
        id: 1,
        title: 'Tranquil Mind Meditation',
        category: 'Health',
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
        completedDates: {todayStr},
      );
      final mockGamification = _MockGamificationRepo();
      final mockHabit = _MockHabitRepo([sampleHabit]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamificationRepositoryProvider.overrideWithValue(mockGamification),
            habitRepositoryProvider.overrideWithValue(mockHabit),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              );
            },
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final checkmark = find.byKey(const Key('habit_tile_checkmark_btn')).first;
      await tester.tap(checkmark);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
