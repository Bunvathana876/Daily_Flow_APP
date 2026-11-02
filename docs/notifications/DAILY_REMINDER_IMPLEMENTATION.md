# DailyFlow 3.0: Production-Quality Daily Reminder Notifications

This document details the architecture, configuration, implementation, testing, and operational verification of DailyFlow 3.0's local reminder notification system.

---

## 1. Existing Implementation Audit

Prior to this implementation:
- **UI State**: The `SettingsScreen` included a "Daily Reminder Time" list tile backed only by transient local widget state (`TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0)`).
- **Missing Persistence**: Picking a time did not persist the chosen hour and minute to `SharedPreferences`. Restarting the application immediately reverted the displayed time to 8:00 AM.
- **No Scheduling or Services**: No notification plugin, background receiver, permission handling, or scheduling service existed. No notifications could ever fire.
- **Theme & Navigation**: DailyFlow 3.0 is Dark Mode only with an RPG theme (warm gold accents, deep midnight navy background). Navigation is powered by `MainShell` using an `IndexedStack` to preserve state across tabs (Today, Insights, Focus, Profile).

---

## 2. Dependencies and Versions

The notification subsystem introduces minimal, production-grade dependencies verified for compatibility with Flutter 3.47.9 and Dart 3.13.7:

| Dependency | Version | Purpose |
| :--- | :--- | :--- |
| `flutter_local_notifications` | `^22.3.3` | Cross-platform local notification scheduling, channel management, and interaction handlers |
| `timezone` | `^0.11.2` | IANA timezone database and wall-clock datetime math |
| `flutter_timezone` | `^5.1.1` | Native platform lookup for the device's current IANA timezone string |
| `flutter_riverpod` | `^3.3.2` | State management and dependency injection |
| `shared_preferences` | `^2.5.6` | Offline-first key-value persistence for settings and reminder state |

No remote notification services (e.g. Firebase Cloud Messaging) or network dependencies were introduced.

---

## 3. Architecture

The notification system follows DailyFlow's offline-first layered architecture:

```
┌────────────────────────────────────────────────────────┐
│                   UI Layer                             │
│   SettingsScreen  /  MainShell  /  DailyFlowApp        │
└──────────────────────────┬─────────────────────────────┘
                           │ watches / dispatches
┌──────────────────────────▼─────────────────────────────┐
│                 Controller Layer                       │
│    SettingsController (Riverpod Notifier)              │
│    MainShellTabNotifier                                │
└─────────────┬────────────────────────────┬─────────────┘
              │ reads / persists           │ invokes
┌─────────────▼───────────────┐ ┌──────────▼─────────────┐
│      Persistence Layer      │ │      Service Layer     │
│      SharedPreferences      │ │   NotificationService  │
└─────────────────────────────┘ └──────────┬─────────────┘
                                           │ delegates
                                ┌──────────▼─────────────┐
                                │   Timezone & Platform  │
                                │   TimezoneHelper       │
                                │   LocalNotifications   │
                                └────────────────────────┘
```

### Components

1. **`NotificationService` (Interface) & `LocalNotificationService` (Implementation)** (`lib/core/services/notification_service.dart`):
   - Encapsulates plugin initialization, permission queries, schedule creation, cancellations, pending request queries, and tap callbacks.
   - Decoupled from concrete OS bindings via dependency injection (`FlutterLocalNotificationsPlugin`, timezone provider), allowing 100% deterministic unit testing without platform channel crashes.
   - Stable Notification ID: `1001` (`NotificationConstants.dailyReminderId`).
   - Stable Notification Channel: `daily_quest_reminders` (`NotificationConstants.dailyReminderChannelId`).
   - Stable Action Payload: `daily_quest_reminder` (`NotificationConstants.dailyReminderPayload`).

2. **`NotificationTimezoneHelper`** (`lib/core/utils/notification_timezone_helper.dart`):
   - Initializes tzdb data and binds device local timezone using `FlutterTimezone`.
   - Computes next local occurrences safely without Daylight Saving Time drift.

3. **`SettingsController` & `SettingsState`** (`lib/features/settings/controllers/settings_controller.dart`):
   - Manages reminder preferences transactionally (`reminderEnabled`, `reminderHour`, `reminderMinute`, `permissionStatus`, `reminderErrorMessage`).
   - Enforces transactional rollbacks: if permission is denied or scheduling fails, reminders are not marked active.
   - Provides reconciliation on startup and app resume.

4. **`MainShellTabNotifier`** (`lib/features/navigation/screen/main_shell.dart`):
   - Riverpod notifier driving `IndexedStack` tab selection (Index 0 = Today).
   - Allows seamless tab switching upon notification taps without recreating navigation routes or resetting state.

---

## 4. Notification Permission Flow

Permissions are requested **contextually** only when the user explicitly enables reminders. Permissions are never requested automatically on app launch.

```
User toggles "Daily Reminders" ON
                 │
                 ▼
SettingsController.setReminderEnabled(true)
                 │
                 ▼
NotificationService.requestPermission()
                 │
         ┌───────┴────────┐
         ▼                ▼
     Granted            Denied / Permanently Denied
         │                │
         ▼                ▼
Schedule Reminder    Keep toggle OFF in UI
         │           Persist reminderEnabled = false
   ┌─────┴─────┐     Show contextual explanation banner
   ▼           ▼
Success     Failure
   │           │
   ▼           ▼
Toggle ON    Rollback toggle OFF
Persist      Show friendly error message
```

- **Android 13+ (API 33+)**: Invokes `requestNotificationsPermission()`.
- **iOS**: Invokes `requestPermissions(alert: true, badge: true, sound: true)`.
- **Pre-Android 13**: Automatically granted by platform; verified via `areNotificationsEnabled()`.

---

## 5. Scheduling and Time-Zone Behavior

### Preventing Daylight Saving Time (DST) Drift
A common failure mode in recurring mobile notifications is adding 24 hours (`Duration(days: 1)`) repeatedly. Because spring-forward days have 23 hours and fall-back days have 25 hours, duration addition causes reminders to shift permanently by 1 hour (e.g. 8:00 AM shifting to 9:00 AM or 7:00 AM).

**Solution**:
1. `NotificationTimezoneHelper.nextOccurrence` constructs the initial `TZDateTime` using the calendar year, month, and day of tomorrow, while preserving the exact wall-clock `hour` and `minute`.
2. The schedule is handed to `zonedSchedule` with `matchDateTimeComponents: DateTimeComponents.time`.
3. On iOS, `UNCalendarNotificationTrigger` matches calendar components natively every day.
4. On Android, `flutter_local_notifications` recalculates the next alarm on each trigger matching the time component.
5. On app resume (`AppLifecycleState.resumed`), `checkPermissionAndReconcile` checks if time zone or alarms were altered and reschedules if necessary.

---

## 6. Android Platform Configuration

### Permissions (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### Receivers (`android/app/src/main/AndroidManifest.xml`)
```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
    </intent-filter>
</receiver>
```

### Desugaring (`android/app/build.gradle.kts`)
Enabled Java 8+ API desugaring for `java.time` support across all supported Android API levels:
```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

### Inexact Alarms & Google Play Compliance
- **No `USE_EXACT_ALARM` or `SCHEDULE_EXACT_ALARM`**: Habit reminders are non-critical wall-clock cues, not alarm clocks. Requesting exact alarm permissions exposes apps to Google Play rejection or revoking by users.
- **`AndroidScheduleMode.inexactAllowWhileIdle`**: Allows Android's AlarmManager to batch reminders energy-efficiently while still waking up the device during Doze mode within a short OS tolerance window.

### Status Bar Icon
- Created monochrome alpha-only vector drawable `android/app/src/main/res/drawable/ic_notification.xml` featuring DailyFlow's adventure shield crest outline and star.
- Avoids Android's solid white square bug caused by rendering full-color launcher icons in the status bar.

---

## 7. iOS Platform Configuration

### Deployment Target (`ios/Podfile`)
```ruby
platform :ios, '15.0'
```

### AppDelegate Configuration (`ios/Runner/AppDelegate.swift`)
Configured `UNUserNotificationCenterDelegate` to route foreground presentations and tap interactions to Flutter:
```swift
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Foreground Behavior
`DarwinNotificationDetails` specifies `presentAlert: true`, `presentBadge: true`, and `presentSound: true`. Notifications can display banner alerts even if the user currently has DailyFlow open.

---

## 8. Notification Tap Navigation

When a user taps a DailyFlow notification:
1. **Cold Launch (Terminated App)**:
   - `getNotificationAppLaunchDetails()` extracts the payload.
   - `handleNotificationResponse` queues selection of Tab 0 (`mainShellTabProvider`).
   - `SplashScreen` completes standard database and profile initialization.
   - `SplashScreen` pushes `MainShell`, which opens directly on "Today / Quest Dashboard".
2. **Background Tap**:
   - `onDidReceiveNotificationResponse` receives payload.
   - `handleNotificationResponse` selects Tab 0 (`mainShellTabProvider.notifier.selectTab(0)`).
   - Pops any modal or pushed route (e.g. `SettingsScreen`) via `appNavigatorKey.currentState?.popUntil((route) => route.isFirst)`.
3. **Foreground Tap**:
   - Switches `MainShell` to Tab 0 smoothly without navigation glitches.
4. **Safety Invariants**:
   - Habit database is never initialized twice.
   - Quests are never marked completed by a tap.
   - No XP or achievements are awarded by a tap.
   - The Focus timer running in the Focus tab is not reset (preserved via `IndexedStack`).
   - If payload is unknown or null, the app opens normally without error.

---

## 9. Persistence Behavior

All settings persist offline in `SharedPreferences`:

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `daily_flow_theme_mode` | `String` | `'dark'` | App theme (enforced dark mode) |
| `daily_flow_haptics_enabled` | `bool` | `true` | Haptic feedback toggle |
| `daily_flow_sound_enabled` | `bool` | `false` | Sound feedback toggle |
| `daily_flow_reminder_enabled` | `bool` | `false` | Whether daily reminders are active |
| `daily_flow_reminder_hour` | `int` | `8` | Reminder wall-clock hour (0–23) |
| `daily_flow_reminder_minute` | `int` | `0` | Reminder wall-clock minute (0–59) |

---

## 10. Error Handling

- **Permission Denied**: Switch remains OFF. An inline alert banner and transient SnackBar explain that notifications must be enabled in device settings.
- **Scheduling Exception**: If platform scheduling throws, the switch rolls back to OFF, the error message is captured in `SettingsState`, and preferences remain `false`.
- **Time Picker Failure**: If rescheduling at a newly selected time fails, the controller rolls back to the previous hour/minute and displays an error SnackBar.
- **Timezone Lookup Failure**: If native timezone lookup throws or returns an unrecognized string, the system defaults cleanly to `'UTC'` without crashing.

---

## 11. Automated Test Results

Total test suite across DailyFlow 3.0: **221 tests passed (100% success)**.

### New Test Suites
- **`test/notification_timezone_test.dart`** (10 tests):
  - Validates today vs tomorrow scheduling based on past/future times.
  - Validates exact minute edge cases.
  - Validates month boundaries (Oct 31 -> Nov 1) and year boundaries (Dec 31 -> Jan 1).
  - Validates leap year rollover (Feb 28 -> Feb 29 in 2028).
  - Validates Daylight Saving spring forward (no 1-hour jump).
  - Validates Daylight Saving fall back (no 1-hour regression).
  - Validates fallback to UTC on invalid zone strings.
- **`test/notification_service_test.dart`** (9 tests):
  - Validates single idempotent initialization.
  - Validates Android monochrome icon and Darwin permission flags on init.
  - Validates stable ID `1001`, `inexactAllowWhileIdle`, and `DateTimeComponents.time`.
  - Validates prior schedule cancellation on rescheduling.
  - Validates cancellation of reminders.
  - Validates pending notification check.
  - Validates tap callback dispatch.
  - Validates cold-launch payload retrieval.
  - Validates failure handling without unhandled exceptions.
- **`test/settings_reminders_test.dart`** (10 tests):
  - Validates default reminder state.
  - Validates transactional enablement when permission is granted.
  - Validates rollback and error state when permission is denied.
  - Validates rollback when scheduling fails.
  - Validates cancellation on disable.
  - Validates rescheduling on time change while active.
  - Validates time change while disabled (persists without scheduling).
  - Validates rollback on failed time change.
  - Validates restoration from `SharedPreferences`.
  - Validates reconciliation when schedule was dropped by OS.
- **`test/settings_reminders_ui_test.dart`** (3 tests):
  - Renders Preferences section, Daily Reminders switch, and Reminder Time tile.
  - Validates toggle ON when permission granted shows active status.
  - Validates toggle ON when permission denied shows error banner and dismiss button.
- **`test/notification_navigation_test.dart`** (4 tests):
  - Validates tap with valid payload switches tab to Today (index 0).
  - Validates tap pops pushed `SettingsScreen` back to `MainShell`.
  - Validates tap with invalid or null payload does not mutate tabs or crash.
  - Validates tap leaves habits, XP, and focus timer completely intact.

---

## 12. Manual Device Testing Checklist

Follow these steps on physical hardware or simulators to verify end-to-end delivery:

### Android Verification
1. **Fresh Install / First Run**:
   - Launch app. Verify no notification permission prompt appears on initial launch.
2. **Enable Daily Reminders**:
   - Go to Profile -> Settings.
   - Toggle **Daily Reminders** ON.
   - Verify Android 13+ runtime dialog appears: "Allow DailyFlow to send you notifications?".
   - Tap **Allow**.
   - Verify toggle turns ON and subtitle changes to "Active — daily quests reminder scheduled".
3. **Schedule Immediate Reminder**:
   - Tap **Daily Reminder Time**.
   - Select a time 2–3 minutes ahead of current time.
   - Send DailyFlow to background and lock device screen.
   - Wait for reminder window.
   - Verify notification arrives with title: **"Your Daily Quests Await!"**, body: **"A new day, a new adventure. Ready to make progress?"**, and the white adventure shield status bar icon.
4. **Notification Interaction**:
   - Tap the notification.
   - Verify app opens and immediately displays the **Today / Quest Dashboard** tab.
   - Verify habit checkmarks and XP are unchanged.
5. **Cold-Launch Test**:
   - Schedule a reminder 2 minutes ahead.
   - Swipe DailyFlow out of recent apps (terminate process).
   - When notification appears, tap it.
   - Verify splash screen launches, initializes, and transitions directly to Today's Quests.
6. **Disable Reminders**:
   - Open Settings, toggle Daily Reminders OFF.
   - Wait past previous reminder time.
   - Verify no notification fires.
7. **Permission Revocation Test**:
   - With reminders ON, go to Android App Info -> Notifications -> Turn OFF.
   - Return to DailyFlow.
   - Verify app detects revoked permission on resume and shows explanation banner.

### iOS Verification
1. **Contextual Permission**:
   - Launch app. Verify no prompt on launch.
   - Open Settings, toggle Daily Reminders ON.
   - Verify iOS system prompt: "DailyFlow Would Like to Send You Notifications".
   - Tap **Allow**.
2. **Delivery & Interaction**:
   - Schedule a reminder 2–3 minutes ahead.
   - Lock screen or put app in background.
   - Verify banner appears with sound and adventure text.
   - Tap banner; verify app opens on Today tab.
3. **Foreground Alert**:
   - Keep app open in foreground when reminder fires.
   - Verify banner drops down at top of screen (configured via `DarwinNotificationDetails`).

---

## 13. Known Platform Limitations

1. **Android Inexact Alarm Batching**:
   - Because `AndroidScheduleMode.inexactAllowWhileIdle` is used to adhere to Google Play policies and preserve battery life, Android OS may batch alarm delivery within a 1–10 minute window depending on device OEM battery management and Doze mode state.
2. **Device Reboot Delivery**:
   - On Android, `ScheduledNotificationBootReceiver` automatically reschedules alarms upon `BOOT_COMPLETED`. However, on certain heavily customized Android skins (e.g. Xiaomi MIUI / Huawei EMUI), "Auto-start" permissions may need to be enabled by the user in device settings for background receivers to run post-boot.
3. **iOS Notification Center Retention**:
   - iOS retains notifications in Notification Center until dismissed by the user or clicked. Delivering multiple notifications without tapping them will accumulate in the notification group.
