import 'package:daily_flow/core/database/db_helper.dart';
import 'package:daily_flow/core/utils/date_utils.dart';
import 'package:daily_flow/features/focus/controllers/focus_timer_controller.dart';
import 'package:daily_flow/features/gamification/data/gamification_repository.dart';
import 'package:daily_flow/features/gamification/models/achievement.dart';
import 'package:daily_flow/features/gamification/models/xp_entry.dart';
import 'package:daily_flow/features/habits/controllers/habit_controller.dart';
import 'package:daily_flow/features/habits/data/habit_repository.dart';
import 'package:daily_flow/features/habits/models/habit.dart';
import 'package:daily_flow/features/habits/screen/widgets/habit_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late SqliteHabitRepository habitRepo;
  late SqliteGamificationRepository gamificationRepo;
  DateTime currentTestClock = DateTime(2026, 11, 2, 10, 0, 0);

  setUp(() async {
    currentTestClock = DateTime(2026, 11, 2, 10, 0, 0);
    AppDateUtils.setCustomClock(() => currentTestClock);

    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE habits (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              created_at TEXT NOT NULL,
              category TEXT NOT NULL DEFAULT 'General',
              color_value INTEGER NOT NULL DEFAULT 4283385573,
              is_archived INTEGER NOT NULL DEFAULT 0
            )
          ''');

          await db.execute('''
            CREATE TABLE habit_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              habit_id INTEGER NOT NULL,
              completed_date TEXT NOT NULL,
              FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
              UNIQUE(habit_id, completed_date)
            )
          ''');

          await db.execute('''
            CREATE TABLE xp_ledger (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              source_type TEXT NOT NULL,
              source_id INTEGER,
              event_date TEXT NOT NULL,
              xp_amount INTEGER NOT NULL,
              status TEXT NOT NULL DEFAULT 'ACTIVE',
              created_at TEXT NOT NULL,
              UNIQUE(source_type, source_id, event_date)
            )
          ''');

          await db.execute('''
            CREATE TABLE user_profile (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              hero_name TEXT NOT NULL DEFAULT 'DailyFlow Champion',
              avatar_id TEXT NOT NULL DEFAULT 'knight_helm',
              total_xp INTEGER NOT NULL DEFAULT 0,
              current_level INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE achievements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              badge_key TEXT NOT NULL UNIQUE,
              current_progress INTEGER NOT NULL DEFAULT 0,
              is_unlocked INTEGER NOT NULL DEFAULT 0,
              unlocked_at TEXT
            )
          ''');

          await db.insert('user_profile', {
            'hero_name': 'DailyFlow Champion',
            'avatar_id': 'knight_helm',
            'total_xp': 0,
            'current_level': 1,
            'created_at': DateTime.now().toIso8601String(),
          });

          for (final def in Achievement.definitions.values) {
            await db.insert('achievements', {
              'badge_key': def.key,
              'current_progress': 0,
              'is_unlocked': 0,
              'unlocked_at': null,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        },
      ),
    );

    DBHelper.setTestDatabase(db);
    habitRepo = SqliteHabitRepository();
    gamificationRepo = SqliteGamificationRepository();
  });

  tearDown(() async {
    DBHelper.setTestDatabase(null);
    AppDateUtils.setCustomClock(null);
    await db.close();
  });

  group('Today-Only Habit Completion System Tests', () {
    // 1. Checking today's habit succeeds and awards XP
    test(
      '1. Checking today habit succeeds, writes log, and awards XP',
      () async {
        final habit = await habitRepo.createHabit(
          title: 'Morning Yoga',
          category: 'Health',
          colorValue: 0xFF10B981,
        );

        final container = ProviderContainer(
          overrides: [
            habitRepositoryProvider.overrideWithValue(habitRepo),
            gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(habitControllerProvider.notifier).loadHabits();
        final todayStr = AppDateUtils.todayString; // '2026-11-02'

        await container
            .read(habitControllerProvider.notifier)
            .toggleHabitOnDate(habit, todayStr);

        final updatedHabits = container.read(habitControllerProvider);
        expect(updatedHabits.first.completedDates.contains(todayStr), isTrue);
        expect(updatedHabits.first.isCompletedToday, isTrue);

        // Verify SQLite habit_logs record
        final logs = await db.query('habit_logs');
        expect(logs.length, 1);
        expect(logs.first['completed_date'], todayStr);

        // Verify XP ledger
        final ledger = await gamificationRepo.getXpEntries();
        expect(ledger.length, 1);
        expect(ledger.first.eventDate, todayStr);
        expect(ledger.first.status, XpStatus.active);
        expect(ledger.first.xpAmount, 20);

        // Verify User Profile
        final profile = await gamificationRepo.getUserProfile();
        expect(profile.totalXp, 20);
      },
    );

    // 2. Unchecking today's habit revokes XP
    test('2. Unchecking today habit removes log and revokes XP', () async {
      final habit = await habitRepo.createHabit(
        title: 'Meditation',
        category: 'Health',
        colorValue: 0xFF10B981,
      );

      final container = ProviderContainer(
        overrides: [
          habitRepositoryProvider.overrideWithValue(habitRepo),
          gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(habitControllerProvider.notifier).loadHabits();
      final todayStr = AppDateUtils.todayString;

      // Check-in
      await container
          .read(habitControllerProvider.notifier)
          .toggleHabitForToday(habit);

      expect(await gamificationRepo.getTotalActiveXp(), 20);

      // Uncheck
      final checkedHabit = container.read(habitControllerProvider).first;
      await container
          .read(habitControllerProvider.notifier)
          .toggleHabitForToday(checkedHabit);

      final uncompletedHabits = container.read(habitControllerProvider);
      expect(
        uncompletedHabits.first.completedDates.contains(todayStr),
        isFalse,
      );
      expect(uncompletedHabits.first.isCompletedToday, isFalse);

      // SQLite habit_logs should be empty
      final logs = await db.query('habit_logs');
      expect(logs, isEmpty);

      // XP ledger should be REVOKED
      final ledger = await gamificationRepo.getXpEntries();
      expect(ledger.length, 1);
      expect(ledger.first.status, XpStatus.revoked);
      expect(await gamificationRepo.getTotalActiveXp(), 0);
    });

    // 3. Attempting to check yesterday
    test(
      '3. Attempting to check yesterday is rejected at controller and repository level',
      () async {
        final habit = await habitRepo.createHabit(
          title: 'Read Coding Docs',
          category: 'Coding',
          colorValue: 0xFF4F46E5,
        );

        final container = ProviderContainer(
          overrides: [
            habitRepositoryProvider.overrideWithValue(habitRepo),
            gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(habitControllerProvider.notifier).loadHabits();
        const yesterdayStr = '2026-11-01';

        // 1. Controller rejection: silently ignored, no DB changes
        await container
            .read(habitControllerProvider.notifier)
            .toggleHabitOnDate(habit, yesterdayStr);

        final habitsAfterController = container.read(habitControllerProvider);
        expect(habitsAfterController.first.completedDates, isEmpty);
        expect(await db.query('habit_logs'), isEmpty);
        expect(await gamificationRepo.getXpEntries(), isEmpty);

        // 2. Direct repository call rejection: throws ArgumentError
        expect(
          () => habitRepo.toggleHabitLog(
            habitId: habit.id!,
            dateStr: yesterdayStr,
            isCompleted: false,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(await db.query('habit_logs'), isEmpty);
        expect(await gamificationRepo.getTotalActiveXp(), 0);
      },
    );

    // 4. Attempting to check tomorrow
    test(
      '4. Attempting to check tomorrow is rejected at controller and repository level',
      () async {
        final habit = await habitRepo.createHabit(
          title: 'Future Quest',
          category: 'General',
          colorValue: 0xFF4F46E5,
        );

        final container = ProviderContainer(
          overrides: [
            habitRepositoryProvider.overrideWithValue(habitRepo),
            gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(habitControllerProvider.notifier).loadHabits();
        const tomorrowStr = '2026-11-03';

        // Controller rejection
        await container
            .read(habitControllerProvider.notifier)
            .toggleHabitOnDate(habit, tomorrowStr);

        final habits = container.read(habitControllerProvider);
        expect(habits.first.completedDates, isEmpty);

        // Repository rejection
        expect(
          () => habitRepo.toggleHabitLog(
            habitId: habit.id!,
            dateStr: tomorrowStr,
            isCompleted: false,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(await db.query('habit_logs'), isEmpty);
        expect(await gamificationRepo.getTotalActiveXp(), 0);
      },
    );

    // 5. Attempting to revoke a historical completion
    test(
      '5. Attempting to uncheck/revoke a historical completion is rejected',
      () async {
        final habit = await habitRepo.createHabit(
          title: 'Drink 2L Water',
          category: 'Health',
          colorValue: 0xFF059669,
        );

        const pastDate = '2026-10-31';

        // Seed historical log and XP in DB directly
        await db.insert('habit_logs', {
          'habit_id': habit.id,
          'completed_date': pastDate,
        });
        await db.insert('xp_ledger', {
          'source_type': XpSourceType.habitCheckin,
          'source_id': habit.id,
          'event_date': pastDate,
          'xp_amount': 20,
          'status': XpStatus.active,
          'created_at': DateTime.parse(pastDate).toIso8601String(),
        });
        await db.update('user_profile', {'total_xp': 20});

        final container = ProviderContainer(
          overrides: [
            habitRepositoryProvider.overrideWithValue(habitRepo),
            gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(habitControllerProvider.notifier).loadHabits();
        final loadedHabit = container.read(habitControllerProvider).first;
        expect(loadedHabit.completedDates.contains(pastDate), isTrue);

        // Attempting to toggle/uncheck past date via controller is rejected
        await container
            .read(habitControllerProvider.notifier)
            .toggleHabitOnDate(loadedHabit, pastDate);

        // Habit completion state remains unchanged
        final afterAttempt = container.read(habitControllerProvider).first;
        expect(afterAttempt.completedDates.contains(pastDate), isTrue);

        // Attempting to revoke past date via repository throws ArgumentError
        expect(
          () => habitRepo.toggleHabitLog(
            habitId: habit.id!,
            dateStr: pastDate,
            isCompleted: true,
          ),
          throwsA(isA<ArgumentError>()),
        );

        // Historical log and XP remain active and untouched
        final logs = await db.query('habit_logs');
        expect(logs.length, 1);
        expect(await gamificationRepo.getTotalActiveXp(), 20);
      },
    );

    // 6. Midnight date rollover
    test(
      '6. Midnight date rollover advances today, locks previous day, and separates completion',
      () async {
        await habitRepo.createHabit(
          title: 'Nightly Review',
          category: 'Study',
          colorValue: 0xFFD97706,
        );

        final container = ProviderContainer(
          overrides: [
            habitRepositoryProvider.overrideWithValue(habitRepo),
            gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(habitControllerProvider.notifier).loadHabits();

        // Day 1: 2026-11-02 23:59:50
        currentTestClock = DateTime(2026, 11, 2, 23, 59, 50);
        final day1 = container.read(habitControllerProvider).first;
        await container
            .read(habitControllerProvider.notifier)
            .toggleHabitForToday(day1);

        expect(
          container
              .read(habitControllerProvider)
              .first
              .completedDates
              .contains('2026-11-02'),
          isTrue,
        );
        expect(
          container.read(habitControllerProvider).first.isCompletedToday,
          isTrue,
        );

        // Advance clock past midnight to Day 2: 2026-11-03 00:00:10
        currentTestClock = DateTime(2026, 11, 3, 0, 0, 10);
        container.read(currentDateProvider.notifier).checkDateChanged();

        // On Day 2, isCompletedToday is false (yesterday's completion is not copied into today)
        final day2Habit = container.read(habitControllerProvider).first;
        expect(day2Habit.isCompletedToday, isFalse);

        // Day 1 ('2026-11-02') is now strictly past and read-only
        expect(AppDateUtils.isPastDay('2026-11-02'), isTrue);
        await container
            .read(habitControllerProvider.notifier)
            .toggleHabitOnDate(day2Habit, '2026-11-02');
        // Verify Day 1 was not removed or altered
        expect(
          container
              .read(habitControllerProvider)
              .first
              .completedDates
              .contains('2026-11-02'),
          isTrue,
        );

        // Now toggle for Day 2:
        await container
            .read(habitControllerProvider.notifier)
            .toggleHabitForToday(day2Habit);
        final updatedDay2 = container.read(habitControllerProvider).first;
        expect(updatedDay2.completedDates.contains('2026-11-03'), isTrue);
        expect(updatedDay2.isCompletedToday, isTrue);
        expect(updatedDay2.currentStreak, 2); // 2 consecutive days!
      },
    );

    // 7. App resume after midnight
    test(
      '7. App resume after midnight triggers checkDateChanged and updates currentDateProvider',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        currentTestClock = DateTime(2026, 11, 2, 22, 0, 0);
        expect(container.read(currentDateProvider), '2026-11-02');

        // Simulate app suspended overnight and resumed next morning
        currentTestClock = DateTime(2026, 11, 3, 8, 30, 0);
        container.read(currentDateProvider.notifier).checkDateChanged();

        expect(container.read(currentDateProvider), '2026-11-03');
      },
    );

    // 8. Time-zone changes
    test(
      '8. Time-zone changes normalize calendar dates safely without timestamp comparison errors',
      () {
        // Local date in UTC+7 (e.g., Nov 3 04:00) vs UTC (Nov 2 21:00)
        final localDateTime = DateTime(2026, 11, 3, 4, 30, 0);
        final normalized = AppDateUtils.normalizeDate(localDateTime);
        expect(normalized.year, 2026);
        expect(normalized.month, 11);
        expect(normalized.day, 3);
        expect(normalized.hour, 0);
        expect(normalized.minute, 0);

        AppDateUtils.setCustomClock(() => localDateTime);
        expect(AppDateUtils.todayString, '2026-11-03');
        expect(AppDateUtils.isToday('2026-11-03'), isTrue);
        expect(AppDateUtils.isPastDay('2026-11-02'), isTrue);
        expect(AppDateUtils.isFutureDay('2026-11-04'), isTrue);
      },
    );

    // 9. XP anti-farming protection
    test(
      '9. XP anti-farming protection prevents duplicate XP on repeated today toggles',
      () async {
        await habitRepo.createHabit(
          title: 'Core Workout',
          category: 'Fitness',
          colorValue: 0xFFEF4444,
        );

        final container = ProviderContainer(
          overrides: [
            habitRepositoryProvider.overrideWithValue(habitRepo),
            gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(habitControllerProvider.notifier).loadHabits();

        // Rapidly toggle today's check-in 10 times (ON and OFF)
        for (int i = 0; i < 10; i++) {
          final current = container.read(habitControllerProvider).first;
          await container
              .read(habitControllerProvider.notifier)
              .toggleHabitForToday(current);
        }

        // If ended up completed, total XP must be exactly 20, never 200
        final state = container.read(habitControllerProvider).first;
        final expectedXp = state.isCompletedToday ? 20 : 0;
        expect(await gamificationRepo.getTotalActiveXp(), expectedXp);

        final entries = await gamificationRepo.getXpEntries();
        expect(entries.length, 1); // Exactly 1 row in the ledger
      },
    );

    // 10. Focus-linked habit completion
    test(
      '10. Focus-linked habit auto-completion records for completion date (including midnight crossing)',
      () async {
        final habit = await habitRepo.createHabit(
          title: 'Deep Coding',
          category: 'Coding',
          colorValue: 0xFF4F46E5,
        );

        // Start focus session at 23:50 on Nov 2
        currentTestClock = DateTime(2026, 11, 2, 23, 50, 0);

        final container = ProviderContainer(
          overrides: [
            habitRepositoryProvider.overrideWithValue(habitRepo),
            gamificationRepositoryProvider.overrideWithValue(gamificationRepo),
            focusClockProvider.overrideWithValue(() => currentTestClock),
          ],
        );
        addTearDown(container.dispose);

        await container.read(habitControllerProvider.notifier).loadHabits();

        final focusController = container.read(
          focusTimerControllerProvider.notifier,
        );
        focusController.selectHabit(habit.id);
        focusController.setMode(FocusMode.focus);
        focusController.startTimer();

        // Session completes at 00:15 on Nov 3 (crossing midnight)
        currentTestClock = DateTime(2026, 11, 3, 0, 15, 0);
        await focusController.handleAppLifecycleResumed();

        // Verify linked habit was completed on Nov 3 (completion date), NOT Nov 2
        final habits = container.read(habitControllerProvider);
        final updatedHabit = habits.firstWhere((h) => h.id == habit.id);
        expect(updatedHabit.completedDates.contains('2026-11-03'), isTrue);
        expect(updatedHabit.completedDates.contains('2026-11-02'), isFalse);

        // Verify habit_logs in DB
        final logs = await db.query('habit_logs');
        expect(logs.length, 1);
        expect(logs.first['completed_date'], '2026-11-03');
      },
    );

    // 11. UI showing past dates as read-only
    testWidgets(
      '11. UI HabitTile presents past dates as read-only and today as interactive',
      (WidgetTester tester) async {
        currentTestClock = DateTime(2026, 11, 2, 12, 0, 0);

        // Habit with completed past date (yesterday 2026-11-01) and uncompleted today (2026-11-02)
        final habit = Habit(
          id: 1,
          title: 'Master Swordsmanship',
          createdAt: DateTime(2026, 10, 20),
          completedDates: {'2026-11-01'},
          category: 'Fitness',
          colorValue: 0xFF10B981,
        );

        String? tappedDate;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HabitTile(
                habit: habit,
                onToggle: () {},
                onToggleDate: (dateStr) {
                  tappedDate = dateStr;
                },
                onEdit: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        // 1. Verify accessibility semantics
        // Past dates must have button: false and '(Read-only)' label
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.button == false &&
                (w.properties.label?.contains('Read-only') ?? false),
          ),
          findsNWidgets(6), // 6 historical days in 7-day strip
        );

        // Today must have button: true
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.button == true &&
                (w.properties.label?.contains('Today') ?? false),
          ),
          findsOneWidget,
        );

        // 2. Verify lock icons appear on uncompleted past days
        expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);

        // 3. Verify tapping today triggers onToggleDate
        final todayFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              (w.properties.label?.contains('Today') ?? false),
        );
        await tester.tap(todayFinder);
        await tester.pump();
        expect(tappedDate, '2026-11-02');

        // 4. Verify tapping past day does NOT trigger onToggleDate
        tappedDate = null;
        final pastFinder = find
            .byWidgetPredicate(
              (w) =>
                  w is Semantics &&
                  w.properties.button == false &&
                  (w.properties.label?.contains('Read-only') ?? false),
            )
            .first;
        await tester.tap(pastFinder);
        await tester.pump();
        expect(tappedDate, isNull);
      },
    );

    // 12. Persistence of existing historical data
    test(
      '12. Existing historical habit logs and XP persist without alteration or auto-copying',
      () async {
        // Seed an established user history: 10 historical completions across October
        final habit = await habitRepo.createHabit(
          title: 'Archery Practice',
          category: 'General',
          colorValue: 0xFF6366F1,
        );

        final historicalDates = [
          '2026-10-23',
          '2026-10-24',
          '2026-10-25',
          '2026-10-26',
          '2026-10-27',
          '2026-10-28',
          '2026-10-29',
          '2026-10-30',
          '2026-10-31',
          '2026-11-01', // yesterday
        ];

        for (final dateStr in historicalDates) {
          await db.insert('habit_logs', {
            'habit_id': habit.id,
            'completed_date': dateStr,
          });
          await db.insert('xp_ledger', {
            'source_type': XpSourceType.habitCheckin,
            'source_id': habit.id,
            'event_date': dateStr,
            'xp_amount': 20,
            'status': XpStatus.active,
            'created_at': DateTime.parse(dateStr).toIso8601String(),
          });
        }
        await db.update('user_profile', {
          'total_xp': historicalDates.length * 20,
        });

        // Load habits fresh from repository
        final habits = await habitRepo.getHabits();
        expect(habits.length, 1);
        final loaded = habits.first;

        // Verify all 10 historical dates loaded
        expect(loaded.completedDates.length, 10);
        for (final dateStr in historicalDates) {
          expect(loaded.completedDates.contains(dateStr), isTrue);
        }

        // Verify streak is alive from yesterday
        expect(loaded.currentStreak, 10);
        expect(loaded.bestStreak, 10);

        // Verify today is NOT auto-completed
        expect(loaded.completedDates.contains('2026-11-02'), isFalse);
        expect(loaded.isCompletedToday, isFalse);

        // Verify total active XP from ledger is 200
        expect(await gamificationRepo.getTotalActiveXp(), 200);
      },
    );
  });
}
