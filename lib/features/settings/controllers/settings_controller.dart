import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';

class SettingsState {
  final ThemeMode themeMode;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final NotificationPermissionStatus permissionStatus;
  final String? reminderErrorMessage;
  final bool isLoaded;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.hapticsEnabled = true,
    this.soundEnabled = false,
    this.reminderEnabled = false,
    this.reminderHour = 8,
    this.reminderMinute = 0,
    this.permissionStatus = NotificationPermissionStatus.notDetermined,
    this.reminderErrorMessage,
    this.isLoaded = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? hapticsEnabled,
    bool? soundEnabled,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    NotificationPermissionStatus? permissionStatus,
    String? reminderErrorMessage,
    bool clearErrorMessage = false,
    bool? isLoaded,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      reminderErrorMessage: clearErrorMessage
          ? null
          : (reminderErrorMessage ?? this.reminderErrorMessage),
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

class SettingsController extends Notifier<SettingsState> {
  static const String themePrefKey = 'daily_flow_theme_mode';
  static const String hapticsPrefKey = 'daily_flow_haptics_enabled';
  static const String soundPrefKey = 'daily_flow_sound_enabled';
  static const String reminderEnabledPrefKey = 'daily_flow_reminder_enabled';
  static const String reminderHourPrefKey = 'daily_flow_reminder_hour';
  static const String reminderMinutePrefKey = 'daily_flow_reminder_minute';

  SharedPreferences? _prefs;

  NotificationService get _notificationService =>
      ref.read(notificationServiceProvider);

  @override
  SettingsState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    if (_prefs != null) {
      final initialState = _buildStateFromPrefs(_prefs!);
      Future.microtask(() => checkPermissionAndReconcile());
      return initialState;
    } else {
      Future.microtask(() => _asyncLoad());
      return const SettingsState();
    }
  }

  SettingsState _buildStateFromPrefs(SharedPreferences prefs) {
    final themeStr = prefs.getString(themePrefKey);
    final haptics = prefs.getBool(hapticsPrefKey) ?? true;
    final sound = prefs.getBool(soundPrefKey) ?? false;
    final reminderEnabled = prefs.getBool(reminderEnabledPrefKey) ?? false;
    final reminderHour = prefs.getInt(reminderHourPrefKey) ?? 8;
    final reminderMinute = prefs.getInt(reminderMinutePrefKey) ?? 0;

    // Migrate any legacy 'light' or 'system' preference to 'dark'
    if (themeStr != 'dark') {
      prefs.setString(themePrefKey, 'dark');
    }

    return SettingsState(
      themeMode: ThemeMode.dark,
      hapticsEnabled: haptics,
      soundEnabled: sound,
      reminderEnabled: reminderEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      isLoaded: true,
    );
  }

  Future<void> _asyncLoad() async {
    _prefs = await SharedPreferences.getInstance();
    state = _buildStateFromPrefs(_prefs!);
    await checkPermissionAndReconcile();
  }

  /// Verifies current permission status and reconciles notification schedule if needed.
  Future<void> checkPermissionAndReconcile() async {
    try {
      final status = await _notificationService.checkPermissionStatus();
      state = state.copyWith(permissionStatus: status);

      // If user enabled reminders, ensure the operating system schedule is consistent
      if (state.reminderEnabled) {
        if (status == NotificationPermissionStatus.denied ||
            status == NotificationPermissionStatus.permanentlyDenied) {
          // System permission was revoked outside the app
          state = state.copyWith(
            reminderErrorMessage:
                'Notification permission was revoked in system settings.',
          );
        } else if (status == NotificationPermissionStatus.granted) {
          final isScheduled = await _notificationService
              .isDailyReminderScheduled();
          if (!isScheduled) {
            // Re-schedule reminder to restore missing schedule (e.g. after time zone change)
            await _notificationService.scheduleDailyReminder(
              hour: state.reminderHour,
              minute: state.reminderMinute,
            );
          }
        }
      }
    } catch (_) {
      // Gracefully ignore platform channel errors in non-mobile test environments
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    // DailyFlow is Dark Mode only; always enforce ThemeMode.dark
    state = state.copyWith(themeMode: ThemeMode.dark);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(themePrefKey, 'dark');
  }

  Future<void> toggleTheme() async {
    // DailyFlow is Dark Mode only
    await setThemeMode(ThemeMode.dark);
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    state = state.copyWith(hapticsEnabled: enabled);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool(hapticsPrefKey, enabled);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool(soundPrefKey, enabled);
  }

  /// Enables or disables daily reminder notifications transactionally.
  ///
  /// When enabling:
  /// 1. Requests notification permission contextually.
  /// 2. If granted, schedules recurring reminder with [NotificationService].
  /// 3. If scheduling succeeds, persists preference.
  /// 4. If permission denied or scheduling fails, leaves setting off and displays error.
  Future<bool> setReminderEnabled(bool enabled) async {
    _prefs ??= await SharedPreferences.getInstance();

    if (!enabled) {
      // Disabling reminder: cancel schedule and update preferences
      await _notificationService.cancelDailyReminder();
      await _prefs?.setBool(reminderEnabledPrefKey, false);
      state = state.copyWith(reminderEnabled: false, clearErrorMessage: true);
      return true;
    }

    // Enabling reminder:
    // 1. Request notification permission contextually
    final permission = await _notificationService.requestPermission();
    state = state.copyWith(permissionStatus: permission);

    if (permission == NotificationPermissionStatus.denied ||
        permission == NotificationPermissionStatus.permanentlyDenied) {
      state = state.copyWith(
        reminderEnabled: false,
        reminderErrorMessage:
            'Notification permission is needed to receive daily quest reminders. Please enable notifications in your device settings.',
      );
      await _prefs?.setBool(reminderEnabledPrefKey, false);
      return false;
    }

    // 2. Permission granted, schedule daily reminder
    final result = await _notificationService.scheduleDailyReminder(
      hour: state.reminderHour,
      minute: state.reminderMinute,
    );

    if (result is NotificationScheduleSuccess) {
      await _prefs?.setBool(reminderEnabledPrefKey, true);
      state = state.copyWith(
        reminderEnabled: true,
        permissionStatus: NotificationPermissionStatus.granted,
        clearErrorMessage: true,
      );
      return true;
    } else if (result is NotificationSchedulePermissionDenied) {
      state = state.copyWith(
        reminderEnabled: false,
        reminderErrorMessage:
            'Notification permission is required. Please check system settings.',
      );
      await _prefs?.setBool(reminderEnabledPrefKey, false);
      return false;
    } else if (result is NotificationScheduleFailure) {
      state = state.copyWith(
        reminderEnabled: false,
        reminderErrorMessage: result.message,
      );
      await _prefs?.setBool(reminderEnabledPrefKey, false);
      return false;
    }

    return false;
  }

  /// Updates the daily reminder wall-clock time and reschedules if reminders are active.
  Future<bool> setReminderTime(TimeOfDay time) async {
    _prefs ??= await SharedPreferences.getInstance();

    final prevHour = state.reminderHour;
    final prevMinute = state.reminderMinute;

    // Optimistically update time values in state and prefs
    state = state.copyWith(
      reminderHour: time.hour,
      reminderMinute: time.minute,
      clearErrorMessage: true,
    );
    await _prefs?.setInt(reminderHourPrefKey, time.hour);
    await _prefs?.setInt(reminderMinutePrefKey, time.minute);

    // If reminders are currently active, reschedule with new time
    if (state.reminderEnabled) {
      final result = await _notificationService.scheduleDailyReminder(
        hour: time.hour,
        minute: time.minute,
      );

      if (result is! NotificationScheduleSuccess) {
        // Rollback or display error message
        state = state.copyWith(
          reminderHour: prevHour,
          reminderMinute: prevMinute,
          reminderErrorMessage:
              'Failed to update reminder schedule. Kept previous time.',
        );
        await _prefs?.setInt(reminderHourPrefKey, prevHour);
        await _prefs?.setInt(reminderMinutePrefKey, prevMinute);
        return false;
      }
    }

    return true;
  }

  /// Clears any transient reminder error banner.
  void clearReminderErrorMessage() {
    state = state.copyWith(clearErrorMessage: true);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
