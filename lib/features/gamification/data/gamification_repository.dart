import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/gamification_math.dart';
import '../../habits/models/habit.dart';
import '../models/achievement.dart';
import '../models/user_profile.dart';
import '../models/xp_entry.dart';

abstract class GamificationRepository {
  Future<UserProfile> getUserProfile();
  Future<void> updateUserProfile({String? heroName, String? avatarId});
  Future<List<XpEntry>> getXpEntries({int limit = 50, int offset = 0});
  Future<int> getTotalActiveXp();
  Future<int> getCurrentLevel();
  Future<int> getTotalFocusMinutes();
  Future<int> getTotalFocusSessions();
  Future<int> awardHabitCheckin({
    required int habitId,
    required String dateStr,
    required int currentStreak,
  });
  Future<int> revokeHabitCheckin({
    required int habitId,
    required String dateStr,
  });
  Future<int> awardFocusSession({
    required int durationMinutes,
    int? habitId,
    required String dateStr,
  });
  Future<List<Achievement>> getAchievements();
  Future<void> updateAchievementProgress(String badgeKey, int progress);
  Future<bool> unlockAchievement(String badgeKey);
  Future<List<Achievement>> evaluateAndSyncAchievements({
    required List<Habit> habits,
  });
  Future<Map<String, int>> getXpBreakdown();
  Future<void> recalculateTotalXpAndLevel();
}

class SqliteGamificationRepository implements GamificationRepository {
  final DBHelper _dbHelper;

  SqliteGamificationRepository([DBHelper? dbHelper])
    : _dbHelper = dbHelper ?? DBHelper.instance;

  @override
  Future<UserProfile> getUserProfile() async {
    final db = await _dbHelper.database;
    final rows = await db.query('user_profile', limit: 1);
    if (rows.isEmpty) {
      final nowStr = DateTime.now().toIso8601String();
      final id = await db.insert('user_profile', {
        'hero_name': 'DailyFlow Champion',
        'avatar_id': 'knight_helm',
        'total_xp': 0,
        'current_level': 1,
        'created_at': nowStr,
      });
      return UserProfile(
        id: id,
        heroName: 'DailyFlow Champion',
        avatarId: 'knight_helm',
        totalXp: 0,
        currentLevel: 1,
        createdAt: DateTime.now(),
      );
    }
    return UserProfile.fromMap(rows.first);
  }

  @override
  Future<void> updateUserProfile({String? heroName, String? avatarId}) async {
    final db = await _dbHelper.database;
    final updateData = <String, dynamic>{};
    if (heroName != null) updateData['hero_name'] = heroName.trim();
    if (avatarId != null) updateData['avatar_id'] = avatarId;

    if (updateData.isNotEmpty) {
      await db.update('user_profile', updateData);
    }
  }

  @override
  Future<List<XpEntry>> getXpEntries({int limit = 50, int offset = 0}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'xp_ledger',
      orderBy: 'event_date DESC, id DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map((r) => XpEntry.fromMap(r)).toList();
  }

  @override
  Future<int> getTotalActiveXp() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(xp_amount), 0) as total FROM xp_ledger WHERE status = 'ACTIVE'",
    );
    return result.isNotEmpty ? (result.first['total'] as int? ?? 0) : 0;
  }

  @override
  Future<int> getCurrentLevel() async {
    final totalXp = await getTotalActiveXp();
    return GamificationMath.calculateLevel(totalXp);
  }

  @override
  Future<int> awardHabitCheckin({
    required int habitId,
    required String dateStr,
    required int currentStreak,
  }) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      final existing = await txn.query(
        'xp_ledger',
        where: 'source_type = ? AND source_id = ? AND event_date = ?',
        whereArgs: [XpSourceType.habitCheckin, habitId, dateStr],
      );

      int awardedXp = 0;
      if (existing.isNotEmpty) {
        final entry = existing.first;
        final currentStatus = entry['status'] as String;
        awardedXp = entry['xp_amount'] as int;

        if (currentStatus == XpStatus.revoked) {
          await txn.update(
            'xp_ledger',
            {'status': XpStatus.active},
            where: 'id = ?',
            whereArgs: [entry['id']],
          );
        }
      } else {
        awardedXp = GamificationMath.calculateCheckinXp(currentStreak);
        await txn.insert('xp_ledger', {
          'source_type': XpSourceType.habitCheckin,
          'source_id': habitId,
          'event_date': dateStr,
          'xp_amount': awardedXp,
          'status': XpStatus.active,
          'created_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      await _syncProfileInTxn(txn);
      return awardedXp;
    });
  }

  @override
  Future<int> revokeHabitCheckin({
    required int habitId,
    required String dateStr,
  }) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      final existing = await txn.query(
        'xp_ledger',
        where: 'source_type = ? AND source_id = ? AND event_date = ?',
        whereArgs: [XpSourceType.habitCheckin, habitId, dateStr],
      );

      int revokedXp = 0;
      if (existing.isNotEmpty) {
        final entry = existing.first;
        if ((entry['status'] as String) == XpStatus.active) {
          revokedXp = entry['xp_amount'] as int;
          await txn.update(
            'xp_ledger',
            {'status': XpStatus.revoked},
            where: 'id = ?',
            whereArgs: [entry['id']],
          );
        }
      }

      await _syncProfileInTxn(txn);
      return revokedXp;
    });
  }

  @override
  Future<int> awardFocusSession({
    required int durationMinutes,
    int? habitId,
    required String dateStr,
  }) async {
    final db = await _dbHelper.database;
    final xp = GamificationMath.calculateFocusSessionXp(durationMinutes);
    if (xp <= 0) return 0;

    int grantedXp = 0;
    await db.transaction((txn) async {
      // Check today's total focus XP to respect daily cap of 180 XP
      final todaysFocus = await txn.rawQuery(
        "SELECT COALESCE(SUM(xp_amount), 0) as total FROM xp_ledger WHERE source_type = ? AND event_date = ? AND status = 'ACTIVE'",
        [XpSourceType.focusSession, dateStr],
      );
      final currentTodayFocusXp = todaysFocus.isNotEmpty
          ? (todaysFocus.first['total'] as int? ?? 0)
          : 0;
      final remainingAllowed = max(
        0,
        GamificationMath.maxFocusSessionXpPerDay - currentTodayFocusXp,
      );

      final grantXp = min(xp, remainingAllowed);
      grantedXp = grantXp;
      if (grantXp > 0) {
        await txn.insert('xp_ledger', {
          'source_type': XpSourceType.focusSession,
          'source_id': habitId,
          'event_date': dateStr,
          'xp_amount': grantXp,
          'status': XpStatus.active,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await _syncProfileInTxn(txn);
    });

    return grantedXp;
  }

  @override
  Future<int> getTotalFocusMinutes() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(xp_amount), 0) as total FROM xp_ledger WHERE source_type = ? AND status = 'ACTIVE'",
      [XpSourceType.focusSession],
    );
    return result.isNotEmpty ? (result.first['total'] as int? ?? 0) : 0;
  }

  @override
  Future<int> getTotalFocusSessions() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM xp_ledger WHERE source_type = ? AND status = 'ACTIVE'",
      [XpSourceType.focusSession],
    );
    return result.isNotEmpty ? (result.first['count'] as int? ?? 0) : 0;
  }

  @override
  Future<List<Achievement>> getAchievements() async {
    final db = await _dbHelper.database;
    final rows = await db.query('achievements', orderBy: 'id ASC');
    return rows.map((r) => Achievement.fromMap(r)).toList();
  }

  @override
  Future<void> updateAchievementProgress(String badgeKey, int progress) async {
    final db = await _dbHelper.database;
    final def = Achievement.definitions[badgeKey];
    if (def == null) return;

    final target = def.targetValue;
    final isNowUnlocked = progress >= target;

    await db.transaction((txn) async {
      final rows = await txn.query(
        'achievements',
        where: 'badge_key = ?',
        whereArgs: [badgeKey],
      );

      final wasUnlocked =
          rows.isNotEmpty && ((rows.first['is_unlocked'] as int? ?? 0) == 1);

      await txn.update(
        'achievements',
        {
          'current_progress': progress,
          'is_unlocked': (wasUnlocked || isNowUnlocked) ? 1 : 0,
          if (!wasUnlocked && isNowUnlocked)
            'unlocked_at': DateTime.now().toIso8601String(),
        },
        where: 'badge_key = ?',
        whereArgs: [badgeKey],
      );

      // If newly unlocked, award achievement XP with deduplication
      if (!wasUnlocked && isNowUnlocked) {
        final deterministicId = Achievement.deterministicIdFor(badgeKey);
        final legacyHashCode = badgeKey.hashCode.abs();

        final existingXp = await txn.query(
          'xp_ledger',
          where: 'source_type = ? AND (source_id = ? OR source_id = ?)',
          whereArgs: [
            XpSourceType.achievement,
            deterministicId,
            legacyHashCode,
          ],
        );

        if (existingXp.isEmpty) {
          await txn.insert('xp_ledger', {
            'source_type': XpSourceType.achievement,
            'source_id': deterministicId,
            'event_date': DateTime.now().toIso8601String().substring(0, 10),
            'xp_amount': def.xpReward,
            'status': XpStatus.active,
            'created_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          await _syncProfileInTxn(txn);
        } else if (existingXp.any(
          (row) => (row['source_id'] as int?) == legacyHashCode,
        )) {
          // Reconcile legacy runtime hashCode to permanent deterministicId
          await txn.update(
            'xp_ledger',
            {'source_id': deterministicId},
            where: 'source_type = ? AND source_id = ?',
            whereArgs: [XpSourceType.achievement, legacyHashCode],
          );
        }
      }
    });
  }

  @override
  Future<Map<String, int>> getXpBreakdown() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT source_type, COALESCE(SUM(xp_amount), 0) as total
      FROM xp_ledger
      WHERE status = 'ACTIVE'
      GROUP BY source_type
    ''');

    final result = <String, int>{
      XpSourceType.habitCheckin: 0,
      XpSourceType.focusSession: 0,
      XpSourceType.achievement: 0,
      XpSourceType.cleanSheet: 0,
    };

    for (final row in rows) {
      final type = row['source_type'] as String?;
      final total = row['total'] as int? ?? 0;
      if (type != null) {
        result[type] = total;
      }
    }
    return result;
  }

  @override
  Future<bool> unlockAchievement(String badgeKey) async {
    final def = Achievement.definitions[badgeKey];
    if (def == null) return false;
    await updateAchievementProgress(badgeKey, def.targetValue);
    return true;
  }

  @override
  Future<List<Achievement>> evaluateAndSyncAchievements({
    required List<Habit> habits,
  }) async {
    final totalCheckins = habits.fold<int>(
      0,
      (sum, h) => sum + h.completedDates.length,
    );
    final bestStreak = habits.isEmpty
        ? 0
        : habits
              .map((h) => AppDateUtils.calculateBestStreak(h.completedDates))
              .fold<int>(0, max);
    final totalHabits = habits.length;
    final distinctCategories = habits.map((h) => h.category).toSet().length;
    final isCleanSheetToday =
        habits.isNotEmpty && habits.every((h) => h.isCompletedToday);

    final focusMinutes = await getTotalFocusMinutes();
    final focusSessions = await getTotalFocusSessions();

    final evaluations = <String, int>{
      'first_spark': totalCheckins,
      'flame_keeper': bestStreak,
      'iron_will': bestStreak,
      'centurion': bestStreak,
      'single_spark': focusSessions,
      'deep_delver': focusMinutes,
      'guild_founder': totalHabits,
      'polymath': distinctCategories,
      'clean_sheet': isCleanSheetToday ? 1 : 0,
      'century_flow': totalCheckins,
    };

    for (final entry in evaluations.entries) {
      await updateAchievementProgress(entry.key, entry.value);
    }

    return await getAchievements();
  }

  @override
  Future<void> recalculateTotalXpAndLevel() async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await _syncProfileInTxn(txn);
    });
  }

  Future<void> _syncProfileInTxn(DatabaseExecutor txn) async {
    final sumResult = await txn.rawQuery(
      "SELECT COALESCE(SUM(xp_amount), 0) as total FROM xp_ledger WHERE status = 'ACTIVE'",
    );
    final totalXp = sumResult.isNotEmpty
        ? (sumResult.first['total'] as int? ?? 0)
        : 0;
    final level = GamificationMath.calculateLevel(totalXp);

    final profiles = await txn.query('user_profile', limit: 1);
    if (profiles.isEmpty) {
      await txn.insert('user_profile', {
        'hero_name': 'DailyFlow Champion',
        'avatar_id': 'knight_helm',
        'total_xp': totalXp,
        'current_level': level,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      await txn.update(
        'user_profile',
        {'total_xp': totalXp, 'current_level': level},
        where: 'id = ?',
        whereArgs: [profiles.first['id']],
      );
    }
  }
}

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return SqliteGamificationRepository();
});
