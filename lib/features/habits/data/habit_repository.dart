import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/db_helper.dart';
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
    });

    return Habit(
      id: id,
      title: title.trim(),
      createdAt: now,
      completedDates: {},
      category: category,
      colorValue: colorValue,
    );
  }

  @override
  Future<void> updateHabit({
    required int id,
    required String title,
    String? category,
    int? colorValue,
  }) async {
    final db = await _dbHelper.database;
    final updateData = <String, dynamic>{'title': title.trim()};
    if (category != null) updateData['category'] = category;
    if (colorValue != null) updateData['color_value'] = colorValue;

    await db.update(
      'habits',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteHabit(int id) async {
    final db = await _dbHelper.database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
    await db.delete('habit_logs', where: 'habit_id = ?', whereArgs: [id]);
  }

  @override
  Future<void> toggleHabitLog({
    required int habitId,
    required String dateStr,
    required bool isCompleted,
  }) async {
    final db = await _dbHelper.database;
    if (isCompleted) {
      await db.delete(
        'habit_logs',
        where: 'habit_id = ? AND completed_date = ?',
        whereArgs: [habitId, dateStr],
      );
    } else {
      await db.insert('habit_logs', {
        'habit_id': habitId,
        'completed_date': dateStr,
      });
    }
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
        });
      }
    });
  }
}

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return SqliteHabitRepository();
});

