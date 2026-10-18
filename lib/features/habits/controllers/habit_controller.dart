import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../data/habit_repository.dart';
import '../models/habit.dart';

class HabitController extends Notifier<List<Habit>> {
  late final HabitRepository _repository;

  @override
  List<Habit> build() {
    _repository = ref.read(habitRepositoryProvider);
    loadHabits();
    return [];
  }

  Future<void> loadHabits() async {
    final habits = await _repository.getHabits();
    state = habits;
  }

  Future<void> addHabit(
    String title, {
    String category = 'General',
    int colorValue = AppConstants.defaultColorValue,
  }) async {
    if (title.trim().isEmpty) return;
    final newHabit = await _repository.createHabit(
      title: title,
      category: category,
      colorValue: colorValue,
    );
    state = [newHabit, ...state];
  }

  Future<void> editHabit(
    int id,
    String newTitle, {
    String? category,
    int? colorValue,
  }) async {
    if (newTitle.trim().isEmpty) return;
    await _repository.updateHabit(
      id: id,
      title: newTitle,
      category: category,
      colorValue: colorValue,
    );

    state = [
      for (final habit in state)
        if (habit.id == id)
          habit.copyWith(
            title: newTitle.trim(),
            category: category ?? habit.category,
            colorValue: colorValue ?? habit.colorValue,
          )
        else
          habit,
    ];
  }

  Future<void> deleteHabit(int id) async {
    await _repository.deleteHabit(id);
    state = state.where((h) => h.id != id).toList();
  }

  Future<void> toggleHabitOnDate(Habit habit, String dateStr) async {
    if (habit.id == null) return;
    final updatedDates = Set<String>.from(habit.completedDates);
    final isCurrentlyCompleted = updatedDates.contains(dateStr);

    await _repository.toggleHabitLog(
      habitId: habit.id!,
      dateStr: dateStr,
      isCompleted: isCurrentlyCompleted,
    );

    if (isCurrentlyCompleted) {
      updatedDates.remove(dateStr);
    } else {
      updatedDates.add(dateStr);
    }

    state = [
      for (final h in state)
        if (h.id == habit.id) h.copyWith(completedDates: updatedDates) else h,
    ];
  }

  Future<void> toggleHabitForToday(Habit habit) =>
      toggleHabitOnDate(habit, Habit.formatDate(DateTime.now()));

  Future<void> restoreHabit(Habit habit) async {
    await _repository.restoreHabit(habit);
    if (!state.any((h) => h.id == habit.id)) {
      state = [habit, ...state];
    }
  }
}

final habitControllerProvider =
    NotifierProvider<HabitController, List<Habit>>(HabitController.new);
