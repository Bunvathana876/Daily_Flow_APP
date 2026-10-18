import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_utils.dart';
import '../controllers/habit_controller.dart';
import '../models/habit.dart';
import 'widgets/habit_form_dialog.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final int habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  void _showEditDialog(Habit habit) {
    HabitFormDialog.show(
      context,
      habit: habit,
      onSave: (title, category, colorValue) {
        ref.read(habitControllerProvider.notifier).editHabit(
              habit.id!,
              title,
              category: category,
              colorValue: colorValue,
            );
      },
    );
  }

  void _confirmDelete(Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              ref.read(habitControllerProvider.notifier).deleteHabit(habit.id!);
              Navigator.pop(context); // Pop detail screen
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Habit "${habit.title}" deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ref.read(habitControllerProvider.notifier).restoreHabit(habit);
                    },
                  ),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final habitIndex = habits.indexWhere((h) => h.id == widget.habitId);
    if (habitIndex == -1) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Habit not found')),
      );
    }
    final habit = habits[habitIndex];
    final accentColor = Color(habit.colorValue);

    final currentStreak = habit.currentStreak;
    final bestStreak = habit.bestStreak;
    final totalDays = habit.totalCompletions;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          habit.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Habit',
            onPressed: () => _showEditDialog(habit),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Habit',
            onPressed: () => _confirmDelete(habit),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Header badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    habit.category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Created ${DateFormat.yMMMd().format(habit.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top Stat Cards Row
            Row(
              children: [
                Expanded(
                  child: _DetailStatCard(
                    title: 'Current Streak',
                    value: '$currentStreak d',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.deepOrange,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DetailStatCard(
                    title: 'Best Streak',
                    value: '$bestStreak d',
                    icon: Icons.emoji_events_rounded,
                    iconColor: Colors.amber.shade700,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DetailStatCard(
                    title: 'Total Days',
                    value: '$totalDays',
                    icon: Icons.check_circle_rounded,
                    iconColor: accentColor,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Monthly Calendar Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Month navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () {
                          setState(() {
                            _displayedMonth = DateTime(
                              _displayedMonth.year,
                              _displayedMonth.month - 1,
                              1,
                            );
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_displayedMonth),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () {
                          setState(() {
                            _displayedMonth = DateTime(
                              _displayedMonth.year,
                              _displayedMonth.month + 1,
                              1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Weekday Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                        .map(
                          (day) => SizedBox(
                            width: 36,
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Calendar Days Grid
                  _buildCalendarGrid(habit, accentColor, isDark),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(Habit habit, Color accentColor, bool isDark) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1 = Mon, 7 = Sun
    final leadingBlanks = firstWeekday - 1;

    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    final totalCells = leadingBlanks + daysInMonth;
    final rowsCount = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rowsCount, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              if (cellIndex < leadingBlanks || cellIndex >= totalCells) {
                return const SizedBox(width: 36, height: 36);
              }
              final dayNumber = cellIndex - leadingBlanks + 1;
              final dayDate = DateTime(year, month, dayNumber);
              final dateStr = AppDateUtils.formatDate(dayDate);
              final isToday = dayDate == todayNormalized;
              final isFuture = dayDate.isAfter(todayNormalized);
              final isCompleted = habit.completedDates.contains(dateStr);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isFuture
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(habitControllerProvider.notifier)
                            .toggleHabitOnDate(habit, dateStr);
                      },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? accentColor
                        : (isToday
                            ? accentColor.withValues(alpha: 0.1)
                            : Colors.transparent),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isToday
                          ? accentColor
                          : (isCompleted
                              ? accentColor
                              : (isDark
                                  ? Colors.white10
                                  : Colors.grey.shade200)),
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            (isToday || isCompleted) ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted
                            ? Colors.white
                            : (isFuture
                                ? (isDark ? Colors.white24 : Colors.grey.shade400)
                                : (isDark ? Colors.white : Colors.black87)),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _DetailStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

