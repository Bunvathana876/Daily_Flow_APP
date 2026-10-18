import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_provider.dart';
import '../controllers/habit_controller.dart';
import '../models/habit.dart';
import 'habit_detail_screen.dart';
import 'widgets/habit_form_dialog.dart';
import 'widgets/habit_tile.dart';
import 'widgets/weekly_overview_card.dart';

const availableCategories = AppConstants.allCategories;
const habitCategories = AppConstants.habitCategories;
const availableColors = AppConstants.availableColors;

class CategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void select(String category) => state = category;
}

final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, String>(CategoryFilterNotifier.new);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showHabitDialog(BuildContext context, WidgetRef ref, {Habit? habit}) {
    HabitFormDialog.show(
      context,
      habit: habit,
      onSave: (title, category, colorValue) {
        if (habit == null) {
          ref.read(habitControllerProvider.notifier).addHabit(
                title,
                category: category,
                colorValue: colorValue,
              );
        } else {
          ref.read(habitControllerProvider.notifier).editHabit(
                habit.id!,
                title,
                category: category,
                colorValue: colorValue,
              );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitControllerProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayedHabits = selectedCategory == 'All'
        ? habits
        : habits.where((h) => h.category == selectedCategory).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'DailyFlow',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WeeklyOverviewCard(habits: habits),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: availableCategories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = availableCategories[index];
                  final isSelected = selectedCategory == category;
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      ref
                          .read(categoryFilterProvider.notifier)
                          .select(category);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Habits",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (selectedCategory != 'All')
                  Text(
                    '${displayedHabits.length} habits',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: displayedHabits.isEmpty
                  ? Center(
                      child: Text(
                        habits.isEmpty
                            ? 'No habits yet. Tap + to start your streak!'
                            : 'No habits found in "$selectedCategory".',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: displayedHabits.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final habit = displayedHabits[index];
                        return HabitTile(
                          habit: habit,
                          onDetailTap: () {
                            if (habit.id != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HabitDetailScreen(
                                    habitId: habit.id!,
                                  ),
                                ),
                              );
                            }
                          },
                          onToggle: () => ref
                              .read(habitControllerProvider.notifier)
                              .toggleHabitForToday(habit),
                          onToggleDate: (dateStr) => ref
                              .read(habitControllerProvider.notifier)
                              .toggleHabitOnDate(habit, dateStr),
                          onEdit: () =>
                              _showHabitDialog(context, ref, habit: habit),
                          onDelete: () {
                            final deletedHabit = habit;
                            ref
                                .read(habitControllerProvider.notifier)
                                .deleteHabit(deletedHabit.id!);

                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Habit "${deletedHabit.title}" deleted'),
                                duration: const Duration(seconds: 4),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    ref
                                        .read(habitControllerProvider.notifier)
                                        .restoreHabit(deletedHabit);
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showHabitDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Habit'),
      ),
    );
  }
}
