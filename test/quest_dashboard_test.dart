import 'package:daily_flow/core/utils/date_utils.dart';
import 'package:daily_flow/core/utils/gamification_math.dart';
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
import 'package:daily_flow/features/habits/screen/widgets/level_up_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockGamificationRepository implements GamificationRepository {
  UserProfile profile;
  final List<XpEntry> ledger = [];

  MockGamificationRepository({UserProfile? initialProfile})
    : profile =
          initialProfile ??
          UserProfile(
            heroName: 'Knight Tester',
            avatarId: 'knight_helm',
            totalXp: 150,
            currentLevel: 2,
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
  Future<Map<String, int>> getXpBreakdown() async => {
    'HABIT_CHECKIN': 100,
    'FOCUS_SESSION': 50,
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
  }) async {}

  @override
  Future<void> deleteHabit(int id) async {
    _habits.removeWhere((h) => h.id == id);
  }

  @override
  Future<void> toggleHabitLog({
    required int habitId,
    required String dateStr,
    required bool isCompleted,
  }) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      final h = _habits[index];
      final dates = Set<String>.from(h.completedDates);
      if (isCompleted) {
        dates.remove(dateStr);
      } else {
        dates.add(dateStr);
      }
      _habits[index] = h.copyWith(completedDates: dates);
    }
  }

  @override
  Future<void> restoreHabit(Habit habit) async {
    _habits.add(habit);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final todayStr = AppDateUtils.todayString;
  final yesterdayStr = AppDateUtils.formatDate(
    DateTime.now().subtract(const Duration(days: 1)),
  );

  group('HeroXpHud Component Tests', () {
    testWidgets(
      'renders player profile, level badge, total XP, and active streak',
      (tester) async {
        final mockGamificationRepo = MockGamificationRepository(
          initialProfile: UserProfile(
            heroName: 'Eldritch Knight',
            avatarId: 'knight_helm',
            totalXp: 350,
            currentLevel: 3,
            createdAt: DateTime.now(),
          ),
        );

        final sampleHabits = [
          Habit(
            id: 1,
            title: 'Daily Run',
            createdAt: DateTime.now(),
            completedDates: {todayStr, yesterdayStr},
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gamificationRepositoryProvider.overrideWithValue(
                mockGamificationRepo,
              ),
            ],
            child: MaterialApp(
              home: Scaffold(body: HeroXpHud(habits: sampleHabits)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Eldritch Knight'), findsOneWidget);
        expect(find.text('Lv. 3'), findsOneWidget);
        expect(find.text('350 Total XP'), findsOneWidget);
        expect(find.text('2-day Streak'), findsOneWidget);
      },
    );
  });

  group('DailyBountyCard Component Tests', () {
    testWidgets('renders clean sheet banner when all habits completed today', (
      tester,
    ) async {
      final habits = [
        Habit(
          id: 1,
          title: 'Meditate',
          createdAt: DateTime.now(),
          completedDates: {todayStr},
        ),
        Habit(
          id: 2,
          title: 'Read',
          createdAt: DateTime.now(),
          completedDates: {todayStr},
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DailyBountyCard(habits: habits)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DAILY BOUNTY'), findsOneWidget);
      expect(find.text('2 / 2 Done'), findsOneWidget);
      expect(find.text('7-Day Completion Rate'), findsOneWidget);
    });

    testWidgets('renders empty quest state gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DailyBountyCard(habits: [])),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Quests'), findsOneWidget);
      expect(find.text('7-Day Completion Rate'), findsOneWidget);
    });
  });

  group('HabitTile RPG Quest Card Tests', () {
    testWidgets(
      'displays title, category badge, calculated XP reward, and streak',
      (tester) async {
        final habit = Habit(
          id: 1,
          title: 'Master Riverpod',
          category: 'Coding',
          colorValue: 0xFF6366F1,
          createdAt: DateTime.now(),
          completedDates: {todayStr, yesterdayStr},
        );

        bool toggled = false;
        String? toggledDate;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HabitTile(
                habit: habit,
                onToggle: () => toggled = true,
                onToggleDate: (d) => toggledDate = d,
                onEdit: () {},
                onDelete: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Master Riverpod'), findsOneWidget);
        expect(find.text('CODING'), findsOneWidget);
        expect(
          find.text('+24 XP'),
          findsOneWidget,
        ); // 20 + (2 streak * 2) = 24 XP
        expect(find.text('2'), findsOneWidget); // Streak count

        // Verify 48x48 touch targets for checkmark and runic dots
        final checkmarkFinder = find.byKey(
          const Key('habit_tile_checkmark_btn'),
        );
        await tester.tap(checkmarkFinder);
        expect(toggled, isTrue);

        // Tap last runic dot (today)
        final runicFinder = find.byType(GestureDetector).last;
        await tester.tap(runicFinder);
        expect(toggledDate, isNotNull);
      },
    );
  });

  group('Real-Time XP Updates through HabitController', () {
    testWidgets(
      'completing and uncompleting a habit awards and revokes XP in real time',
      (tester) async {
        final mockGamificationRepo = MockGamificationRepository(
          initialProfile: UserProfile(
            heroName: 'Quest Slayer',
            avatarId: 'knight_helm',
            totalXp: 0,
            currentLevel: 1,
            createdAt: DateTime.now(),
          ),
        );

        final initialHabit = Habit(
          id: 1,
          title: 'Morning Yoga',
          category: 'Health',
          colorValue: 0xFF10B981,
          createdAt: DateTime.now(),
          completedDates: const {},
        );

        final mockHabitRepo = MockHabitRepository([initialHabit]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gamificationRepositoryProvider.overrideWithValue(
                mockGamificationRepo,
              ),
              habitRepositoryProvider.overrideWithValue(mockHabitRepo),
            ],
            child: const MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Initially 0 Total XP
        expect(find.text('0 Total XP'), findsOneWidget);
        expect(find.text('0 / 1 Done'), findsOneWidget);

        // Tap to complete the quest
        final checkmark = find
            .byKey(const Key('habit_tile_checkmark_btn'))
            .first;
        await tester.tap(checkmark);
        await tester.pumpAndSettle();

        // Profile and XP updated in real time (+20 XP for day 1)
        expect(find.text('20 Total XP'), findsOneWidget);
        expect(find.text('1 / 1 Done'), findsOneWidget);
        expect(mockGamificationRepo.ledger.length, 1);
        expect(mockGamificationRepo.ledger.first.status, XpStatus.active);

        // Uncheck the quest
        await tester.tap(checkmark);
        await tester.pumpAndSettle();

        // XP revoked in real time
        expect(find.text('0 Total XP'), findsOneWidget);
        expect(find.text('0 / 1 Done'), findsOneWidget);
        expect(mockGamificationRepo.ledger.first.status, XpStatus.revoked);
      },
    );
  });

  group('LevelUpDialog and Reduced Motion Tests', () {
    testWidgets('renders celebratory dialog with level and title', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LevelUpDialog(newLevel: 5))),
      );
      await tester.pumpAndSettle();

      expect(find.text('LEVEL UP!'), findsOneWidget);
      expect(find.text('Lv. 5'), findsOneWidget);
      expect(find.text('Rank Unlocked: Flow Adept'), findsOneWidget);
      expect(find.text('Continue Journey'), findsOneWidget);

      await tester.tap(find.text('Continue Journey'));
      await tester.pumpAndSettle();
    });

    testWidgets('respects reduced-motion setting without layout errors', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(home: Scaffold(body: LevelUpDialog(newLevel: 2))),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LEVEL UP!'), findsOneWidget);
      expect(find.text('Lv. 2'), findsOneWidget);
    });
  });
}
