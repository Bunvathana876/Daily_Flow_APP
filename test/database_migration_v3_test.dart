import 'dart:io';
import 'package:daily_flow/core/database/db_helper.dart';
import 'package:daily_flow/core/utils/gamification_math.dart';
import 'package:daily_flow/features/gamification/data/gamification_repository.dart';
import 'package:daily_flow/features/gamification/models/achievement.dart';
import 'package:daily_flow/features/habits/data/habit_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late String dbPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'daily_flow_migration_test_',
    );
    dbPath = p.join(tempDir.path, 'migration_test.db');
  });

  tearDown(() async {
    DBHelper.setTestDatabase(null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Database Migration from v2 to v3 with historical XP backfill', () async {
    // 1. Create a legacy v2 SQLite database
    final v2Db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE habits (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              created_at TEXT NOT NULL,
              category TEXT NOT NULL DEFAULT 'General',
              color_value INTEGER NOT NULL DEFAULT 4283385573
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
        },
      ),
    );

    // 2. Insert realistic existing user data into v2 database
    final habit1Id = await v2Db.insert('habits', {
      'title': 'Read 30 Mins',
      'created_at': '2026-10-01T08:00:00.000',
      'category': 'Study',
      'color_value': 0xFFD97706,
    });

    final habit2Id = await v2Db.insert('habits', {
      'title': 'Drink 2L Water',
      'created_at': '2026-10-05T09:30:00.000',
      'category': 'Health',
      'color_value': 0xFF059669,
    });

    // Insert 12 completion logs across 2 habits
    final logDatesH1 = [
      '2026-10-10',
      '2026-10-11',
      '2026-10-12',
      '2026-10-13',
      '2026-10-14',
      '2026-10-15',
      '2026-10-16',
    ];
    for (final d in logDatesH1) {
      await v2Db.insert('habit_logs', {
        'habit_id': habit1Id,
        'completed_date': d,
      });
    }

    final logDatesH2 = [
      '2026-10-12',
      '2026-10-13',
      '2026-10-14',
      '2026-10-15',
      '2026-10-16',
    ];
    for (final d in logDatesH2) {
      await v2Db.insert('habit_logs', {
        'habit_id': habit2Id,
        'completed_date': d,
      });
    }

    // Verify v2 state before migration
    final v2Habits = await v2Db.query('habits');
    expect(v2Habits.length, 2);
    final v2Logs = await v2Db.query('habit_logs');
    expect(v2Logs.length, 12);

    await v2Db.close();

    // 3. Open database at version 3 with DBHelper migration callbacks
    final v3Db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Execute migration logic
          if (oldVersion < 3) {
            await db.transaction((txn) async {
              await txn.execute(
                'ALTER TABLE habits ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0',
              );

              await txn.execute('''
                CREATE TABLE IF NOT EXISTS xp_ledger (
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

              await txn.execute(
                'CREATE INDEX IF NOT EXISTS idx_xp_ledger_date ON xp_ledger(event_date)',
              );
              await txn.execute(
                'CREATE INDEX IF NOT EXISTS idx_xp_ledger_status ON xp_ledger(status)',
              );
              await txn.execute(
                'CREATE INDEX IF NOT EXISTS idx_xp_ledger_source ON xp_ledger(source_type, source_id)',
              );

              await txn.execute('''
                CREATE TABLE IF NOT EXISTS user_profile (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  hero_name TEXT NOT NULL DEFAULT 'DailyFlow Champion',
                  avatar_id TEXT NOT NULL DEFAULT 'knight_helm',
                  total_xp INTEGER NOT NULL DEFAULT 0,
                  current_level INTEGER NOT NULL DEFAULT 1,
                  created_at TEXT NOT NULL
                )
              ''');

              await txn.execute('''
                CREATE TABLE IF NOT EXISTS achievements (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  badge_key TEXT NOT NULL UNIQUE,
                  current_progress INTEGER NOT NULL DEFAULT 0,
                  is_unlocked INTEGER NOT NULL DEFAULT 0,
                  unlocked_at TEXT
                )
              ''');

              final nowStr = DateTime.now().toIso8601String();

              for (final def in Achievement.definitions.values) {
                await txn.insert('achievements', {
                  'badge_key': def.key,
                  'current_progress': 0,
                  'is_unlocked': 0,
                  'unlocked_at': null,
                }, conflictAlgorithm: ConflictAlgorithm.ignore);
              }

              // Backfill
              final existingLogs = await txn.rawQuery('''
                SELECT habit_id, completed_date FROM habit_logs ORDER BY completed_date ASC
              ''');

              for (final row in existingLogs) {
                final hId = row['habit_id'] as int;
                final date = row['completed_date'] as String;
                await txn.insert('xp_ledger', {
                  'source_type': 'HABIT_CHECKIN',
                  'source_id': hId,
                  'event_date': date,
                  'xp_amount': GamificationMath.baseCheckinXp,
                  'status': 'ACTIVE',
                  'created_at': nowStr,
                }, conflictAlgorithm: ConflictAlgorithm.ignore);
              }

              final xpSumResult = await txn.rawQuery('''
                SELECT COALESCE(SUM(xp_amount), 0) as total FROM xp_ledger WHERE status = 'ACTIVE'
              ''');
              final totalXp = xpSumResult.isNotEmpty
                  ? (xpSumResult.first['total'] as int? ?? 0)
                  : 0;
              final startingLevel = GamificationMath.calculateLevel(totalXp);

              await txn.insert('user_profile', {
                'hero_name': 'DailyFlow Champion',
                'avatar_id': 'knight_helm',
                'total_xp': totalXp,
                'current_level': startingLevel,
                'created_at': nowStr,
              });
            });
          }
        },
      ),
    );

    DBHelper.setTestDatabase(v3Db);
    final habitRepo = SqliteHabitRepository();
    final gamificationRepo = SqliteGamificationRepository();

    // 4. Verify original habits are intact and have isArchived = false
    final habits = await habitRepo.getHabits();
    expect(habits.length, 2);
    expect(habits.any((h) => h.title == 'Read 30 Mins'), isTrue);
    expect(habits.any((h) => h.title == 'Drink 2L Water'), isTrue);
    expect(habits.first.isArchived, isFalse);

    // 5. Verify historical XP backfill
    // 12 completions * 20 XP = 240 XP
    final totalXp = await gamificationRepo.getTotalActiveXp();
    expect(totalXp, 240);

    // 240 XP is Level 2 (264 XP is required for Level 3)
    final profile = await gamificationRepo.getUserProfile();
    expect(profile.totalXp, 240);
    expect(profile.currentLevel, 2);
    expect(profile.rankTitle, 'Novice Wanderer');

    // 6. Verify Foreign Key Cascade on deletion
    await habitRepo.deleteHabit(habit1Id);

    // Remaining habits should be 1
    final remainingHabits = await habitRepo.getHabits();
    expect(remainingHabits.length, 1);
    expect(remainingHabits.first.id, habit2Id);

    // habit_logs for habit1Id should be cascaded and deleted
    final remainingLogs = await v3Db.query(
      'habit_logs',
      where: 'habit_id = ?',
      whereArgs: [habit1Id],
    );
    expect(remainingLogs.isEmpty, isTrue);

    // 7. Verify restart persistence: close and re-open v3 database
    await v3Db.close();

    final reopenedDb = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );
    DBHelper.setTestDatabase(reopenedDb);

    final persistentProfile = await gamificationRepo.getUserProfile();
    expect(persistentProfile.totalXp, 240);
    expect(persistentProfile.currentLevel, 2);

    final persistentHabits = await habitRepo.getHabits();
    expect(persistentHabits.length, 1);
    expect(persistentHabits.first.title, 'Drink 2L Water');

    await reopenedDb.close();
  });
}
