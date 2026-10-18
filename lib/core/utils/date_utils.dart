import 'package:intl/intl.dart';

class DayInfo {
  final DateTime date;
  final String label;
  final String dateStr;

  const DayInfo({
    required this.date,
    required this.label,
    required this.dateStr,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayInfo &&
          runtimeType == other.runtimeType &&
          dateStr == other.dateStr &&
          label == other.label;

  @override
  int get hashCode => dateStr.hashCode ^ label.hashCode;
}

class AppDateUtils {
  static final DateFormat _formatter = DateFormat('yyyy-MM-dd');

  /// Normalizes any DateTime into a 'yyyy-MM-dd' string
  static String formatDate(DateTime date) => _formatter.format(date);

  /// Returns today's date string in 'yyyy-MM-dd'
  static String get todayString => formatDate(DateTime.now());

  /// Returns the last 7 days as 'yyyy-MM-dd' strings (from today back to 6 days ago)
  static List<String> getLast7DaysStrings([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    return List.generate(
      7,
      (index) => formatDate(now.subtract(Duration(days: index))),
    );
  }

  /// Single-letter day label ('M', 'T', 'W', 'T', 'F', 'S', 'S')
  static String getDayLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'T';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'S';
      default:
        return '';
    }
  }

  /// Returns the last 7 days as DateTime objects (ordered oldest to newest, ending today)
  static List<DateTime> getLast7Days([DateTime? referenceDate]) {
    final base = referenceDate ?? DateTime.now();
    return List.generate(7, (index) => base.subtract(Duration(days: 6 - index)));
  }

  /// Returns the last 7 days as DayInfo (ordered oldest to newest, ending today)
  /// along with single-letter day labels ('M', 'T', 'W', 'T', 'F', 'S', 'S').
  static List<DayInfo> getLast7DaysWithLabels([DateTime? referenceDate]) {
    final base = referenceDate ?? DateTime.now();
    return List.generate(7, (index) {
      final date = base.subtract(Duration(days: 6 - index));
      return DayInfo(
        date: date,
        label: getDayLabel(date),
        dateStr: formatDate(date),
      );
    });
  }

  /// Calculates consecutive completed days up to today or yesterday
  static int calculateStreak(Set<String> completedDates, [DateTime? referenceDate]) {
    if (completedDates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = referenceDate ?? DateTime.now();
    String todayStr = formatDate(checkDate);

    // If not completed today yet, check if the streak is still alive from yesterday
    if (!completedDates.contains(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (!completedDates.contains(formatDate(checkDate))) {
        return 0;
      }
    }

    // Count backward consecutively day by day
    while (completedDates.contains(formatDate(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Calculates the all-time longest consecutive daily streak
  static int calculateBestStreak(Set<String> completedDates) {
    if (completedDates.isEmpty) return 0;

    final sortedDates = completedDates
        .map((d) => DateTime.parse(d))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? previousDate;

    for (final date in sortedDates) {
      if (previousDate == null) {
        currentStreak = 1;
      } else {
        final expectedNextDay = DateTime(
          previousDate.year,
          previousDate.month,
          previousDate.day + 1,
        );
        if (expectedNextDay == date) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }
      }
      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }
      previousDate = date;
    }

    return maxStreak;
  }

  /// Returns a map of 'yyyy-MM-dd' to completion ratio (0.0 to 1.0) for the last [days] days
  static Map<String, double> getHeatmapData(
    List<dynamic> habits, {
    int days = 84,
    DateTime? referenceDate,
  }) {
    final base = referenceDate ?? DateTime.now();
    final Map<String, double> result = {};
    final totalHabits = habits.length;

    for (int i = days - 1; i >= 0; i--) {
      final date = base.subtract(Duration(days: i));
      final dateStr = formatDate(date);
      if (totalHabits == 0) {
        result[dateStr] = 0.0;
      } else {
        int completed = 0;
        for (final habit in habits) {
          if (habit.completedDates.contains(dateStr)) {
            completed++;
          }
        }
        result[dateStr] = completed / totalHabits;
      }
    }
    return result;
  }

  /// Returns completion ratios for Monday (1) through Sunday (7) over the last [weeks] weeks
  static Map<int, double> getWeekdayCompletionRates(
    List<dynamic> habits, {
    int weeks = 12,
    DateTime? referenceDate,
  }) {
    final rates = <int, double>{for (int i = 1; i <= 7; i++) i: 0.0};
    if (habits.isEmpty) return rates;

    final base = referenceDate ?? DateTime.now();
    final weekdayCounts = <int, int>{for (int i = 1; i <= 7; i++) i: 0};
    final weekdayCompletions = <int, int>{for (int i = 1; i <= 7; i++) i: 0};

    final totalDays = weeks * 7;
    for (int i = 0; i < totalDays; i++) {
      final date = base.subtract(Duration(days: i));
      final weekday = date.weekday;
      final dateStr = formatDate(date);

      weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;
      for (final habit in habits) {
        if (habit.completedDates.contains(dateStr)) {
          weekdayCompletions[weekday] = (weekdayCompletions[weekday] ?? 0) + 1;
        }
      }
    }

    for (int i = 1; i <= 7; i++) {
      final totalPossible = (weekdayCounts[i] ?? 0) * habits.length;
      rates[i] = totalPossible > 0
          ? (weekdayCompletions[i] ?? 0) / totalPossible
          : 0.0;
    }
    return rates;
  }
}
