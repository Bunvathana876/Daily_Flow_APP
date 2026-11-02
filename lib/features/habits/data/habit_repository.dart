import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/gamification_math.dart';
import '../../gamification/models/xp_entry.dart';
import '../models/habit.dart';

abstract class HabitRepository {
  Future<List<Habit>> getHabits();
  Future<Habit> createHabit({
    required String title,
    required String category,
    required int colorValue,
  });
  Future<void> updateHabit({
    required int id,
    required String title,
    String? category,
    int? colorValue,
    bool? isArchived,
  });
  Future<void> deleteHabit(int id);
  Future<void> toggleHabitLog({
    required int habitId,
    required String dateStr,
    required bool isCompleted,
  });
  Future<void> restoreHabit(Habit habit);
}

class SqliteHabitRepository implements HabitRepository {
  final DBHelper _dbHelper;

  SqliteHabitRepository([DBHelper? dbHelper])
    : _dbHelper = dbHelper ?? DBHelper.instance;

  @override
  Future<List<Habit>> getHabits() async {
    final db = await _dbHelper.database;
    final habitRows = await db.query('habits', orderBy: 'id DESC');
    final logRows = await db.query('habit_logs');

    final Map<int, Set<String>> logsByHabit = {};
    for (final row in logRows) {
      final habitId = row['habit_id'] as int;
      final date = row['completed_date'] as String;
      logsByHabit.putIfAbsent(habitId, () => <String>{}).add(date);
    }

    return habitRows.map((row) {
      final id = row['id'] as int;
      return Habit(
        id: id,
        title: row['title'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        completedDates: logsByHabit[id] ?? <String>{},
        category: (row['category'] as String?) ?? 'General',
        colorValue: (row['color_value'] as int?) ?? 0xFF4F46E5,
        isArchived: (row['is_archived'] as int? ?? 0) == 1,
      );
    }).toList();
  }

  @override
  Future<Habit> createHabit({
    required String title,
    required String category,
    required int colorValue,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final id = await db.insert('habits', {
      'title': title.trim(),
      'created_at': now.toIso8601String(),
      'category': category,
      'color_value': colorValue,
      'is_archived': 0,
    });

    return Habit(
      id: id,
      title: title.trim(),
      createdAt: now,
      completedDates: {},
      category: category,
      colorValue: colorValue,
      isArchived: false,
    );
  }

  @override
  Future<void> updateHabit({
    required int id,
    required String title,
    String? category,
    int? colorValue,
    bool? isArchived,
  }) async {
    final db = await _dbHelper.database;
    final updateData = <String, dynamic>{'title': title.trim()};
    if (category != null) updateData['category'] = category;
    if (colorValue != null) updateData['color_value'] = colorValue;
    if (isArchived != null) updateData['is_archived'] = isArchived ? 1 : 0;

    await db.update('habits', updateData, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteHabit(int id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('habits', where: 'id = ?', whereArgs: [id]);
      await txn.delete('habit_logs', where: 'habit_id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<void> toggleHabitLog({
    required int habitId,
    required String dateStr,
    required bool isCompleted,
  }) async {
    if (!AppDateUtils.isToday(dateStr)) {
      throw ArgumentError(
        'Habits can only be checked or unchecked for today (${AppDateUtils.todayString}). Attempted date: $dateStr',
      );
    }

    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      if (isCompleted) {
        // User unchecking habit: delete log and revoke XP
        await txn.delete(
          'habit_logs',
          where: 'habit_id = ? AND completed_date = ?',
          whereArgs: [habitId, dateStr],
        );

        await txn.update(
          'xp_ledger',
          {'status': XpStatus.revoked},
          where: 'source_type = ? AND source_id = ? AND event_date = ?',
          whereArgs: [XpSourceType.habitCheckin, habitId, dateStr],
        );
      } else {
        // User checking habit: insert log and award/reactivate XP
        await txn.insert('habit_logs', {
          'habit_id': habitId,
          'completed_date': dateStr,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        // Check if ledger entry already exists (anti-farming protection)
        final existing = await txn.query(
          'xp_ledger',
          where: 'source_type = ? AND source_id = ? AND event_date = ?',
          whereArgs: [XpSourceType.habitCheckin, habitId, dateStr],
        );

        if (existing.isNotEmpty) {
          // Reactivate existing reward without granting duplicate XP
          await txn.update(
            'xp_ledger',
            {'status': XpStatus.active},
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        } else {
          // First time check-in for this date
          final allDates = await txn.query(
            'habit_logs',
            columns: ['completed_date'],
            where: 'habit_id = ?',
            whereArgs: [habitId],
          );
          final dateSet = allDates
              .map((r) => r['completed_date'] as String)
              .toSet();
          final streak = AppDateUtils.calculateStreak(dateSet);
          final xp = GamificationMath.calculateCheckinXp(streak);

          await txn.insert('xp_ledger', {
            'source_type': XpSourceType.habitCheckin,
            'source_id': habitId,
            'event_date': dateStr,
            'xp_amount': xp,
            'status': XpStatus.active,
            'created_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      // Keep user_profile in sync atomically
      final sumResult = await txn.rawQuery(
        "SELECT COALESCE(SUM(xp_amount), 0) as total FROM xp_ledger WHERE status = 'ACTIVE'",
      );
      final newTotalXp = sumResult.isNotEmpty
          ? (sumResult.first['total'] as int? ?? 0)
          : 0;
      final newLevel = GamificationMath.calculateLevel(newTotalXp);

      await txn.update('user_profile', {
        'total_xp': newTotalXp,
        'current_level': newLevel,
      });
    });
  }

  @override
  Future<void> restoreHabit(Habit habit) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final habitMap = <String, dynamic>{
        'title': habit.title,
        'created_at': habit.createdAt.toIso8601String(),
        'category': habit.category,
        'color_value': habit.colorValue,
        'is_archived': habit.isArchived ? 1 : 0,
      };
      if (habit.id != null) {
        habitMap['id'] = habit.id;
      }
      final newId = await txn.insert('habits', habitMap);
      final habitId = habit.id ?? newId;

      for (final dateStr in habit.completedDates) {
        await txn.insert('habit_logs', {
          'habit_id': habitId,
          'completed_date': dateStr,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        final existing = await txn.query(
          'xp_ledger',
          where: 'source_type = ? AND source_id = ? AND event_date = ?',
          whereArgs: [XpSourceType.habitCheckin, habitId, dateStr],
        );
        if (existing.isNotEmpty) {
          await txn.update(
            'xp_ledger',
            {'status': XpStatus.active},
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        } else {
          await txn.insert('xp_ledger', {
            'source_type': XpSourceType.habitCheckin,
            'source_id': habitId,
            'event_date': dateStr,
            'xp_amount': GamificationMath.baseCheckinXp,
            'status': XpStatus.active,
            'created_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      final sumResult = await txn.rawQuery(
        "SELECT COALESCE(SUM(xp_amount), 0) as total FROM xp_ledger WHERE status = 'ACTIVE'",
      );
      final newTotalXp = sumResult.isNotEmpty
          ? (sumResult.first['total'] as int? ?? 0)
          : 0;
      final newLevel = GamificationMath.calculateLevel(newTotalXp);

      await txn.update('user_profile', {
        'total_xp': newTotalXp,
        'current_level': newLevel,
      });
    });
  }
}

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return SqliteHabitRepository();
});
