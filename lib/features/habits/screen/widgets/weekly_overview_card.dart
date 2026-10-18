import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../models/habit.dart';

class WeeklyOverviewCard extends StatelessWidget {
  final List<Habit> habits;

  const WeeklyOverviewCard({super.key, required this.habits});

  double _calculateWeeklyCompletionRate() {
    if (habits.isEmpty) return 0.0;
    final last7Days = AppDateUtils.getLast7DaysStrings();
    int completedCount = 0;
    final int totalPossible = habits.length * 7;

    for (final dateStr in last7Days) {
      for (final habit in habits) {
        if (habit.completedDates.contains(dateStr)) {
          completedCount++;
        }
      }
    }
    return completedCount / totalPossible;
  }

  @override
  Widget build(BuildContext context) {
    final weeklyRate = _calculateWeeklyCompletionRate();
    final percentage = (weeklyRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '7-Day Completion Rate',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: weeklyRate),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
