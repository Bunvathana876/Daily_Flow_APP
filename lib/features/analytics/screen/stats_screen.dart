import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_utils.dart';
import '../../habits/controllers/habit_controller.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final totalCompletions = habits.fold<int>(
      0,
      (sum, h) => sum + h.completedDates.length,
    );

    final bestEverStreak = habits.isEmpty
        ? 0
        : habits
            .map((h) => AppDateUtils.calculateBestStreak(h.completedDates))
            .reduce(max);

    final heatmapData = AppDateUtils.getHeatmapData(habits, days: 84);
    final weekdayRates = AppDateUtils.getWeekdayCompletionRates(habits);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Insights & Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards Row
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    title: 'Total Check-ins',
                    value: '$totalCompletions',
                    icon: Icons.check_circle_rounded,
                    iconColor: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    title: 'Best Streak',
                    value: '$bestEverStreak d',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.deepOrange,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    title: 'Active Habits',
                    value: '${habits.length}',
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFF4F46E5),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 12-Week Consistency Heatmap Card
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '12-Week Consistency',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Last 84 Days',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _HeatmapGrid(
                    heatmapData: heatmapData,
                    primaryColor: primaryColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Less',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      for (final ratio in [0.0, 0.25, 0.5, 0.75, 1.0]) ...[
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: ratio == 0.0
                                ? (isDark
                                    ? Colors.white10
                                    : Colors.grey.shade200)
                                : primaryColor.withValues(
                                    alpha: 0.2 + 0.8 * ratio),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        'More',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Weekday Performance Bar Chart Card
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Weekday Performance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Average Rate',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _WeekdayBarChart(
                    rates: weekdayRates,
                    primaryColor: primaryColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final Map<String, double> heatmapData;
  final Color primaryColor;
  final bool isDark;

  const _HeatmapGrid({
    required this.heatmapData,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final entries = heatmapData.entries.toList();
    final columns = <List<MapEntry<String, double>>>[];
    for (int i = 0; i < entries.length; i += 7) {
      columns.add(entries.sublist(i, min(i + 7, entries.length)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final boxSize = max(10.0, (availableWidth - (12 * 4)) / 12);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: columns.map((col) {
            return Column(
              children: col.map((entry) {
                final ratio = entry.value;
                final color = ratio == 0.0
                    ? (isDark ? Colors.white10 : Colors.grey.shade200)
                    : primaryColor.withValues(alpha: 0.2 + 0.8 * ratio);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Tooltip(
                    message: '${entry.key}: ${(ratio * 100).round()}% completed',
                    child: Container(
                      width: boxSize,
                      height: boxSize,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        );
      },
    );
  }
}

class _WeekdayBarChart extends StatelessWidget {
  final Map<int, double> rates;
  final Color primaryColor;
  final bool isDark;

  const _WeekdayBarChart({
    required this.rates,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const maxBarHeight = 90.0;
    final maxRate = rates.values.fold<double>(0.0, max);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final weekday = index + 1;
        final rate = rates[weekday] ?? 0.0;
        final barHeight = max(6.0, rate * maxBarHeight);
        final isTop = maxRate > 0 && (rate - maxRate).abs() < 0.001;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(rate * 100).round()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isTop ? FontWeight.bold : FontWeight.w500,
                color: isTop
                    ? primaryColor
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: 24,
              height: barHeight,
              decoration: BoxDecoration(
                color: rate > 0
                    ? (isTop
                        ? primaryColor
                        : primaryColor.withValues(alpha: 0.6))
                    : (isDark ? Colors.white10 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              weekdayLabels[index],
              style: TextStyle(
                fontSize: 12,
                fontWeight: isTop ? FontWeight.bold : FontWeight.w600,
                color: isTop
                    ? primaryColor
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        );
      }),
    );
  }
}

