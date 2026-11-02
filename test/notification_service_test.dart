import 'package:daily_flow/core/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class FakeScheduledCall {
  final int id;
  final String? title;
  final String? body;
  final tz.TZDateTime scheduledDate;
  final NotificationDetails notificationDetails;
  final AndroidScheduleMode androidScheduleMode;
  final DateTimeComponents? matchDateTimeComponents;
  final String? payload;

  FakeScheduledCall({
    required this.id,
    this.title,
    this.body,
    required this.scheduledDate,
    required this.notificationDetails,
    required this.androidScheduleMode,
    this.matchDateTimeComponents,
    this.payload,
  });
}

class FakeFlutterLocalNotificationsPlugin
    implements FlutterLocalNotificationsPlugin {
  bool isInitialized = false;
  InitializationSettings? lastSettings;
  DidReceiveNotificationResponseCallback? onNotificationResponse;
  NotificationAppLaunchDetails? launchDetails;

  final List<FakeScheduledCall> scheduledCalls = [];
  final List<int> cancelledNotificationIds = [];
  final List<PendingNotificationRequest> mockPendingRequests = [];
  bool throwOnSchedule = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    isInitialized = true;
    lastSettings = settings;
    onNotificationResponse = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async {
    return launchDetails;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (throwOnSchedule) {
      throw Exception('Simulated OS scheduling failure');
    }
    scheduledCalls.add(
      FakeScheduledCall(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      ),
    );
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelledNotificationIds.add(id);
    scheduledCalls.removeWhere((call) => call.id == id);
    mockPendingRequests.removeWhere((req) => req.id == id);
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return List.unmodifiable(mockPendingRequests);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('LocalNotificationService Tests', () {
    late FakeFlutterLocalNotificationsPlugin fakePlugin;
    late LocalNotificationService service;
    late tz.Location testLocation;

    setUp(() {
      testLocation = tz.getLocation('UTC');
      fakePlugin = FakeFlutterLocalNotificationsPlugin();
      service = LocalNotificationService(
        plugin: fakePlugin,
        locationProvider: () => testLocation,
        nextOccurrenceCalculator: (hour, minute, {location}) {
          return tz.TZDateTime(
            location ?? testLocation,
            2026,
            11,
            2,
            hour,
            minute,
          );
        },
      );
    });

    test(
      'initializes plugin with proper Android and Darwin settings',
      () async {
        await service.initialize();

        expect(fakePlugin.isInitialized, isTrue);
        expect(fakePlugin.lastSettings, isNotNull);
        expect(
          fakePlugin.lastSettings!.android?.defaultIcon,
          NotificationConstants.androidIcon,
        );
        // Ensures permissions are NOT requested on startup
        expect(fakePlugin.lastSettings!.iOS?.requestAlertPermission, isFalse);
        expect(fakePlugin.lastSettings!.iOS?.requestBadgePermission, isFalse);
        expect(fakePlugin.lastSettings!.iOS?.requestSoundPermission, isFalse);
      },
    );

    test('multiple calls to initialize are idempotent', () async {
      await service.initialize();
      final firstSettings = fakePlugin.lastSettings;

      await service.initialize();
      expect(fakePlugin.lastSettings, equals(firstSettings));
    });

    test(
      'schedules daily reminder with stable ID and inexact alarm mode',
      () async {
        final result = await service.scheduleDailyReminder(hour: 8, minute: 30);

        expect(result, isA<NotificationScheduleSuccess>());
        expect(fakePlugin.scheduledCalls.length, 1);

        final call = fakePlugin.scheduledCalls.first;
        expect(call.id, NotificationConstants.dailyReminderId);
        expect(call.title, NotificationConstants.dailyReminderTitle);
        expect(call.body, NotificationConstants.dailyReminderBody);
        expect(call.payload, NotificationConstants.dailyReminderPayload);
        expect(call.scheduledDate.hour, 8);
        expect(call.scheduledDate.minute, 30);
        expect(call.matchDateTimeComponents, DateTimeComponents.time);
        // Inexact scheduling strictly compliant with Google Play policy
        expect(
          call.androidScheduleMode,
          AndroidScheduleMode.inexactAllowWhileIdle,
        );
      },
    );

    test(
      'rescheduling cancels previous reminder before creating new one',
      () async {
        await service.scheduleDailyReminder(hour: 8, minute: 0);
        await service.scheduleDailyReminder(hour: 9, minute: 15);

        expect(
          fakePlugin.cancelledNotificationIds,
          contains(NotificationConstants.dailyReminderId),
        );
        // Last scheduled call has the updated time
        expect(fakePlugin.scheduledCalls.last.scheduledDate.hour, 9);
        expect(fakePlugin.scheduledCalls.last.scheduledDate.minute, 15);
      },
    );

    test(
      'canceling daily reminder calls plugin.cancel with stable ID',
      () async {
        await service.cancelDailyReminder();
        expect(
          fakePlugin.cancelledNotificationIds,
          contains(NotificationConstants.dailyReminderId),
        );
      },
    );

    test(
      'isDailyReminderScheduled reports true only when notification is in pending list',
      () async {
        expect(await service.isDailyReminderScheduled(), isFalse);

        fakePlugin.mockPendingRequests.add(
          const PendingNotificationRequest(
            NotificationConstants.dailyReminderId,
            NotificationConstants.dailyReminderTitle,
            NotificationConstants.dailyReminderBody,
            NotificationConstants.dailyReminderPayload,
          ),
        );

        expect(await service.isDailyReminderScheduled(), isTrue);
      },
    );

    test(
      'handles tap callback dispatch when notification response received',
      () async {
        String? tappedPayload;
        await service.initialize(
          onNotificationTap: (payload) => tappedPayload = payload,
        );

        // Simulate notification tapped by user
        fakePlugin.onNotificationResponse?.call(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: NotificationConstants.dailyReminderPayload,
          ),
        );

        expect(tappedPayload, NotificationConstants.dailyReminderPayload);
      },
    );

    test(
      'captures cold launch payload when app opened from notification',
      () async {
        fakePlugin.launchDetails = const NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: NotificationConstants.dailyReminderPayload,
          ),
        );

        await service.initialize();
        final payload = await service.getInitialPayload();

        expect(payload, NotificationConstants.dailyReminderPayload);
      },
    );

    test(
      'returns NotificationScheduleFailure on platform error without throwing',
      () async {
        fakePlugin.throwOnSchedule = true;

        final result = await service.scheduleDailyReminder(hour: 8, minute: 0);

        expect(result, isA<NotificationScheduleFailure>());
        final failure = result as NotificationScheduleFailure;
        expect(failure.message, contains('Failed to schedule daily reminder'));
      },
    );
  });
}
