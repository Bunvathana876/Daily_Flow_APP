import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Time-zone utility helping DailyFlow calculate local wall-clock daily reminder schedules
/// without Daylight Saving Time (DST) drift.
class NotificationTimezoneHelper {
  NotificationTimezoneHelper._();

  static bool _initialized = false;
  static String _currentTimeZone = 'UTC';

  /// Whether the timezone database has been initialized.
  static bool get isInitialized => _initialized;

  /// The active local timezone name (e.g. 'America/New_York', 'UTC').
  static String get currentTimeZone => _currentTimeZone;

  /// Initializes timezone database and configures the device's local timezone.
  ///
  /// Safe to call multiple times; subsequent calls are idempotent.
  static Future<void> initializeTimeZones({String? overrideTimeZone}) async {
    if (_initialized && overrideTimeZone == null) return;

    tz_data.initializeTimeZones();

    String timeZoneName;
    if (overrideTimeZone != null && overrideTimeZone.isNotEmpty) {
      timeZoneName = overrideTimeZone;
    } else {
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        timeZoneName = timezoneInfo.identifier;
      } catch (e) {
        debugPrint(
          'NotificationTimezoneHelper: Unable to query device local timezone ($e), falling back to UTC.',
        );
        timeZoneName = 'UTC';
      }
    }

    try {
      final location = tz.getLocation(timeZoneName);
      tz.setLocalLocation(location);
      _currentTimeZone = timeZoneName;
    } catch (e) {
      debugPrint(
        'NotificationTimezoneHelper: Unknown timezone "$timeZoneName", falling back to UTC.',
      );
      tz.setLocalLocation(tz.getLocation('UTC'));
      _currentTimeZone = 'UTC';
    }

    _initialized = true;
  }

  /// Calculates the next occurrence of [hour]:[minute] in the specified or local timezone.
  ///
  /// If today's time is in the future, returns today's occurrence.
  /// If today's time has already passed or is right now, returns tomorrow's occurrence.
  ///
  /// CRITICAL FOR DST: This explicitly constructs a wall-clock [tz.TZDateTime] for tomorrow
  /// using the target calendar date and the exact [hour] and [minute], instead of adding
  /// 24 hours of elapsed duration. This prevents 1-hour drift across spring-forward (23h)
  /// and fall-back (25h) daylight-saving transitions.
  static tz.TZDateTime nextOccurrence(
    int hour,
    int minute, {
    tz.Location? location,
    DateTime? from,
  }) {
    final loc = location ?? tz.local;
    final now = from != null
        ? tz.TZDateTime.from(from, loc)
        : tz.TZDateTime.now(loc);

    var scheduledDate = tz.TZDateTime(
      loc,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate.isAfter(now)) {
      // Find tomorrow's date by moving forward past current midnight
      final tomorrow = now.add(const Duration(days: 1));
      scheduledDate = tz.TZDateTime(
        loc,
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        hour,
        minute,
      );
    }

    return scheduledDate;
  }

  /// Resets state for isolated testing environments.
  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    _currentTimeZone = 'UTC';
  }
}
