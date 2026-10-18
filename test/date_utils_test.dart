import 'package:daily_flow/core/utils/date_utils.dart';
import 'package:daily_flow/features/habits/models/habit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDateUtils.calculateStreak', () {
    final fixedToday = DateTime(2026, 10, 18); // Sunday

    test('returns 0 when completedDates is empty', () {
      expect(AppDateUtils.calculateStreak({}, fixedToday), 0);
    });

    test('returns 1 when completed only today', () {
      final dates = {'2026-10-18'};
      expect(AppDateUtils.calculateStreak(dates, fixedToday), 1);
    });

    test('returns 1 when completed only yesterday (streak preserved)', () {
      final dates = {'2026-10-17'};
      expect(AppDateUtils.calculateStreak(dates, fixedToday), 1);
    });

    test('returns 0 when last completed was 2 days ago', () {
      final dates = {'2026-10-16'};
      expect(AppDateUtils.calculateStreak(dates, fixedToday), 0);
    });

    test('returns consecutive streak up to today', () {
      final dates = {'2026-10-18', '2026-10-17', '2026-10-16', '2026-10-15'};
      expect(AppDateUtils.calculateStreak(dates, fixedToday), 4);
    });

    test('returns consecutive streak up to yesterday when today not completed yet', () {
      final dates = {'2026-10-17', '2026-10-16', '2026-10-15'};
      expect(AppDateUtils.calculateStreak(dates, fixedToday), 3);
    });

    test('breaks streak on missed day', () {
      final dates = {'2026-10-18', '2026-10-17', '2026-10-15'};
      expect(AppDateUtils.calculateStreak(dates, fixedToday), 2);
    });
  });

  group('AppDateUtils.calculateBestStreak', () {
    test('returns 0 for empty completedDates', () {
      expect(AppDateUtils.calculateBestStreak({}), 0);
    });

    test('returns 1 for a single completed day', () {
      expect(AppDateUtils.calculateBestStreak({'2026-10-01'}), 1);
    });

    test('returns longest consecutive streak even if current streak is broken', () {
      // Streak 1: 4 days (Oct 1 to Oct 4)
      // Break: Oct 5-9
      // Streak 2: 2 days (Oct 10-11)
      final dates = {
        '2026-10-01',
        '2026-10-02',
        '2026-10-03',
        '2026-10-04',
        '2026-10-10',
        '2026-10-11',
      };
      expect(AppDateUtils.calculateBestStreak(dates), 4);
    });

    test('correctly handles month boundary transitions', () {
      final dates = {
        '2026-09-29',
        '2026-09-30',
        '2026-10-01',
        '2026-10-02',
      };
      expect(AppDateUtils.calculateBestStreak(dates), 4);
    });
  });

  group('AppDateUtils 7-day helpers', () {
    final fixedToday = DateTime(2026, 10, 18); // Sunday

    test('getLast7Days returns 7 consecutive dates ending today', () {
      final days = AppDateUtils.getLast7Days(fixedToday);
      expect(days.length, 7);
      expect(AppDateUtils.formatDate(days.last), '2026-10-18');
      expect(AppDateUtils.formatDate(days.first), '2026-10-12');
    });

    test('getLast7DaysWithLabels returns 7 DayInfo objects with correct labels', () {
      final days = AppDateUtils.getLast7DaysWithLabels(fixedToday);
      expect(days.length, 7);
      expect(days.last.dateStr, '2026-10-18');
      expect(days.last.label, 'S'); // Sunday
      expect(days.first.dateStr, '2026-10-12');
      expect(days.first.label, 'M'); // Monday

      final labels = days.map((d) => d.label).toList();
      expect(labels, ['M', 'T', 'W', 'T', 'F', 'S', 'S']);
    });

    test('getDayLabel returns correct single-letter day codes', () {
      expect(AppDateUtils.getDayLabel(DateTime(2026, 10, 12)), 'M'); // Mon
      expect(AppDateUtils.getDayLabel(DateTime(2026, 10, 13)), 'T'); // Tue
      expect(AppDateUtils.getDayLabel(DateTime(2026, 10, 14)), 'W'); // Wed
      expect(AppDateUtils.getDayLabel(DateTime(2026, 10, 15)), 'T'); // Thu
      expect(AppDateUtils.getDayLabel(DateTime(2026, 10, 16)), 'F'); // Fri
      expect(AppDateUtils.getDayLabel(DateTime(2026, 10, 17)), 'S'); // Sat
      expect(AppDateUtils.getDayLabel(DateTime(2026, 10, 18)), 'S'); // Sun
    });
  });

  group('AppDateUtils Analytics Math', () {
    final fixedToday = DateTime(2026, 10, 18);

    final habit1 = Habit(
      id: 1,
      title: 'Run',
      createdAt: DateTime(2026, 1, 1),
      completedDates: {'2026-10-18', '2026-10-17'},
    );
    final habit2 = Habit(
      id: 2,
      title: 'Read',
      createdAt: DateTime(2026, 1, 1),
      completedDates: {'2026-10-18'},
    );

    test('getHeatmapData returns 84 entries with valid ratios', () {
      final heatmap = AppDateUtils.getHeatmapData(
        [habit1, habit2],
        days: 84,
        referenceDate: fixedToday,
      );
      expect(heatmap.length, 84);
      // On 2026-10-18: both habits completed -> 2/2 = 1.0
      expect(heatmap['2026-10-18'], 1.0);
      // On 2026-10-17: 1 habit completed -> 1/2 = 0.5
      expect(heatmap['2026-10-17'], 0.5);
      // On 2026-10-16: 0 completed -> 0.0
      expect(heatmap['2026-10-16'], 0.0);
    });

    test('getWeekdayCompletionRates returns rates for days 1 through 7', () {
      final rates = AppDateUtils.getWeekdayCompletionRates(
        [habit1, habit2],
        weeks: 1,
        referenceDate: fixedToday,
      );
      expect(rates.keys.toList(), [1, 2, 3, 4, 5, 6, 7]);
      // Sunday is 7 (Oct 18, both completed -> 1.0)
      expect(rates[7], 1.0);
      // Saturday is 6 (Oct 17, 1 completed -> 0.5)
      expect(rates[6], 0.5);
    });
  });
}
