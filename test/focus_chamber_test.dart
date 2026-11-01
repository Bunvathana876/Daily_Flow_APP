import 'package:daily_flow/core/utils/date_utils.dart';
import 'package:daily_flow/core/utils/gamification_math.dart';
import 'package:daily_flow/features/focus/controllers/focus_timer_controller.dart';
import 'package:daily_flow/features/focus/screen/focus_screen.dart';
import 'package:daily_flow/features/focus/widgets/arcane_timer_ring.dart';
import 'package:daily_flow/features/focus/widgets/focus_victory_dialog.dart';
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
  final List<XpEntry> ledger = [];

  MockGamificationRepository({UserProfile? initialProfile})
    : profile =
          initialProfile ??
          UserProfile(
            heroName: 'Focus Champion',
            avatarId: 'knight_helm',
            totalXp: 100,
            currentLevel: 2,
            createdAt: DateTime.now(),
          );

  @override
  Future<UserProfile> getUserProfile() async => profile;

  @override
  Future<void> updateUserProfile({String? heroName, String? avatarId}) async {}

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
  Future<List<Achievement>> evaluateAndSyncAchievements({
    required List<Habit> habits,
  }) async => [];

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
  }) async {
    final xp = GamificationMath.calculateFocusSessionXp(durationMinutes);
    if (xp <= 0) return 0;

    final todayActiveFocusXp = ledger
        .where(
          (e) =>
              e.sourceType == XpSourceType.focusSession &&
              e.eventDate == dateStr &&
              e.status == XpStatus.active,
        )
        .fold<int>(0, (sum, e) => sum + e.xpAmount);

    final remainingAllowed =
        (GamificationMath.maxFocusSessionXpPerDay - todayActiveFocusXp).clamp(
          0,
          GamificationMath.maxFocusSessionXpPerDay,
        );

    final grantXp = xp > remainingAllowed ? remainingAllowed : xp;
    if (grantXp > 0) {
      ledger.add(
        XpEntry(
          id: ledger.length + 1,
          sourceType: XpSourceType.focusSession,
          sourceId: habitId,
          eventDate: dateStr,
          xpAmount: grantXp,
          status: XpStatus.active,
          createdAt: DateTime.now(),
        ),
      );
    }

    final total = await getTotalActiveXp();
    final level = GamificationMath.calculateLevel(total);
    profile = profile.copyWith(totalXp: total, currentLevel: level);
    return grantXp;
  }

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
  Future<void> restoreHabit(Habit habit) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime mockClockTime;

  setUp(() {
    mockClockTime = DateTime(2026, 11, 1, 10, 0, 0);
  });

  group('FocusTimerController Wall-Clock Engine Tests', () {
    test(
      'start, pause, resume, and reset calculate wall-clock deadlines accurately',
      () {
        final container = ProviderContainer(
          overrides: [
            focusClockProvider.overrideWithValue(() => mockClockTime),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(
          focusTimerControllerProvider.notifier,
        );

        // Initial state: 25 minutes
        var state = container.read(focusTimerControllerProvider);
        expect(state.status, FocusTimerStatus.initial);
        expect(state.remainingDuration.inMinutes, 25);
        expect(state.targetEndTime, isNull);

        // Start timer at 10:00:00 -> targetEndTime is 10:25:00
        controller.startTimer();
        state = container.read(focusTimerControllerProvider);
        expect(state.status, FocusTimerStatus.running);
        expect(state.targetEndTime, DateTime(2026, 11, 1, 10, 25, 0));

        // Advance mock time by 10 minutes to 10:10:00 -> Pause timer
        mockClockTime = mockClockTime.add(const Duration(minutes: 10));
        controller.pauseTimer();
        state = container.read(focusTimerControllerProvider);
        expect(state.status, FocusTimerStatus.paused);
        expect(state.remainingDuration.inMinutes, 15);
        expect(state.targetEndTime, isNull);

        // Idle 5 minutes while paused to 10:15:00 -> Remaining must stay frozen at 15m
        mockClockTime = mockClockTime.add(const Duration(minutes: 5));
        expect(
          container
              .read(focusTimerControllerProvider)
              .remainingDuration
              .inMinutes,
          15,
        );

        // Resume timer at 10:15:00 -> targetEndTime is now 10:30:00 (10:15 + 15m)
        controller.resumeTimer();
        state = container.read(focusTimerControllerProvider);
        expect(state.status, FocusTimerStatus.running);
        expect(state.targetEndTime, DateTime(2026, 11, 1, 10, 30, 0));

        // Reset timer -> sets status to initial, restores 25m, clears deadline
        controller.resetTimer();
        state = container.read(focusTimerControllerProvider);
        expect(state.status, FocusTimerStatus.initial);
        expect(state.remainingDuration.inMinutes, 25);
        expect(state.targetEndTime, isNull);
      },
    );

    test(
      'simulates app backgrounding and foregrounding with deadline completion',
      () async {
        final mockGamificationRepo = MockGamificationRepository();
        final container = ProviderContainer(
          overrides: [
            focusClockProvider.overrideWithValue(() => mockClockTime),
            gamificationRepositoryProvider.overrideWithValue(
              mockGamificationRepo,
            ),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(
          focusTimerControllerProvider.notifier,
        );
        controller.setPresetMinutes(15);
        controller.startTimer();

        // App is backgrounded at 10:00:00, user returns at 10:16:00 (16 minutes later)
        mockClockTime = mockClockTime.add(const Duration(minutes: 16));
        await controller.handleAppLifecycleResumed();

        final state = container.read(focusTimerControllerProvider);
        expect(state.status, FocusTimerStatus.completed);
        expect(state.remainingDuration, Duration.zero);
        expect(state.lastAwardedXp, 15);
        expect(state.isVictoryModalPending, isTrue);

        // Ledger has exactly 1 entry for 15 XP
        expect(mockGamificationRepo.ledger.length, 1);
        expect(mockGamificationRepo.ledger.first.xpAmount, 15);

        // Subsequent resume calls do not duplicate completion
        await controller.handleAppLifecycleResumed();
        expect(mockGamificationRepo.ledger.length, 1);
      },
    );

    test('break modes grant 0 XP upon session completion', () async {
      final mockGamificationRepo = MockGamificationRepository();
      final container = ProviderContainer(
        overrides: [
          focusClockProvider.overrideWithValue(() => mockClockTime),
          gamificationRepositoryProvider.overrideWithValue(
            mockGamificationRepo,
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(focusTimerControllerProvider.notifier);
      controller.setMode(FocusMode.shortBreak);
      controller.startTimer();

      // 5-minute break completed
      mockClockTime = mockClockTime.add(const Duration(minutes: 6));
      await controller.handleAppLifecycleResumed();

      final state = container.read(focusTimerControllerProvider);
      expect(state.status, FocusTimerStatus.completed);
      expect(state.lastAwardedXp, 0);
      expect(mockGamificationRepo.ledger, isEmpty);
    });

    test('enforces daily 180 XP cap across multiple focus sessions', () async {
      final mockGamificationRepo = MockGamificationRepository();
      final todayStr = AppDateUtils.todayString;

      // Manually pre-seed 165 focus XP today
      mockGamificationRepo.ledger.add(
        XpEntry(
          id: 1,
          sourceType: XpSourceType.focusSession,
          eventDate: todayStr,
          xpAmount: 165,
          status: XpStatus.active,
          createdAt: DateTime.now(),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          focusClockProvider.overrideWithValue(() => mockClockTime),
          gamificationRepositoryProvider.overrideWithValue(
            mockGamificationRepo,
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(focusTimerControllerProvider.notifier);

      // Complete a 25-minute session: only 15 XP remains before 180 daily cap!
      controller.setPresetMinutes(25);
      controller.startTimer();
      mockClockTime = mockClockTime.add(const Duration(minutes: 26));
      await controller.handleAppLifecycleResumed();

      final state = container.read(focusTimerControllerProvider);
      expect(state.lastAwardedXp, 15);
      expect(await mockGamificationRepo.getTotalActiveXp(), 180);

      // Another 15-minute session on same day awards 0 XP
      controller.setPresetMinutes(15);
      controller.startTimer();
      mockClockTime = mockClockTime.add(const Duration(minutes: 16));
      await controller.handleAppLifecycleResumed();

      expect(container.read(focusTimerControllerProvider).lastAwardedXp, 0);
      expect(await mockGamificationRepo.getTotalActiveXp(), 180);
    });
  });

  group('FocusScreen UI & Interaction Tests', () {
    testWidgets(
      'renders arcane timer ring, mode selector, and switches presets',
      (tester) async {
        final mockGamificationRepo = MockGamificationRepository();
        final sampleHabit = Habit(
          id: 10,
          title: 'Deep Meditation',
          category: 'Health',
          colorValue: 0xFF10B981,
          createdAt: DateTime.now(),
          completedDates: const {},
        );

        final mockHabitRepo = MockHabitRepository([sampleHabit]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              focusClockProvider.overrideWithValue(() => mockClockTime),
              gamificationRepositoryProvider.overrideWithValue(
                mockGamificationRepo,
              ),
              habitRepositoryProvider.overrideWithValue(mockHabitRepo),
            ],
            child: const MaterialApp(home: FocusScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Focus Session'), findsOneWidget);
        expect(find.text('Focus Trial'), findsOneWidget);
        expect(find.text('Short Rest'), findsOneWidget);
        expect(find.text('Deep Rest'), findsOneWidget);
        expect(find.text('25:00'), findsOneWidget);
        expect(find.text('Start Focus'), findsOneWidget);

        // Switch to Short Rest (5 min)
        await tester.tap(find.text('Short Rest'));
        await tester.pumpAndSettle();
        expect(find.text('05:00'), findsOneWidget);

        // Switch back to Focus Trial (25 min)
        await tester.tap(find.text('Focus Trial'));
        await tester.pumpAndSettle();
        expect(find.text('25:00'), findsOneWidget);

        // Start focus -> displays Pause
        await tester.tap(find.text('Start Focus'));
        await tester.pump();
        expect(find.text('Pause'), findsOneWidget);

        // Pause focus -> displays Start Focus
        await tester.tap(find.text('Pause'));
        await tester.pump();
        expect(find.text('Start Focus'), findsOneWidget);
      },
    );

    testWidgets('ArcaneTimerRing respects reduced-motion without errors', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: ArcaneTimerRing(
                remainingDuration: Duration(minutes: 18),
                totalDuration: Duration(minutes: 25),
                progressRatio: 0.72,
                isRunning: true,
                isPaused: false,
                mode: FocusMode.focus,
                activeColor: Color(0xFF8B5CF6),
                presetMinutes: 25,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('18:00'), findsOneWidget);
      expect(find.text('+25 XP Channel'), findsOneWidget);
    });

    testWidgets(
      'FocusVictoryDialog displays awarded XP and dismisses cleanly',
      (tester) async {
        bool dismissed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FocusVictoryDialog(
                awardedXp: 25,
                completedHabitTitle: 'Morning Meditation',
                profile: UserProfile(
                  heroName: 'Grand Mage',
                  avatarId: 'knight_helm',
                  totalXp: 500,
                  currentLevel: 4,
                  createdAt: DateTime.now(),
                ),
                onDismiss: () => dismissed = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('TRIAL CONQUERED!'), findsOneWidget);
        expect(find.text('+25 Focus XP Earned'), findsOneWidget);
        expect(
          find.text('Quest "Morning Meditation" completed for today!'),
          findsOneWidget,
        );
        expect(find.text('500 Total XP'), findsOneWidget);

        await tester.tap(find.text('Claim Victory'));
        await tester.pumpAndSettle();
        expect(dismissed, isTrue);
      },
    );
  });
}
