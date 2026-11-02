import 'package:daily_flow/core/utils/notification_timezone_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
  });

  setUp(() {
    NotificationTimezoneHelper.resetForTesting();
  });

  group('NotificationTimezoneHelper Tests', () {
    test('initializes and configures specific timezone', () async {
      await NotificationTimezoneHelper.initializeTimeZones(
        overrideTimeZone: 'America/New_York',
      );

      expect(NotificationTimezoneHelper.isInitialized, isTrue);
      expect(NotificationTimezoneHelper.currentTimeZone, 'America/New_York');
      expect(tz.local.name, 'America/New_York');
    });

    test('falls back gracefully on unknown timezone identifier', () async {
      await NotificationTimezoneHelper.initializeTimeZones(
        overrideTimeZone: 'Invalid/NonExistent_Zone',
      );

      expect(NotificationTimezoneHelper.isInitialized, isTrue);
      expect(NotificationTimezoneHelper.currentTimeZone, 'UTC');
      expect(tz.local.name, 'UTC');
    });

    test('schedules for today when target time is in the future', () {
      final location = tz.getLocation('America/New_York');
      // Current time: 08:30 AM on Oct 10, 2026
      final now = tz.TZDateTime(location, 2026, 10, 10, 8, 30);

      // Target time: 10:00 AM (future)
      final scheduled = NotificationTimezoneHelper.nextOccurrence(
        10,
        0,
        location: location,
        from: now,
      );

      expect(scheduled.year, 2026);
      expect(scheduled.month, 10);
      expect(scheduled.day, 10);
      expect(scheduled.hour, 10);
      expect(scheduled.minute, 0);
      expect(scheduled.isAfter(now), isTrue);
    });

    test(
      'schedules for tomorrow when target time has already passed today',
      () {
        final location = tz.getLocation('America/New_York');
        // Current time: 14:00 (2:00 PM) on Oct 10, 2026
        final now = tz.TZDateTime(location, 2026, 10, 10, 14, 0);

        // Target time: 08:00 AM (past)
        final scheduled = NotificationTimezoneHelper.nextOccurrence(
          8,
          0,
          location: location,
          from: now,
        );

        expect(scheduled.year, 2026);
        expect(scheduled.month, 10);
        expect(scheduled.day, 11); // Tomorrow
        expect(scheduled.hour, 8);
        expect(scheduled.minute, 0);
        expect(scheduled.isAfter(now), isTrue);
      },
    );

    test('schedules for tomorrow when target time is exact current minute', () {
      final location = tz.getLocation('Asia/Tokyo');
      // Current time: 09:15 on Oct 15, 2026
      final now = tz.TZDateTime(location, 2026, 10, 15, 9, 15);

      final scheduled = NotificationTimezoneHelper.nextOccurrence(
        9,
        15,
        location: location,
        from: now,
      );

      expect(scheduled.day, 16);
      expect(scheduled.hour, 9);
      expect(scheduled.minute, 15);
      expect(scheduled.isAfter(now), isTrue);
    });

    test('handles month rollover safely (e.g. October 31 to November 1)', () {
      final location = tz.getLocation('Europe/London');
      final now = tz.TZDateTime(location, 2026, 10, 31, 20, 0);

      final scheduled = NotificationTimezoneHelper.nextOccurrence(
        8,
        0,
        location: location,
        from: now,
      );

      expect(scheduled.year, 2026);
      expect(scheduled.month, 11);
      expect(scheduled.day, 1);
      expect(scheduled.hour, 8);
      expect(scheduled.minute, 0);
    });

    test('handles year rollover safely (e.g. December 31 to January 1)', () {
      final location = tz.getLocation('UTC');
      final now = tz.TZDateTime(location, 2026, 12, 31, 23, 0);

      final scheduled = NotificationTimezoneHelper.nextOccurrence(
        8,
        0,
        location: location,
        from: now,
      );

      expect(scheduled.year, 2027);
      expect(scheduled.month, 1);
      expect(scheduled.day, 1);
      expect(scheduled.hour, 8);
      expect(scheduled.minute, 0);
    });

    test(
      'handles leap year transition (Feb 28 to Feb 29 in leap year 2028)',
      () {
        final location = tz.getLocation('UTC');
        final now = tz.TZDateTime(location, 2028, 2, 28, 12, 0);

        final scheduled = NotificationTimezoneHelper.nextOccurrence(
          8,
          0,
          location: location,
          from: now,
        );

        expect(scheduled.year, 2028);
        expect(scheduled.month, 2);
        expect(scheduled.day, 29); // Leap day
        expect(scheduled.hour, 8);
        expect(scheduled.minute, 0);
      },
    );

    test(
      'prevents 1-hour DST drift across spring forward transition (America/New_York)',
      () {
        final location = tz.getLocation('America/New_York');
        // In 2026, US Daylight Saving begins Sunday, March 8, 2026 (clocks jump 2:00 AM -> 3:00 AM).
        // On Saturday, March 7 at 9:00 PM:
        final saturdayNight = tz.TZDateTime(location, 2026, 3, 7, 21, 0);

        // Calculate next 8:00 AM reminder
        final scheduled = NotificationTimezoneHelper.nextOccurrence(
          8,
          0,
          location: location,
          from: saturdayNight,
        );

        // Must remain exactly 8:00 AM on Sunday, March 8
        expect(scheduled.year, 2026);
        expect(scheduled.month, 3);
        expect(scheduled.day, 8);
        expect(scheduled.hour, 8);
        expect(scheduled.minute, 0);
      },
    );

    test(
      'prevents 1-hour DST drift across fall back transition (America/New_York)',
      () {
        final location = tz.getLocation('America/New_York');
        // In 2026, US Daylight Saving ends Sunday, November 1, 2026 (clocks repeat 1:00 AM).
        // On Saturday, Oct 31 at 10:00 PM:
        final saturdayNight = tz.TZDateTime(location, 2026, 10, 31, 22, 0);

        // Calculate next 8:00 AM reminder
        final scheduled = NotificationTimezoneHelper.nextOccurrence(
          8,
          0,
          location: location,
          from: saturdayNight,
        );

        // Must remain exactly 8:00 AM on Sunday, November 1
        expect(scheduled.year, 2026);
        expect(scheduled.month, 11);
        expect(scheduled.day, 1);
        expect(scheduled.hour, 8);
        expect(scheduled.minute, 0);
      },
    );
  });
}
