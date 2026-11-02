import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../utils/notification_timezone_helper.dart';

/// Notification permission status abstraction.
enum NotificationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  notDetermined,
}

/// Typed result of a scheduling operation.
sealed class NotificationScheduleResult {
  const NotificationScheduleResult();

  bool get isSuccess => this is NotificationScheduleSuccess;
}

class NotificationScheduleSuccess extends NotificationScheduleResult {
  final tz.TZDateTime scheduledTime;
  const NotificationScheduleSuccess(this.scheduledTime);
}

class NotificationSchedulePermissionDenied extends NotificationScheduleResult {
  final String reason;
  const NotificationSchedulePermissionDenied([
    this.reason = 'Notification permission was not granted by the user.',
  ]);
}

class NotificationScheduleFailure extends NotificationScheduleResult {
  final String message;
  final Object? error;

  const NotificationScheduleFailure(this.message, [this.error]);
}

/// Constants for DailyFlow daily reminder notifications.
class NotificationConstants {
  NotificationConstants._();

  static const int dailyReminderId = 1001;
  static const String dailyReminderChannelId = 'daily_quest_reminders';
  static const String dailyReminderChannelName = 'Daily Quest Reminders';
  static const String dailyReminderChannelDesc =
      'Daily quest reminder notifications to keep your streak alive.';
  static const String dailyReminderPayload = 'daily_quest_reminder';
  static const String dailyReminderTitle = 'Your Daily Quests Await!';
  static const String dailyReminderBody =
      'A new day, a new adventure. Ready to make progress?';
  static const String androidIcon = 'ic_notification';
}

/// Abstract contract for DailyFlow's local notification service.
abstract class NotificationService {
  /// Initializes local notification plugins and hooks up notification tap callbacks.
  Future<void> initialize({void Function(String? payload)? onNotificationTap});

  /// Reads the current notification permission status from the platform.
  Future<NotificationPermissionStatus> checkPermissionStatus();

  /// Requests notification permission from the user contextually.
  Future<NotificationPermissionStatus> requestPermission();

  /// Schedules the recurring daily quest reminder at [hour]:[minute] in local time.
  Future<NotificationScheduleResult> scheduleDailyReminder({
    required int hour,
    required int minute,
  });

  /// Cancels the scheduled daily reminder.
  Future<void> cancelDailyReminder();

  /// Checks if a daily reminder is currently scheduled with the operating system.
  Future<bool> isDailyReminderScheduled();

  /// Retrieves any notification payload that launched the app from a terminated state.
  Future<String?> getInitialPayload();

  /// Disposes of any resources held by the service.
  void dispose();
}

/// Production implementation of [NotificationService] backed by [FlutterLocalNotificationsPlugin].
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final tz.Location Function()? _locationProvider;
  final tz.TZDateTime Function(int hour, int minute, {tz.Location? location})?
  _nextOccurrenceCalculator;

  bool _isInitialized = false;
  void Function(String? payload)? _onNotificationTap;
  String? _initialPayload;
  bool _checkedInitialPayload = false;

  LocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    tz.Location Function()? locationProvider,
    tz.TZDateTime Function(int hour, int minute, {tz.Location? location})?
    nextOccurrenceCalculator,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _locationProvider = locationProvider,
       _nextOccurrenceCalculator = nextOccurrenceCalculator;

  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    if (_isInitialized) {
      if (onNotificationTap != null) {
        _onNotificationTap = onNotificationTap;
      }
      return;
    }

    _onNotificationTap = onNotificationTap;

    // Initialize time zones
    await NotificationTimezoneHelper.initializeTimeZones();

    // Android settings: use monochrome silhouette icon
    const androidSettings = AndroidInitializationSettings(
      NotificationConstants.androidIcon,
    );

    // iOS Darwin settings: do NOT request permissions automatically on launch
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // Retrieve cold launch details if launched via notification
    if (!_checkedInitialPayload) {
      try {
        final launchDetails = await _plugin.getNotificationAppLaunchDetails();
        if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
          _initialPayload = launchDetails.notificationResponse?.payload;
        }
      } catch (e) {
        debugPrint(
          'LocalNotificationService: Error reading launch details: $e',
        );
      }
      _checkedInitialPayload = true;
    }

    _isInitialized = true;
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    try {
      _onNotificationTap?.call(payload);
    } catch (e) {
      debugPrint('LocalNotificationService: Error in tap callback: $e');
    }
  }

  @override
  Future<String?> getInitialPayload() async {
    if (!_checkedInitialPayload) {
      try {
        final launchDetails = await _plugin.getNotificationAppLaunchDetails();
        if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
          _initialPayload = launchDetails.notificationResponse?.payload;
        }
      } catch (e) {
        debugPrint(
          'LocalNotificationService: Error reading initial payload: $e',
        );
      }
      _checkedInitialPayload = true;
    }
    return _initialPayload;
  }

  @override
  Future<NotificationPermissionStatus> checkPermissionStatus() async {
    try {
      TargetPlatform platform;
      try {
        platform = defaultTargetPlatform;
      } catch (_) {
        return NotificationPermissionStatus.granted;
      }

      if (platform == TargetPlatform.android) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidImpl == null) {
          return NotificationPermissionStatus.granted;
        }
        final enabled = await androidImpl.areNotificationsEnabled();
        if (enabled == true) {
          return NotificationPermissionStatus.granted;
        } else if (enabled == false) {
          return NotificationPermissionStatus.denied;
        }
        return NotificationPermissionStatus.notDetermined;
      } else if (platform == TargetPlatform.iOS) {
        final iosImpl = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (iosImpl == null) {
          return NotificationPermissionStatus.granted;
        }
        final options = await iosImpl.checkPermissions();
        if (options == null) {
          return NotificationPermissionStatus.notDetermined;
        }
        return options.isEnabled
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
      }
      return NotificationPermissionStatus.granted;
    } catch (e) {
      return NotificationPermissionStatus.notDetermined;
    }
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    try {
      TargetPlatform platform;
      try {
        platform = defaultTargetPlatform;
      } catch (_) {
        return NotificationPermissionStatus.granted;
      }

      if (platform == TargetPlatform.android) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidImpl == null) {
          return NotificationPermissionStatus.granted;
        }
        final granted = await androidImpl.requestNotificationsPermission();
        if (granted == true) {
          return NotificationPermissionStatus.granted;
        } else if (granted == false) {
          return NotificationPermissionStatus.denied;
        }
        // If null or on older Android versions where permission is granted by default
        final enabled = await androidImpl.areNotificationsEnabled();
        return (enabled ?? true)
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
      } else if (platform == TargetPlatform.iOS) {
        final iosImpl = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (iosImpl == null) {
          return NotificationPermissionStatus.granted;
        }
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return (granted == true)
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
      }
      return NotificationPermissionStatus.granted;
    } catch (e) {
      debugPrint('LocalNotificationService: Error requesting permission: $e');
      return NotificationPermissionStatus.denied;
    }
  }

  @override
  Future<NotificationScheduleResult> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    try {
      // 1. Ensure service is initialized
      if (!_isInitialized) {
        await initialize(onNotificationTap: _onNotificationTap);
      }

      // 2. Check permission
      final permission = await checkPermissionStatus();
      if (permission == NotificationPermissionStatus.denied ||
          permission == NotificationPermissionStatus.permanentlyDenied) {
        return const NotificationSchedulePermissionDenied();
      }

      // 3. Compute next scheduled occurrence without DST drift
      final location = _locationProvider?.call() ?? tz.local;
      final scheduledDate =
          _nextOccurrenceCalculator?.call(hour, minute, location: location) ??
          NotificationTimezoneHelper.nextOccurrence(
            hour,
            minute,
            location: location,
          );

      // 4. Notification details
      const androidDetails = AndroidNotificationDetails(
        NotificationConstants.dailyReminderChannelId,
        NotificationConstants.dailyReminderChannelName,
        channelDescription: NotificationConstants.dailyReminderChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: NotificationConstants.androidIcon,
        channelShowBadge: true,
        autoCancel: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      // 5. Cancel any previous instance with the same ID first to ensure clean state
      await _plugin.cancel(id: NotificationConstants.dailyReminderId);

      // 6. Schedule time-zone-aware recurring notification
      // Uses inexactAllowWhileIdle to comply with Google Play exact alarm policies
      await _plugin.zonedSchedule(
        id: NotificationConstants.dailyReminderId,
        title: NotificationConstants.dailyReminderTitle,
        body: NotificationConstants.dailyReminderBody,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: NotificationConstants.dailyReminderPayload,
      );

      return NotificationScheduleSuccess(scheduledDate);
    } catch (e, stack) {
      debugPrint(
        'LocalNotificationService: Error scheduling daily reminder: $e\n$stack',
      );
      return NotificationScheduleFailure(
        'Failed to schedule daily reminder: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> cancelDailyReminder() async {
    try {
      await _plugin.cancel(id: NotificationConstants.dailyReminderId);
    } catch (e) {
      debugPrint(
        'LocalNotificationService: Error canceling daily reminder: $e',
      );
    }
  }

  @override
  Future<bool> isDailyReminderScheduled() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.any(
        (request) => request.id == NotificationConstants.dailyReminderId,
      );
    } catch (e) {
      debugPrint(
        'LocalNotificationService: Error checking pending requests: $e',
      );
      return false;
    }
  }

  @override
  void dispose() {
    _onNotificationTap = null;
  }
}

/// Riverpod provider exposing the [NotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = LocalNotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});
