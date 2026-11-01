import 'package:daily_flow/features/analytics/screen/stats_screen.dart';
import 'package:daily_flow/features/gamification/data/gamification_repository.dart';
import 'package:daily_flow/features/gamification/models/achievement.dart';
import 'package:daily_flow/features/gamification/models/user_profile.dart';
import 'package:daily_flow/features/gamification/models/xp_entry.dart';
import 'package:daily_flow/features/habits/data/habit_repository.dart';
import 'package:daily_flow/features/habits/models/habit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockGamificationRepository implements GamificationRepository {
  UserProfile profile;
  List<Achievement> achievements;
  final List<XpEntry> ledger = [];

  MockGamificationRepository({
    UserProfile? initialProfile,
    List<Achievement>? initialAchievements,
  }) : profile =
           initialProfile ??
           UserProfile(
             heroName: 'Knight Commander',
             avatarId: 'paladin_crest',
             totalXp: 750,
             currentLevel: 5,
             createdAt: DateTime.now(),
           ),
       achievements =
           initialAchievements ??
           [
             const Achievement(
               badgeKey: 'first_spark',
               currentProgress: 1,
               isUnlocked: true,
             ),
             const Achievement(
               badgeKey: 'flame_keeper',
               currentProgress: 7,
               isUnlocked: true,
             ),
             const Achievement(
               badgeKey: 'single_spark',
               currentProgress: 1,
               isUnlocked: true,
             ),
             const Achievement(
               badgeKey: 'iron_will',
               currentProgress: 12,
               isUnlocked: false,
             ),
           ];

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
  Future<int> getTotalActiveXp() async => profile.totalXp;

  @override
  Future<int> getCurrentLevel() async => profile.currentLevel;

  @override
  Future<int> getTotalFocusMinutes() async => 75;

  @override
  Future<int> getTotalFocusSessions() async => 3;

  @override
  Future<int> awardHabitCheckin({
    required int habitId,
    required String dateStr,
    required int currentStreak,
  }) async => 15;

  @override
  Future<int> revokeHabitCheckin({
    required int habitId,
    required String dateStr,
  }) async => -15;

  @override
  Future<int> awardFocusSession({
    required int durationMinutes,
    int? habitId,
    required String dateStr,
  }) async => durationMinutes;

  @override
  Future<List<Achievement>> getAchievements() async => achievements;

  @override
  Future<void> updateAchievementProgress(String badgeKey, int progress) async {}

  @override
  Future<bool> unlockAchievement(String badgeKey) async => false;

  @override
  Future<List<Achievement>> evaluateAndSyncAchievements({
    required List<Habit> habits,
  }) async => achievements;

  @override
  Future<Map<String, int>> getXpBreakdown() async => {
    XpSourceType.habitCheckin: 450,
    XpSourceType.focusSession: 75,
    XpSourceType.achievement: 225,
  };

  @override
  Future<void> recalculateTotalXpAndLevel() async {}
}

class MockHabitRepository implements HabitRepository {
  final List<Habit> habits;
  MockHabitRepository(this.habits);

  @override
  Future<List<Habit>> getHabits() async => habits;

  @override
  Future<Habit> createHabit({
    required String title,
    String category = 'General',
    int colorValue = 0xFF4F46E5,
  }) async => habits.first;

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

  group('Hall of Records (StatsScreen) Tests', () {
    testWidgets(
      'renders hero productivity overview and 4 KPI cards accurately',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockGamificationRepo = MockGamificationRepository();
        final habits = [
          Habit(
            id: 1,
            title: 'Daily Run',
            category: 'Health',
            createdAt: DateTime.now(),
            completedDates: {
              '2026-10-25',
              '2026-10-26',
              '2026-10-27',
              '2026-10-28',
              '2026-10-29',
            },
          ),
          Habit(
            id: 2,
            title: 'Study Runes',
            category: 'Wisdom',
            createdAt: DateTime.now(),
            completedDates: {'2026-10-28', '2026-10-29'},
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
            child: const MaterialApp(home: StatsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // App bar & titles
        expect(find.text('Hall of Records'), findsOneWidget);
        expect(find.text('Insights & Analytics'), findsOneWidget);

        // Hero character card
        expect(find.text('Knight Commander'), findsOneWidget);
        expect(find.text('Flow Adept'), findsOneWidget);
        expect(find.text('750 Total XP'), findsOneWidget);
        expect(find.text('3 / 4 Badges'), findsOneWidget);

        // 4 KPI cards
        expect(find.text('Total Check-ins'), findsOneWidget);
        expect(find.text('7'), findsOneWidget); // 5 + 2 check-ins
        expect(find.text('Best Streak'), findsOneWidget);
        expect(find.text('Active Habits'), findsOneWidget);
        expect(find.text('2'), findsOneWidget); // 2 active habits
        expect(find.text('Focus Trials'), findsOneWidget);
        expect(find.text('75 m'), findsOneWidget); // 75 minutes focus
      },
    );

    testWidgets(
      'renders 12-Week Consistency, Weekday Chart, and XP Breakdown',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockGamificationRepo = MockGamificationRepository();
        final mockHabitRepo = MockHabitRepository([]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gamificationRepositoryProvider.overrideWithValue(
                mockGamificationRepo,
              ),
              habitRepositoryProvider.overrideWithValue(mockHabitRepo),
            ],
            child: const MaterialApp(home: StatsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Heatmap
        expect(find.text('12-Week Consistency'), findsOneWidget);
        expect(find.text('Last 84 Days'), findsOneWidget);
        expect(find.text('Less'), findsOneWidget);
        expect(find.text('More'), findsOneWidget);

        // Weekday performance
        expect(find.text('Weekday Performance'), findsOneWidget);
        expect(find.text('Average Rate'), findsOneWidget);

        // XP Progression
        expect(find.text('XP Progression'), findsOneWidget);
        expect(find.text('REWARD SOURCES'), findsOneWidget);
        expect(find.text('Habit Quests'), findsOneWidget);
        expect(find.text('+450 XP'), findsOneWidget);
        expect(find.text('Focus Chamber'), findsOneWidget);
        expect(find.text('+75 XP'), findsOneWidget);
        expect(find.text('Achievements'), findsOneWidget);
        expect(find.text('+225 XP'), findsOneWidget);

        // Milestones overview
        expect(find.text('Achievement Milestones'), findsOneWidget);
        expect(find.text('First Spark'), findsOneWidget);
        expect(find.text('Flame Keeper'), findsOneWidget);
        expect(find.text('Single Spark'), findsOneWidget);
      },
    );
  });
}
