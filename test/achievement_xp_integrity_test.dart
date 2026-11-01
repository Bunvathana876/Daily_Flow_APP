import 'dart:io';
import 'package:daily_flow/core/database/db_helper.dart';
import 'package:daily_flow/core/utils/date_utils.dart';
import 'package:daily_flow/features/gamification/data/gamification_repository.dart';
import 'package:daily_flow/features/gamification/models/achievement.dart';
import 'package:daily_flow/features/gamification/models/xp_entry.dart';
import 'package:daily_flow/features/habits/models/habit.dart';
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
  late DBHelper dbHelper;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'achievement_integrity_test_',
    );
    dbPath = p.join(tempDir.path, 'integrity_test.db');
    dbHelper = DBHelper.instance;
    DBHelper.setTestDatabase(null);
  });

  tearDown(() async {
    final db = await dbHelper.database;
    await db.close();
    DBHelper.setTestDatabase(null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Achievement Deterministic ID Integrity Tests', () {
    test(
      'all 10 achievement definitions have unique, stable, deterministic IDs',
      () {
        final ids = <int>{};
        for (final def in Achievement.definitions.values) {
          expect(def.deterministicId, isPositive);
          expect(
            ids.contains(def.deterministicId),
            isFalse,
            reason: 'Deterministic ID ${def.deterministicId} must be unique',
          );
          ids.add(def.deterministicId);

          // Verify Achievement.deterministicIdFor matches definition
          expect(Achievement.deterministicIdFor(def.key), def.deterministicId);
        }
        expect(ids.length, 10);
      },
    );

    test(
      'reconciles legacy runtime hashCode to deterministic persistent ID',
      () async {
        final testDb = await databaseFactory.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(
            version: 3,
            onCreate: (db, version) async {
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
            },
          ),
        );

        // Insert legacy row with runtime hashCode
        final legacyHash = 'flame_keeper'.hashCode.abs();
        await testDb.insert('xp_ledger', {
          'source_type': 'ACHIEVEMENT',
          'source_id': legacyHash,
          'event_date': AppDateUtils.todayString,
          'xp_amount': 100,
          'status': 'ACTIVE',
          'created_at': DateTime.now().toIso8601String(),
        });
        await testDb.insert('achievements', {
          'badge_key': 'flame_keeper',
          'current_progress': 7,
          'is_unlocked': 1,
          'unlocked_at': DateTime.now().toIso8601String(),
        });

        // Verify row before migration
        final beforeRows = await testDb.query(
          'xp_ledger',
          where: 'source_type = ? AND source_id = ?',
          whereArgs: ['ACHIEVEMENT', legacyHash],
        );
        expect(beforeRows.length, 1);

        // Run non-destructive reconciliation
        await DBHelper.reconcileLegacyAchievementXp(testDb);

        // Verify legacy row is migrated to deterministic ID 1002
        final deterministicId = Achievement.deterministicIdFor('flame_keeper');
        expect(deterministicId, 1002);

        final legacyAfter = await testDb.query(
          'xp_ledger',
          where: 'source_type = ? AND source_id = ?',
          whereArgs: ['ACHIEVEMENT', legacyHash],
        );
        expect(legacyAfter, isEmpty);

        final migratedRows = await testDb.query(
          'xp_ledger',
          where: 'source_type = ? AND source_id = ?',
          whereArgs: ['ACHIEVEMENT', deterministicId],
        );
        expect(migratedRows.length, 1);
        expect(migratedRows.first['xp_amount'], 100);

        await testDb.close();
      },
    );

    test(
      'evaluates achievements idempotently and prevents duplicate XP across simulated restarts',
      () async {
        // 1. Initialize DB through DBHelper
        final db = await databaseFactory.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(
            version: 4,
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
              for (final def in Achievement.definitions.values) {
                await db.insert('achievements', {
                  'badge_key': def.key,
                  'current_progress': 0,
                  'is_unlocked': 0,
                  'unlocked_at': null,
                });
              }
              await db.insert('user_profile', {
                'hero_name': 'DailyFlow Champion',
                'avatar_id': 'knight_helm',
                'total_xp': 0,
                'current_level': 1,
                'created_at': DateTime.now().toIso8601String(),
              });
            },
          ),
        );
        DBHelper.setTestDatabase(db);

        final repo = SqliteGamificationRepository(dbHelper);

        final habits = [
          Habit(
            id: 1,
            title: 'Daily Meditation',
            category: 'Mindfulness',
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

        // First evaluation unlocks first_spark and flame_keeper
        await repo.evaluateAndSyncAchievements(habits: habits);

        final profileAfterFirst = await repo.getUserProfile();
        final xpRowsFirst = await db.query(
          'xp_ledger',
          where: 'source_type = ?',
          whereArgs: [XpSourceType.achievement],
        );

        // Should have 2 achievements unlocked: first_spark (50 XP) and flame_keeper (100 XP)
        expect(xpRowsFirst.length, 2);
        expect(profileAfterFirst.totalXp, 150);

        // Verify deterministic persistent IDs are stored in ledger
        final sourceIds = xpRowsFirst.map((r) => r['source_id'] as int).toSet();
        expect(sourceIds, {1001, 1002});

        // Simulate app restart / repeated sync evaluations
        for (int i = 0; i < 5; i++) {
          await repo.evaluateAndSyncAchievements(habits: habits);
        }

        final xpRowsRepeated = await db.query(
          'xp_ledger',
          where: 'source_type = ?',
          whereArgs: [XpSourceType.achievement],
        );
        final profileAfterRepeated = await repo.getUserProfile();

        // Ledger count and total XP must be strictly unchanged
        expect(xpRowsRepeated.length, 2);
        expect(profileAfterRepeated.totalXp, 150);

        // Test getXpBreakdown
        final breakdown = await repo.getXpBreakdown();
        expect(breakdown[XpSourceType.achievement], 150);
      },
    );

    test(
      'v3-to-v4 upgrade reconciles arbitrary legacy hash fixture without duplicating XP',
      () async {
        // 1. Simulate an older build (v3) with arbitrary runtime hash code 888777666 in xp_ledger
        const arbitraryLegacyHash = 888777666;
        final v3Db = await databaseFactory.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(
            version: 3,
            onCreate: (db, version) async {
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
            },
          ),
        );

        // Insert older build record: flame_keeper (100 XP) unlocked with arbitrary legacy hash
        await v3Db.insert('xp_ledger', {
          'source_type': 'ACHIEVEMENT',
          'source_id': arbitraryLegacyHash,
          'event_date': '2026-10-20',
          'xp_amount': 100,
          'status': 'ACTIVE',
          'created_at': '2026-10-20T10:00:00.000',
        });
        await v3Db.insert('achievements', {
          'badge_key': 'flame_keeper',
          'current_progress': 7,
          'is_unlocked': 1,
          'unlocked_at': '2026-10-20T10:00:00.000',
        });
        await v3Db.insert('user_profile', {
          'hero_name': 'Seasoned Hero',
          'avatar_id': 'paladin_crest',
          'total_xp': 100,
          'current_level': 1,
          'created_at': '2026-10-20T10:00:00.000',
        });

        // 2. Perform v3 to v4 upgrade reconciliation
        await DBHelper.reconcileLegacyAchievementXp(v3Db);

        // Verify the legacy hash row was migrated to flame_keeper's deterministic ID 1002
        final migratedRows = await v3Db.query(
          'xp_ledger',
          where: 'source_type = ?',
          whereArgs: ['ACHIEVEMENT'],
        );
        expect(migratedRows.length, 1);
        expect(migratedRows.first['source_id'], 1002);
        expect(migratedRows.first['xp_amount'], 100);

        // 3. Re-open through SqliteGamificationRepository and evaluate
        DBHelper.setTestDatabase(v3Db);
        final repo = SqliteGamificationRepository(dbHelper);

        final habits = [
          Habit(
            id: 1,
            title: 'Daily Streak Habit',
            category: 'Streaks',
            createdAt: DateTime.now(),
            completedDates: {
              '2026-10-20',
              '2026-10-21',
              '2026-10-22',
              '2026-10-23',
              '2026-10-24',
              '2026-10-25',
              '2026-10-26',
            },
          ),
        ];

        // Re-evaluating must NOT grant duplicate XP for flame_keeper
        await repo.evaluateAndSyncAchievements(habits: habits);

        final finalRows = await v3Db.query(
          'xp_ledger',
          where: 'source_type = ? AND source_id = ?',
          whereArgs: ['ACHIEVEMENT', 1002],
        );
        expect(finalRows.length, 1); // Strictly single entry
      },
    );
  });
}
