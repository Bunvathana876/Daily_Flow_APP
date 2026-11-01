import 'package:daily_flow/core/database/db_helper.dart';
import 'package:daily_flow/core/utils/date_utils.dart';
import 'package:daily_flow/features/gamification/data/gamification_repository.dart';
import 'package:daily_flow/features/gamification/models/achievement.dart';
import 'package:daily_flow/features/gamification/models/xp_entry.dart';
import 'package:daily_flow/features/habits/data/habit_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late SqliteHabitRepository habitRepo;
  late SqliteGamificationRepository gamificationRepo;

  setUp(() async {
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
    await db.close();
  });

  group('Anti-Farming & Atomic Habit Check-in Tests', () {
    test(
      'First check-in awards base XP and updates user profile level',
      () async {
        final habit = await habitRepo.createHabit(
          title: 'Morning Run',
          category: 'Fitness',
          colorValue: 0xFF4F46E5,
        );

        final todayStr = AppDateUtils.todayString;

        // Check-in habit
        await habitRepo.toggleHabitLog(
          habitId: habit.id!,
          dateStr: todayStr,
          isCompleted:
              false, // isCompleted is false before toggling -> toggling ON
        );

        final totalXp = await gamificationRepo.getTotalActiveXp();
        expect(totalXp, 20);

        final profile = await gamificationRepo.getUserProfile();
        expect(profile.totalXp, 20);
        expect(profile.currentLevel, 1);

        final entries = await gamificationRepo.getXpEntries();
        expect(entries.length, 1);
        expect(entries.first.sourceType, XpSourceType.habitCheckin);
        expect(entries.first.sourceId, habit.id);
        expect(entries.first.eventDate, todayStr);
        expect(entries.first.status, XpStatus.active);
        expect(entries.first.xpAmount, 20);
      },
    );

    test('Unchecking habit revokes XP atomically', () async {
      final habit = await habitRepo.createHabit(
        title: 'Drink Water',
        category: 'Health',
        colorValue: 0xFF059669,
      );

      final todayStr = AppDateUtils.todayString;

      // Check-in
      await habitRepo.toggleHabitLog(
        habitId: habit.id!,
        dateStr: todayStr,
        isCompleted: false,
      );
      expect(await gamificationRepo.getTotalActiveXp(), 20);

      // Uncheck
      await habitRepo.toggleHabitLog(
        habitId: habit.id!,
        dateStr: todayStr,
        isCompleted: true, // was completed, now unchecking
      );

      expect(await gamificationRepo.getTotalActiveXp(), 0);

      final profile = await gamificationRepo.getUserProfile();
      expect(profile.totalXp, 0);

      final entries = await gamificationRepo.getXpEntries();
      expect(entries.length, 1);
      expect(entries.first.status, XpStatus.revoked);
    });

    test(
      'Rapid toggle farm attack: 50 cycles results in exactly 20 XP',
      () async {
        final habit = await habitRepo.createHabit(
          title: 'Read Books',
          category: 'Study',
          colorValue: 0xFFD97706,
        );

        final todayStr = AppDateUtils.todayString;

        // Simulate malicious or rapid toggling 50 times
        for (int i = 0; i < 50; i++) {
          // Toggle ON
          await habitRepo.toggleHabitLog(
            habitId: habit.id!,
            dateStr: todayStr,
            isCompleted: false,
          );
          // Toggle OFF
          await habitRepo.toggleHabitLog(
            habitId: habit.id!,
            dateStr: todayStr,
            isCompleted: true,
          );
        }

        // Final toggle ON
        await habitRepo.toggleHabitLog(
          habitId: habit.id!,
          dateStr: todayStr,
          isCompleted: false,
        );

        // Verify user has strictly 20 XP, not 1000 XP!
        final totalXp = await gamificationRepo.getTotalActiveXp();
        expect(totalXp, 20);

        // Verify only 1 ledger row exists for this habit and date
        final entries = await gamificationRepo.getXpEntries();
        expect(entries.length, 1);
        expect(entries.first.status, XpStatus.active);
        expect(entries.first.xpAmount, 20);
      },
    );

    test('Backdated completion logs with correct historical date', () async {
      final habit = await habitRepo.createHabit(
        title: 'Evening Walk',
        category: 'Health',
        colorValue: 0xFF059669,
      );

      const pastDate = '2026-10-25';

      await habitRepo.toggleHabitLog(
        habitId: habit.id!,
        dateStr: pastDate,
        isCompleted: false,
      );

      final entries = await gamificationRepo.getXpEntries();
      expect(entries.length, 1);
      expect(entries.first.eventDate, pastDate);
      expect(entries.first.xpAmount, 20);
      expect(entries.first.status, XpStatus.active);

      expect(await gamificationRepo.getTotalActiveXp(), 20);
    });

    test('Focus challenge awards XP and enforces 180 XP daily cap', () async {
      const todayStr = '2026-11-01';

      // 1. Session of 25 mins -> 25 XP
      await gamificationRepo.awardFocusSession(
        durationMinutes: 25,
        dateStr: todayStr,
      );
      expect(await gamificationRepo.getTotalActiveXp(), 25);

      // 2. Session of 60 mins -> 60 XP
      await gamificationRepo.awardFocusSession(
        durationMinutes: 60,
        dateStr: todayStr,
      );
      expect(await gamificationRepo.getTotalActiveXp(), 85);

      // 3. Session of 90 mins -> 90 XP (total 175 XP)
      await gamificationRepo.awardFocusSession(
        durationMinutes: 90,
        dateStr: todayStr,
      );
      expect(await gamificationRepo.getTotalActiveXp(), 175);

      // 4. Another session of 25 mins: only 5 XP remaining before daily 180 cap!
      await gamificationRepo.awardFocusSession(
        durationMinutes: 25,
        dateStr: todayStr,
      );
      expect(await gamificationRepo.getTotalActiveXp(), 180);

      // 5. Subsequent session on same day awards 0 XP due to cap
      await gamificationRepo.awardFocusSession(
        durationMinutes: 45,
        dateStr: todayStr,
      );
      expect(await gamificationRepo.getTotalActiveXp(), 180);
    });

    test('Achievement unlocking awards bonus XP into ledger', () async {
      final initialXp = await gamificationRepo.getTotalActiveXp();
      expect(initialXp, 0);

      // Unlock 'first_spark' (+50 XP)
      final unlocked = await gamificationRepo.unlockAchievement('first_spark');
      expect(unlocked, isTrue);

      final totalXp = await gamificationRepo.getTotalActiveXp();
      expect(totalXp, 50);

      final achievements = await gamificationRepo.getAchievements();
      final firstSpark = achievements.firstWhere(
        (a) => a.badgeKey == 'first_spark',
      );
      expect(firstSpark.isUnlocked, isTrue);
      expect(firstSpark.unlockedAt, isNotNull);
    });
  });
}
