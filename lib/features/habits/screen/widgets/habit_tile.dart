import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/date_utils.dart';
import '../../models/habit.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final void Function(String dateStr) onToggleDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onDetailTap;

  const HabitTile({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onToggleDate,
    required this.onEdit,
    required this.onDelete,
    this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = habit.isCompletedToday;
    final streak = habit.currentStreak;
    final accentColor = Color(habit.colorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayStr = AppDateUtils.todayString;
    final last7Days = AppDateUtils.getLast7DaysWithLabels();

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isDone
              ? (isDark
                  ? accentColor.withValues(alpha: 0.16)
                  : accentColor.withValues(alpha: 0.08))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone
                ? accentColor
                : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              onTap: onDetailTap,
              onLongPress: onEdit,
              leading: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggle();
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    key: ValueKey(isDone),
                    color: isDone
                        ? accentColor
                        : (isDark ? Colors.grey.shade400 : Colors.grey),
                    size: 28,
                  ),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      habit.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    habit.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: streak > 0
                      ? Colors.orange.withValues(alpha: 0.15)
                      : (isDark ? Colors.white10 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 18,
                      color: streak > 0 ? Colors.deepOrange : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streak',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: streak > 0 ? Colors.deepOrange : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: last7Days.map((day) {
                  final isCompleted =
                      habit.completedDates.contains(day.dateStr);
                  final isToday = day.dateStr == todayStr;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onToggleDate(day.dateStr);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          day.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.w500,
                            color: isToday
                                ? accentColor
                                : (isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? accentColor
                                : (isDark
                                    ? Colors.white10
                                    : Colors.grey.shade100),
                            border: Border.all(
                              color: isToday && !isCompleted
                                  ? accentColor
                                  : (isCompleted
                                      ? accentColor
                                      : (isDark
                                          ? Colors.white24
                                          : Colors.grey.shade300)),
                              width: isToday ? 1.5 : 1.0,
                            ),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : (isToday
                                    ? Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: accentColor,
                                        ),
                                      )
                                    : null),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
