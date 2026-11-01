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
            heroName: 'Arcane Mage',
            avatarId: 'wizard_hat',
            totalXp: 350,
            currentLevel: 3,
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
  Future<int> getTotalFocusMinutes() async => 50;

  @override
  Future<int> getTotalFocusSessions() async => 2;

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
    'HABIT_CHECKIN': 200,
    'FOCUS_SESSION': 100,
    'ACHIEVEMENT': 50,
  };

  @override
  Future<void> recalculateTotalXpAndLevel() async {}
}

class MockHabitRepository implements HabitRepository {
  final List<Habit> habits;

  MockHabitRepository(this.habits);

  @override
  Future<List<Habit>> getHabits() async => List.unmodifiable(habits);

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

  late DateTime mockClockTime;
  late MockGamificationRepository mockGamificationRepo;
  late MockHabitRepository mockHabitRepo;

  final testHabits = [
    Habit(
      id: 1,
      title: 'Spellcraft Study',
      category: 'Learning',
      colorValue: 0xFF8B5CF6,
      createdAt: DateTime.now(),
      completedDates: const {},
    ),
    Habit(
      id: 2,
      title: 'Alchemical Brewing',
      category: 'Crafting',
      colorValue: 0xFF10B981,
      createdAt: DateTime.now(),
      completedDates: {AppDateUtils.todayString},
    ),
  ];

  setUp(() {
    mockClockTime = DateTime(2026, 11, 1, 14, 0, 0);
    mockGamificationRepo = MockGamificationRepository();
    mockHabitRepo = MockHabitRepository(testHabits);
  });

  Widget createFocusChamberApp({
    Size screenSize = const Size(800, 1000),
    bool disableAnimations = false,
  }) {
    return ProviderScope(
      overrides: [
        focusClockProvider.overrideWithValue(() => mockClockTime),
        gamificationRepositoryProvider.overrideWithValue(mockGamificationRepo),
        habitRepositoryProvider.overrideWithValue(mockHabitRepo),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            disableAnimations: disableAnimations,
          ),
          child: const FocusScreen(),
        ),
      ),
    );
  }

  group('Phase C Arcane Focus Chamber UI Tests', () {
    testWidgets(
      '1. Arcane Timer Ring renders countdown, XP preview and runes',
      (tester) async {
        await tester.pumpWidget(createFocusChamberApp());
        await tester.pumpAndSettle();

        // Header title
        expect(find.text('Focus Session'), findsOneWidget);

        // Arcane Timer Ring displays initial 25:00
        expect(find.text('25:00'), findsOneWidget);

        // Shows +25 XP Channel preview pill
        expect(find.text('+25 XP Channel'), findsOneWidget);

        // CustomPainter for arcane runes and circular tracks
        expect(find.byType(ArcaneTimerRing), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      },
    );

    testWidgets('2. Focus Mode Selection switches tabs and durations', (
      tester,
    ) async {
      await tester.pumpWidget(createFocusChamberApp());
      await tester.pumpAndSettle();

      expect(find.text('Focus Trial'), findsWidgets);
      expect(find.text('Short Rest'), findsWidgets);
      expect(find.text('Deep Rest'), findsWidgets);

      // Switch to Short Rest
      await tester.tap(find.text('Short Rest').first);
      await tester.pumpAndSettle();

      expect(find.text('05:00'), findsOneWidget);
      expect(find.text('Restoring mana & focus...'), findsOneWidget);

      // Switch to Deep Rest
      await tester.tap(find.text('Deep Rest').first);
      await tester.pumpAndSettle();

      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('Restoring mana & focus...'), findsOneWidget);

      // Switch back to Focus Trial
      await tester.tap(find.text('Focus Trial').first);
      await tester.pumpAndSettle();

      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('+25 XP Channel'), findsOneWidget);
    });

    testWidgets('3. Action controls: Start, Pause, Resume, and Reset', (
      tester,
    ) async {
      await tester.pumpWidget(createFocusChamberApp());
      await tester.pumpAndSettle();

      // Initial state has "Start Focus" button
      expect(find.text('Start Focus'), findsOneWidget);
      expect(find.text('Pause'), findsNothing);

      // Tap Start Focus
      await tester.tap(find.text('Start Focus'));
      await tester.pump();

      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Start Focus'), findsNothing);

      // Tap Pause
      await tester.tap(find.text('Pause'));
      await tester.pump();

      expect(find.text('Start Focus'), findsOneWidget);

      // Tap Reset Timer button
      expect(find.byTooltip('Reset Timer'), findsOneWidget);
      await tester.tap(find.byTooltip('Reset Timer'));
      await tester.pump();

      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Start Focus'), findsOneWidget);
    });

    testWidgets(
      '4. Quest empowerment selector displays habits and links quest',
      (tester) async {
        await tester.pumpWidget(createFocusChamberApp());
        await tester.pumpAndSettle();

        // Initial uncompleted habit is auto-selected
        expect(find.text('Spellcraft Study'), findsWidgets);

        // Tap to open dropdown
        await tester.tap(find.text('Spellcraft Study').first);
        await tester.pumpAndSettle();

        // Dropdown menu items exist
        expect(find.text('Alchemical Brewing'), findsWidgets);

        // Select 'Alchemical Brewing'
        await tester.tap(find.text('Alchemical Brewing').last);
        await tester.pumpAndSettle();

        expect(find.text('Alchemical Brewing'), findsWidgets);
      },
    );

    testWidgets('5. Focus Victory Dialog displays XP, quest status and cap', (
      tester,
    ) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FocusVictoryDialog(
              awardedXp: 25,
              completedHabitTitle: 'Spellcraft Study',
              profile: UserProfile(
                heroName: 'Grand Enchanter',
                avatarId: 'wizard_hat',
                totalXp: 750,
                currentLevel: 5,
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
        find.text('Quest "Spellcraft Study" completed for today!'),
        findsOneWidget,
      );
      expect(find.text('750 Total XP'), findsOneWidget);
      expect(find.textContaining('Daily Focus XP Cap:'), findsOneWidget);

      // Tap Claim Victory
      await tester.tap(find.text('Claim Victory'));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });

    testWidgets('6. Responsive on narrow 320px screens without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createFocusChamberApp(screenSize: const Size(320, 640)),
      );
      await tester.pumpAndSettle();

      // No overflow exceptions occurred
      expect(tester.takeException(), isNull);
      expect(find.text('Focus Session'), findsOneWidget);
      expect(find.text('Start Focus'), findsOneWidget);
    });

    testWidgets('7. Reduced motion mode disables ambient animations safely', (
      tester,
    ) async {
      await tester.pumpWidget(createFocusChamberApp(disableAnimations: true));
      await tester.pumpAndSettle();

      expect(find.text('Focus Session'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
