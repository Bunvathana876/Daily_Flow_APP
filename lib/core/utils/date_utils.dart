import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  static DateTime Function() _clock = DateTime.now;

  /// Returns current local DateTime based on injectable clock.
  static DateTime now() => _clock();

  /// Injects a custom clock for deterministic testing and midnight simulation.
  @visibleForTesting
  static void setCustomClock(DateTime Function()? clock) {
    _clock = clock ?? DateTime.now;
  }

  /// Normalizes any DateTime into a 'yyyy-MM-dd' string.
  static String formatDate(DateTime date) => _formatter.format(date);

  /// Normalizes a DateTime to midnight (year, month, day), ignoring time components.
  static DateTime normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Checks whether two DateTimes fall on the exact same calendar day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns today's date string in 'yyyy-MM-dd' based on active clock.
  static String get todayString => formatDate(now());

  /// Checks whether a 'yyyy-MM-dd' string represents today's local calendar day.
  static bool isToday(String dateStr) => dateStr == todayString;

  /// Checks whether a 'yyyy-MM-dd' string is strictly before today's local calendar day.
  static bool isPastDay(String dateStr, [DateTime? referenceDate]) {
    try {
      final target = normalizeDate(DateTime.parse(dateStr));
      final ref = normalizeDate(referenceDate ?? now());
      return target.isBefore(ref);
    } catch (_) {
      return false;
    }
  }

  /// Checks whether a 'yyyy-MM-dd' string is strictly after today's local calendar day.
  static bool isFutureDay(String dateStr, [DateTime? referenceDate]) {
    try {
      final target = normalizeDate(DateTime.parse(dateStr));
      final ref = normalizeDate(referenceDate ?? now());
      return target.isAfter(ref);
    } catch (_) {
      return false;
    }
  }

  /// Returns the last 7 days as 'yyyy-MM-dd' strings (from today back to 6 days ago).
  static List<String> getLast7DaysStrings([DateTime? referenceDate]) {
    final base = referenceDate ?? now();
    return List.generate(
      7,
      (index) => formatDate(base.subtract(Duration(days: index))),
    );
  }

  /// Single-letter day label ('M', 'T', 'W', 'T', 'F', 'S', 'S').
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

  /// Returns the last 7 days as DateTime objects (ordered oldest to newest, ending today).
  static List<DateTime> getLast7Days([DateTime? referenceDate]) {
    final base = referenceDate ?? now();
    return List.generate(
      7,
      (index) => base.subtract(Duration(days: 6 - index)),
    );
  }

  /// Returns the last 7 days as DayInfo (ordered oldest to newest, ending today)
  /// along with single-letter day labels ('M', 'T', 'W', 'T', 'F', 'S', 'S').
  static List<DayInfo> getLast7DaysWithLabels([DateTime? referenceDate]) {
    final base = referenceDate ?? now();
    return List.generate(7, (index) {
      final date = base.subtract(Duration(days: 6 - index));
      return DayInfo(
        date: date,
        label: getDayLabel(date),
        dateStr: formatDate(date),
      );
    });
  }

  /// Calculates consecutive completed days up to today or yesterday.
  static int calculateStreak(
    Set<String> completedDates, [
    DateTime? referenceDate,
  ]) {
    if (completedDates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = referenceDate ?? now();
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

  /// Calculates the all-time longest consecutive daily streak.
  static int calculateBestStreak(Set<String> completedDates) {
    if (completedDates.isEmpty) return 0;

    final sortedDates =
        completedDates
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

  /// Returns a map of 'yyyy-MM-dd' to completion ratio (0.0 to 1.0) for the last [days] days.
  static Map<String, double> getHeatmapData(
    List<dynamic> habits, {
    int days = 84,
    DateTime? referenceDate,
  }) {
    final base = referenceDate ?? now();
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

  /// Returns completion ratios for Monday (1) through Sunday (7) over the last [weeks] weeks.
  static Map<int, double> getWeekdayCompletionRates(
    List<dynamic> habits, {
    int weeks = 12,
    DateTime? referenceDate,
  }) {
    final rates = <int, double>{for (int i = 1; i <= 7; i++) i: 0.0};
    if (habits.isEmpty) return rates;

    final base = referenceDate ?? now();
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

/// Notifier providing reactive access to today's normalized date string ('yyyy-MM-dd').
///
/// Automatically fires at midnight or upon app resumption so that the UI seamlessly
/// locks yesterday's completed/uncompleted states without requiring an app restart.
class CurrentDateNotifier extends Notifier<String> {
  Timer? _midnightTimer;

  /// Controls whether an automatic background Timer should be scheduled for midnight.
  /// Enabled in real app execution; bypassed in automated widget tests to avoid pending timer assertions.
  static bool enableMidnightTimer = true;

  static bool get _isTestEnvironment {
    try {
      final binding = WidgetsBinding.instance;
      return binding.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  @override
  String build() {
    ref.onDispose(() => _midnightTimer?.cancel());
    if (enableMidnightTimer && !_isTestEnvironment) {
      _scheduleMidnightTimer();
    }
    return AppDateUtils.todayString;
  }

  /// Re-evaluates current calendar date (called on app resume or lifecycle change).
  void checkDateChanged() {
    final currentToday = AppDateUtils.todayString;
    if (state != currentToday) {
      state = currentToday;
      if (enableMidnightTimer && !_isTestEnvironment) {
        _scheduleMidnightTimer();
      }
    }
  }

  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final current = AppDateUtils.now();
    final tomorrow = DateTime(current.year, current.month, current.day + 1);
    final delay =
        tomorrow.difference(current) + const Duration(milliseconds: 500);
    _midnightTimer = Timer(delay, () {
      checkDateChanged();
    });
  }

  @visibleForTesting
  void scheduleMidnightTimerForTesting() {
    _scheduleMidnightTimer();
  }
}

final currentDateProvider = NotifierProvider<CurrentDateNotifier, String>(
  CurrentDateNotifier.new,
);
