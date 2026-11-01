import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/gamification_math.dart';
import '../../features/gamification/models/achievement.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  /// Allows unit and integration tests to inject an in-memory or custom Database instance.
  static void setTestDatabase(Database? db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('daily_flow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
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

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_xp_ledger_date ON xp_ledger(event_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_xp_ledger_status ON xp_ledger(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_xp_ledger_source ON xp_ledger(source_type, source_id)',
    );

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

    final nowStr = DateTime.now().toIso8601String();

    await db.insert('user_profile', {
      'hero_name': 'DailyFlow Champion',
      'avatar_id': 'knight_helm',
      'total_xp': 0,
      'current_level': 1,
      'created_at': nowStr,
    });

    for (final def in Achievement.definitions.values) {
      await db.insert('achievements', {
        'badge_key': def.key,
        'current_progress': 0,
        'is_unlocked': 0,
        'unlocked_at': null,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE habits ADD COLUMN category TEXT NOT NULL DEFAULT 'General'",
      );
      await db.execute(
        "ALTER TABLE habits ADD COLUMN color_value INTEGER NOT NULL DEFAULT 4283385573",
      );
    }

    if (oldVersion < 3) {
      await db.transaction((txn) async {
        // 1. Add is_archived column if missing
        try {
          await txn.execute(
            'ALTER TABLE habits ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0',
          );
        } catch (_) {
          // Column might already exist if table was partially migrated
        }

        // 2. Create xp_ledger table
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

        // 3. Create user_profile table
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

        // 4. Create achievements table
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

        // 5. Seed default achievements
        for (final def in Achievement.definitions.values) {
          await txn.insert('achievements', {
            'badge_key': def.key,
            'current_progress': 0,
            'is_unlocked': 0,
            'unlocked_at': null,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }

        // 6. Backfill historical XP from existing habit_logs
        final existingLogs = await txn.rawQuery('''
          SELECT habit_id, completed_date FROM habit_logs ORDER BY completed_date ASC
        ''');

        for (final row in existingLogs) {
          final habitId = row['habit_id'] as int;
          final date = row['completed_date'] as String;
          const checkinXp = GamificationMath.baseCheckinXp;

          await txn.insert('xp_ledger', {
            'source_type': 'HABIT_CHECKIN',
            'source_id': habitId,
            'event_date': date,
            'xp_amount': checkinXp,
            'status': 'ACTIVE',
            'created_at': nowStr,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }

        // 7. Calculate total historical XP and starting level
        final xpSumResult = await txn.rawQuery('''
          SELECT COALESCE(SUM(xp_amount), 0) as total FROM xp_ledger WHERE status = 'ACTIVE'
        ''');
        final totalXp = xpSumResult.isNotEmpty
            ? (xpSumResult.first['total'] as int? ?? 0)
            : 0;
        final startingLevel = GamificationMath.calculateLevel(totalXp);

        // 8. Insert or replace user profile
        final existingProfiles = await txn.query('user_profile');
        if (existingProfiles.isEmpty) {
          await txn.insert('user_profile', {
            'hero_name': 'DailyFlow Champion',
            'avatar_id': 'knight_helm',
            'total_xp': totalXp,
            'current_level': startingLevel,
            'created_at': nowStr,
          });
        } else {
          await txn.update(
            'user_profile',
            {'total_xp': totalXp, 'current_level': startingLevel},
            where: 'id = ?',
            whereArgs: [existingProfiles.first['id']],
          );
        }
      });
    }

    if (oldVersion < 4) {
      await reconcileLegacyAchievementXp(db);
    }
  }

  /// Reconciles any legacy runtime hash codes stored in `xp_ledger` to deterministic persistent IDs.
  static Future<void> reconcileLegacyAchievementXp(DatabaseExecutor db) async {
    // Pass 1: Direct match by runtime hash code for known definitions
    for (final entry in Achievement.definitions.entries) {
      final badgeKey = entry.key;
      final deterministicId = entry.value.deterministicId;
      final legacyHashCode = badgeKey.hashCode.abs();

      // Non-destructive update: migrate legacy runtime hashCode to permanent deterministicId
      await db.update(
        'xp_ledger',
        {'source_id': deterministicId},
        where: 'source_type = ? AND source_id = ?',
        whereArgs: ['ACHIEVEMENT', legacyHashCode],
      );
    }

    // Pass 2: Cross-platform fallback: for any unlocked achievement whose deterministicId
    // is not yet in xp_ledger, reconcile legacy rows with non-deterministic source_id.
    try {
      final unlockedRows = await db.query(
        'achievements',
        where: 'is_unlocked = ?',
        whereArgs: [1],
      );

      for (final row in unlockedRows) {
        final badgeKey = row['badge_key'] as String;
        final def = Achievement.definitions[badgeKey];
        if (def == null) continue;

        final deterministicId = def.deterministicId;

        final alreadyPresent = await db.query(
          'xp_ledger',
          where: 'source_type = ? AND source_id = ?',
          whereArgs: ['ACHIEVEMENT', deterministicId],
        );

        if (alreadyPresent.isEmpty) {
          final legacyRows = await db.rawQuery(
            '''
            SELECT id FROM xp_ledger
            WHERE source_type = 'ACHIEVEMENT'
              AND status = 'ACTIVE'
              AND (source_id < 1001 OR source_id > 1010)
              AND xp_amount = ?
            LIMIT 1
          ''',
            [def.xpReward],
          );

          if (legacyRows.isNotEmpty) {
            final rowId = legacyRows.first['id'] as int;
            await db.update(
              'xp_ledger',
              {'source_id': deterministicId},
              where: 'id = ?',
              whereArgs: [rowId],
            );
          }
        }
      }
    } catch (_) {
      // Safe non-blocking fallback if achievements table is empty
    }
  }
}
