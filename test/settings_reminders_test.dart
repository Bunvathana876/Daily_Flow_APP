import 'package:daily_flow/core/services/notification_service.dart';
import 'package:daily_flow/features/settings/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class FakeNotificationService implements NotificationService {
  NotificationPermissionStatus permissionStatus =
      NotificationPermissionStatus.granted;
  bool isScheduled = false;
  int? scheduledHour;
  int? scheduledMinute;
  int scheduleCallCount = 0;
  int cancelCallCount = 0;
  int requestPermissionCount = 0;
  bool failNextSchedule = false;
  String? initialPayload;

  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {}

  @override
  Future<NotificationPermissionStatus> checkPermissionStatus() async {
    return permissionStatus;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    requestPermissionCount++;
    return permissionStatus;
  }

  @override
  Future<NotificationScheduleResult> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    scheduleCallCount++;
    if (failNextSchedule) {
      return const NotificationScheduleFailure('Simulated failure');
    }
    if (permissionStatus == NotificationPermissionStatus.denied ||
        permissionStatus == NotificationPermissionStatus.permanentlyDenied) {
      return const NotificationSchedulePermissionDenied();
    }
    isScheduled = true;
    scheduledHour = hour;
    scheduledMinute = minute;
    final now = tz.TZDateTime.now(tz.local);
    return NotificationScheduleSuccess(
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute),
    );
  }

  @override
  Future<void> cancelDailyReminder() async {
    cancelCallCount++;
    isScheduled = false;
    scheduledHour = null;
    scheduledMinute = null;
  }

  @override
  Future<bool> isDailyReminderScheduled() async {
    return isScheduled;
  }

  @override
  Future<String?> getInitialPayload() async {
    return initialPayload;
  }

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('SettingsController Daily Reminder Tests', () {
    late FakeNotificationService fakeNotificationService;

    setUp(() {
      fakeNotificationService = FakeNotificationService();
    });

    test(
      'initializes with default reminder state when no prefs exist',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationServiceProvider.overrideWithValue(
              fakeNotificationService,
            ),
          ],
        );
        addTearDown(container.dispose);

        final state = container.read(settingsControllerProvider);
        expect(state.reminderEnabled, isFalse);
        expect(state.reminderHour, 8);
        expect(state.reminderMinute, 0);
        expect(state.reminderErrorMessage, isNull);
      },
    );

    test(
      'enabling reminder when permission is granted schedules and persists',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationServiceProvider.overrideWithValue(
              fakeNotificationService,
            ),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(settingsControllerProvider.notifier);
        final success = await controller.setReminderEnabled(true);

        expect(success, isTrue);
        expect(fakeNotificationService.requestPermissionCount, 1);
        expect(fakeNotificationService.scheduleCallCount, 1);
        expect(fakeNotificationService.isScheduled, isTrue);
        expect(fakeNotificationService.scheduledHour, 8);
        expect(fakeNotificationService.scheduledMinute, 0);

        final state = container.read(settingsControllerProvider);
        expect(state.reminderEnabled, isTrue);
        expect(state.reminderErrorMessage, isNull);
        expect(
          prefs.getBool(SettingsController.reminderEnabledPrefKey),
          isTrue,
        );
      },
    );

    test(
      'enabling reminder when permission is denied rolls back and shows message',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        fakeNotificationService.permissionStatus =
            NotificationPermissionStatus.denied;

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationServiceProvider.overrideWithValue(
              fakeNotificationService,
            ),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(settingsControllerProvider.notifier);
        final success = await controller.setReminderEnabled(true);

        expect(success, isFalse);
        expect(fakeNotificationService.requestPermissionCount, 1);
        expect(
          fakeNotificationService.scheduleCallCount,
          0,
        ); // Did not schedule
        expect(fakeNotificationService.isScheduled, isFalse);

        final state = container.read(settingsControllerProvider);
        expect(state.reminderEnabled, isFalse);
        expect(
          state.reminderErrorMessage,
          contains('Notification permission is needed'),
        );
        expect(
          prefs.getBool(SettingsController.reminderEnabledPrefKey),
          isFalse,
        );
      },
    );

    test('enabling reminder when scheduling fails rolls back state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      fakeNotificationService.failNextSchedule = true;

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(
            fakeNotificationService,
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(settingsControllerProvider.notifier);
      final success = await controller.setReminderEnabled(true);

      expect(success, isFalse);
      final state = container.read(settingsControllerProvider);
      expect(state.reminderEnabled, isFalse);
      expect(state.reminderErrorMessage, 'Simulated failure');
      expect(prefs.getBool(SettingsController.reminderEnabledPrefKey), isFalse);
    });

    test(
      'disabling reminder cancels schedule and updates preferences',
      () async {
        SharedPreferences.setMockInitialValues({
          SettingsController.reminderEnabledPrefKey: true,
        });
        final prefs = await SharedPreferences.getInstance();
        fakeNotificationService.isScheduled = true;

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationServiceProvider.overrideWithValue(
              fakeNotificationService,
            ),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(settingsControllerProvider.notifier);
        final success = await controller.setReminderEnabled(false);

        expect(success, isTrue);
        expect(fakeNotificationService.cancelCallCount, 1);
        expect(fakeNotificationService.isScheduled, isFalse);

        final state = container.read(settingsControllerProvider);
        expect(state.reminderEnabled, isFalse);
        expect(
          prefs.getBool(SettingsController.reminderEnabledPrefKey),
          isFalse,
        );
      },
    );

    test(
      'updating time while reminder is active reschedules and persists',
      () async {
        SharedPreferences.setMockInitialValues({
          SettingsController.reminderEnabledPrefKey: true,
          SettingsController.reminderHourPrefKey: 8,
          SettingsController.reminderMinutePrefKey: 0,
        });
        final prefs = await SharedPreferences.getInstance();
        fakeNotificationService.isScheduled = true;

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationServiceProvider.overrideWithValue(
              fakeNotificationService,
            ),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(settingsControllerProvider.notifier);
        final success = await controller.setReminderTime(
          const TimeOfDay(hour: 7, minute: 45),
        );

        expect(success, isTrue);
        expect(fakeNotificationService.scheduleCallCount, 1);
        expect(fakeNotificationService.scheduledHour, 7);
        expect(fakeNotificationService.scheduledMinute, 45);

        final state = container.read(settingsControllerProvider);
        expect(state.reminderHour, 7);
        expect(state.reminderMinute, 45);
        expect(prefs.getInt(SettingsController.reminderHourPrefKey), 7);
        expect(prefs.getInt(SettingsController.reminderMinutePrefKey), 45);
      },
    );

    test(
      'updating time when scheduling fails rolls back previous time',
      () async {
        SharedPreferences.setMockInitialValues({
          SettingsController.reminderEnabledPrefKey: true,
          SettingsController.reminderHourPrefKey: 8,
          SettingsController.reminderMinutePrefKey: 0,
        });
        final prefs = await SharedPreferences.getInstance();
        fakeNotificationService.failNextSchedule = true;

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationServiceProvider.overrideWithValue(
              fakeNotificationService,
            ),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(settingsControllerProvider.notifier);
        final success = await controller.setReminderTime(
          const TimeOfDay(hour: 10, minute: 30),
        );

        expect(success, isFalse);
        final state = container.read(settingsControllerProvider);
        expect(state.reminderHour, 8); // Rolled back
        expect(state.reminderMinute, 0);
        expect(prefs.getInt(SettingsController.reminderHourPrefKey), 8);
        expect(prefs.getInt(SettingsController.reminderMinutePrefKey), 0);
        expect(
          state.reminderErrorMessage,
          contains('Failed to update reminder schedule'),
        );
      },
    );

    test(
      'updating time while reminder is disabled persists without scheduling',
      () async {
        SharedPreferences.setMockInitialValues({
          SettingsController.reminderEnabledPrefKey: false,
          SettingsController.reminderHourPrefKey: 8,
          SettingsController.reminderMinutePrefKey: 0,
        });
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationServiceProvider.overrideWithValue(
              fakeNotificationService,
            ),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(settingsControllerProvider.notifier);
        final success = await controller.setReminderTime(
          const TimeOfDay(hour: 6, minute: 15),
        );

        expect(success, isTrue);
        expect(
          fakeNotificationService.scheduleCallCount,
          0,
        ); // No scheduling since disabled

        final state = container.read(settingsControllerProvider);
        expect(state.reminderHour, 6);
        expect(state.reminderMinute, 15);
        expect(prefs.getInt(SettingsController.reminderHourPrefKey), 6);
        expect(prefs.getInt(SettingsController.reminderMinutePrefKey), 15);
      },
    );

    test(
      'restores saved reminder settings accurately on app restart',
      () async {
        SharedPreferences.setMockInitialValues({
          SettingsController.reminderEnabledPrefKey: true,
          SettingsController.reminderHourPrefKey: 9,
          SettingsController.reminderMinutePrefKey: 20,
        });
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationServiceProvider.overrideWithValue(
              fakeNotificationService,
            ),
          ],
        );
        addTearDown(container.dispose);

        final state = container.read(settingsControllerProvider);
        expect(state.reminderEnabled, isTrue);
        expect(state.reminderHour, 9);
        expect(state.reminderMinute, 20);
      },
    );

    test(
      'reconcileSchedule restores missing OS schedule when reminder is active',
      () async {
        SharedPreferences.setMockInitialValues({
          SettingsController.reminderEnabledPrefKey: true,
          SettingsController.reminderHourPrefKey: 8,
          SettingsController.reminderMinutePrefKey: 0,
        });
        final prefs = await SharedPreferences.getInstance();
        fakeNotificationService.isScheduled = false; // Missing from OS

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationServiceProvider.overrideWithValue(
              fakeNotificationService,
            ),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(settingsControllerProvider.notifier);
        await controller.checkPermissionAndReconcile();

        // Verified and restored schedule
        expect(fakeNotificationService.isScheduled, isTrue);
        expect(fakeNotificationService.scheduledHour, 8);
        expect(fakeNotificationService.scheduledMinute, 0);
      },
    );
  });
}
