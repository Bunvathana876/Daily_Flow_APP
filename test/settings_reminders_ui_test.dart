import 'package:daily_flow/core/services/notification_service.dart';
import 'package:daily_flow/core/theme/app_theme.dart';
import 'package:daily_flow/features/settings/controllers/settings_controller.dart';
import 'package:daily_flow/features/settings/screen/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class FakeUiNotificationService implements NotificationService {
  NotificationPermissionStatus permissionStatus =
      NotificationPermissionStatus.granted;
  bool isScheduled = false;

  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {}

  @override
  Future<NotificationPermissionStatus> checkPermissionStatus() async =>
      permissionStatus;

  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      permissionStatus;

  @override
  Future<NotificationScheduleResult> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (permissionStatus == NotificationPermissionStatus.denied) {
      return const NotificationSchedulePermissionDenied();
    }
    isScheduled = true;
    final now = tz.TZDateTime.now(tz.local);
    return NotificationScheduleSuccess(
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute),
    );
  }

  @override
  Future<void> cancelDailyReminder() async {
    isScheduled = false;
  }

  @override
  Future<bool> isDailyReminderScheduled() async => isScheduled;

  @override
  Future<String?> getInitialPayload() async => null;

  @override
  void dispose() {}
}

Widget createSettingsTestApp({
  required SharedPreferences prefs,
  required FakeUiNotificationService notificationService,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationServiceProvider.overrideWithValue(notificationService),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('SettingsScreen Daily Reminder UI Tests', () {
    testWidgets(
      'renders Preferences, Daily Reminders switch, and Reminder Time tile',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final fakeService = FakeUiNotificationService();

        await tester.pumpWidget(
          createSettingsTestApp(prefs: prefs, notificationService: fakeService),
        );
        await tester.pumpAndSettle();

        expect(find.text('Preferences'), findsOneWidget);
        expect(find.text('Daily Reminders'), findsOneWidget);
        expect(find.text('Daily Reminder Time'), findsOneWidget);
        expect(
          find.text('Off — turn on to stay consistent with your quests'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'toggling switch ON when permission granted activates reminder',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final fakeService = FakeUiNotificationService();

        await tester.pumpWidget(
          createSettingsTestApp(prefs: prefs, notificationService: fakeService),
        );
        await tester.pumpAndSettle();

        // Find the Daily Reminders switch
        final reminderSwitch = find.widgetWithText(
          SwitchListTile,
          'Daily Reminders',
        );
        expect(reminderSwitch, findsOneWidget);

        await tester.tap(reminderSwitch);
        await tester.pumpAndSettle();

        expect(fakeService.isScheduled, isTrue);
        expect(
          find.text('Active — daily quests reminder scheduled'),
          findsOneWidget,
        );
        expect(
          prefs.getBool(SettingsController.reminderEnabledPrefKey),
          isTrue,
        );
      },
    );

    testWidgets(
      'toggling switch ON when permission denied shows warning banner',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final fakeService = FakeUiNotificationService()
          ..permissionStatus = NotificationPermissionStatus.denied;

        await tester.pumpWidget(
          createSettingsTestApp(prefs: prefs, notificationService: fakeService),
        );
        await tester.pumpAndSettle();

        final reminderSwitch = find.widgetWithText(
          SwitchListTile,
          'Daily Reminders',
        );
        await tester.tap(reminderSwitch);
        await tester.pumpAndSettle();

        expect(fakeService.isScheduled, isFalse);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(
          find.textContaining('Notification permission is needed'),
          findsOneWidget,
        );
        expect(
          prefs.getBool(SettingsController.reminderEnabledPrefKey),
          isFalse,
        );

        // Dismiss the banner with close button
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      },
    );
  });
}
