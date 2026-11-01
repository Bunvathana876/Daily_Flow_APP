import 'package:daily_flow/core/widgets/rpg_celebration_banner.dart';
import 'package:daily_flow/features/analytics/screen/stats_screen.dart';
import 'package:daily_flow/features/gamification/data/gamification_repository.dart';
import 'package:daily_flow/features/gamification/models/achievement.dart';
import 'package:daily_flow/features/gamification/models/user_profile.dart';
import 'package:daily_flow/features/gamification/models/xp_entry.dart';
import 'package:daily_flow/features/habits/data/habit_repository.dart';
import 'package:daily_flow/features/habits/models/habit.dart';
import 'package:daily_flow/features/habits/screen/widgets/level_up_dialog.dart';
import 'package:daily_flow/features/navigation/screen/main_shell.dart';
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

  final testHabits = [
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

  Widget buildStatsScreen({
    MockGamificationRepository? gamificationRepo,
    MockHabitRepository? habitRepo,
  }) {
    return ProviderScope(
      overrides: [
        gamificationRepositoryProvider.overrideWithValue(
          gamificationRepo ?? MockGamificationRepository(),
        ),
        habitRepositoryProvider.overrideWithValue(
          habitRepo ?? MockHabitRepository(testHabits),
        ),
      ],
      child: const MaterialApp(home: StatsScreen()),
    );
  }

  Widget buildMainShell({
    MockGamificationRepository? gamificationRepo,
    MockHabitRepository? habitRepo,
  }) {
    return ProviderScope(
      overrides: [
        gamificationRepositoryProvider.overrideWithValue(
          gamificationRepo ?? MockGamificationRepository(),
        ),
        habitRepositoryProvider.overrideWithValue(
          habitRepo ?? MockHabitRepository(testHabits),
        ),
      ],
      child: const MaterialApp(home: MainShell()),
    );
  }

  group('Phase E: Hall of Records UI Tests', () {
    testWidgets(
      '1. Stats dashboard renders hero summary, level badge, and 4 KPI cards',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildStatsScreen());
        await tester.pumpAndSettle();

        // Screen title & subtitle
        expect(find.text('Hall of Records'), findsOneWidget);
        expect(find.text('Insights & Analytics'), findsOneWidget);

        // Hero card info
        expect(find.text('Knight Commander'), findsOneWidget);
        expect(find.text('Flow Adept'), findsOneWidget);
        expect(find.text('750 Total XP'), findsOneWidget);
        expect(find.text('3 / 4 Badges'), findsOneWidget);

        // 4 KPI Stat Cards
        expect(find.text('Total Check-ins'), findsOneWidget);
        expect(find.text('Best Streak'), findsOneWidget);
        expect(find.text('Active Habits'), findsOneWidget);
        expect(find.text('Focus Trials'), findsOneWidget);
        expect(find.text('3 sessions'), findsOneWidget);
      },
    );

    testWidgets(
      '2. 12-week consistency rune heatmap renders legend and cells with tooltips',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildStatsScreen());
        await tester.pumpAndSettle();

        // Heatmap header & legend
        expect(find.text('12-Week Consistency'), findsOneWidget);
        expect(find.text('Last 84 Days'), findsOneWidget);
        expect(find.text('Less'), findsOneWidget);
        expect(find.text('More'), findsOneWidget);

        // Verify Tooltip widgets exist for heatmap cells
        final tooltips = find.byType(Tooltip);
        expect(tooltips, findsWidgets);
      },
    );

    testWidgets(
      '3. Weekday performance bar chart renders day labels and top-day crown',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildStatsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Weekday Performance'), findsOneWidget);
        expect(find.text('Average Rate'), findsOneWidget);

        // Weekday labels
        expect(find.text('M'), findsOneWidget);
        expect(find.text('T'), findsNWidgets(2));
        expect(find.text('W'), findsOneWidget);
        expect(find.text('F'), findsOneWidget);
        expect(find.text('S'), findsNWidgets(2));

        // Top day crown icon
        expect(find.byIcon(Icons.workspace_premium_rounded), findsWidgets);
      },
    );

    testWidgets(
      '4. XP progression breakdown and achievement milestones render properly',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildStatsScreen());
        await tester.pumpAndSettle();

        expect(find.text('XP Progression'), findsOneWidget);
        expect(find.text('REWARD SOURCES'), findsOneWidget);
        expect(find.text('Habit Quests'), findsOneWidget);
        expect(find.text('+450 XP'), findsOneWidget);
        expect(find.text('Focus Chamber'), findsOneWidget);
        expect(find.text('+75 XP'), findsOneWidget);
        expect(find.text('Achievements'), findsOneWidget);
        expect(find.text('+225 XP'), findsOneWidget);

        expect(find.text('Achievement Milestones'), findsOneWidget);
        expect(find.text('3 / 4'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Enchanted navigation dock in MainShell navigates tabs and preserves state',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildMainShell());
        await tester.pumpAndSettle();

        // Destinations exist
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Insights'), findsOneWidget);
        expect(find.text('Focus'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);

        // Default screen is Today
        expect(find.text("Today's Quests"), findsOneWidget);

        // Switch to Insights
        await tester.tap(find.text('Insights'));
        await tester.pumpAndSettle();
        expect(find.text('Hall of Records'), findsOneWidget);

        // Switch to Focus
        await tester.tap(find.text('Focus'));
        await tester.pumpAndSettle();
        expect(find.text('Focus Trial'), findsOneWidget);

        // Switch back to Today - state is preserved
        await tester.tap(find.text('Today'));
        await tester.pumpAndSettle();
        expect(find.text("Today's Quests"), findsOneWidget);
      },
    );

    testWidgets(
      '6. Small screen responsiveness (320px width) renders without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildStatsScreen());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Hall of Records'), findsOneWidget);
        expect(find.text('Total Check-ins'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Reduced motion setting runs smoothly without animation lag',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: buildStatsScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hall of Records'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '8. Celebration banner deduplication and LevelUpDialog dismissal',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Rapid double triggers to test deduplication
                        RpgCelebrationBanner.showMilestone(
                          context,
                          title: 'Milestone 1',
                          subtitle: 'First trigger',
                        );
                        RpgCelebrationBanner.showMilestone(
                          context,
                          title: 'Milestone 2',
                          subtitle: 'Second trigger',
                        );
                      },
                      child: const Text('Trigger Celebrations'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => const LevelUpDialog(newLevel: 5),
                        );
                      },
                      child: const Text('Show Level Up'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Tap trigger celebrations
        await tester.tap(find.text('Trigger Celebrations'));
        await tester.pumpAndSettle();

        // Only the second toast should be actively shown (deduplication / clear previous)
        expect(find.text('Milestone 2'), findsOneWidget);
        expect(find.text('Milestone 1'), findsNothing);

        // Open Level Up Dialog
        await tester.tap(find.text('Show Level Up'));
        await tester.pumpAndSettle();

        expect(find.text('LEVEL UP!'), findsOneWidget);
        expect(find.text('Rank Unlocked: Flow Adept'), findsOneWidget);

        // Tap Continue Journey to dismiss
        await tester.tap(find.text('Continue Journey'));
        await tester.pumpAndSettle();

        expect(find.text('LEVEL UP!'), findsNothing);
      },
    );
  });
}
