# Bugs, Deficiencies, and Technical Debt: DailyFlow

This document provides a comprehensive inventory of identified bugs, code defects, architectural vulnerabilities, performance bottlenecks, and testing gaps in the **DailyFlow** codebase.

---

## 1. Verified Bugs & Incomplete Functionality

### 1.1 Bug: Settings & Theme Mode Are Ephemeral (Reset on App Restart)
- **Severity**: High (User Frustration)
- **Files Affected**:
  - `lib/core/theme/theme_provider.dart` (`ThemeModeNotifier`)
  - `lib/features/settings/screen/settings_screen.dart` (`_hapticsEnabled`, `_reminderTime`)
- **Root Cause**:
  `ThemeModeNotifier` is an in-memory Riverpod notifier with no backing storage. Furthermore, `SettingsScreen` holds `_hapticsEnabled` and `_reminderTime` in a private `StatefulWidget` state (`_SettingsScreenState`).
- **Impact**: Any customized theme (Light/Dark/System) reverts to Light mode whenever the app process terminates. Selected reminder times and haptic toggles are lost immediately upon leaving the settings screen.

---

### 1.2 Bug: Haptics Toggle Is Dead Code (Global Disconnect)
- **Severity**: Medium
- **Files Affected**:
  - `lib/features/settings/screen/settings_screen.dart` (lines 156–175)
  - `lib/features/habits/screen/widgets/habit_tile.dart` (lines 81, 178)
  - `lib/features/habits/screen/habit_detail_screen.dart` (line 324)
  - `lib/features/focus/screen/focus_screen.dart` (lines 37, 53, 60, 68)
- **Root Cause**:
  The `_hapticsEnabled` boolean in `SettingsScreen` is purely local. The rest of the app's interactive widgets invoke `HapticFeedback.lightImpact()` directly without checking any global setting or provider.
- **Impact**: Users who turn off haptic feedback in settings still receive device vibrations when interacting with habits and timers.

---

### 1.3 Bug: Daily Reminder Picker Is a Placebo UI
- **Severity**: Medium
- **Files Affected**:
  - `lib/features/settings/screen/settings_screen.dart` (lines 177–199)
  - `pubspec.yaml`
- **Root Cause**:
  Selecting a time from `showTimePicker` simply updates `_reminderTime` in local state. No background notification scheduling library (e.g., `flutter_local_notifications` or `workmanager`) is integrated into the application.
- **Impact**: The user expects a daily push notification reminder at their chosen time, but no notification will ever fire.

---

### 1.4 Defect: SQLite Foreign Key Constraints Are Not Enforced
- **Severity**: High (Data Integrity)
- **Files Affected**:
  - `lib/core/database/db_helper.dart` (lines 16–26)
  - `lib/features/habits/data/habit_repository.dart` (lines 106–110)
- **Root Cause**:
  In SQLite, foreign key constraint enforcement is disabled by default for backward compatibility. In `DBHelper._initDB`, the database is opened without an `onConfigure` hook executing:
  ```dart
  onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON;'),
  ```
- **Impact**: The table schema defines `FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE`, but this cascade is ignored by SQLite unless the PRAGMA is active. While `SqliteHabitRepository.deleteHabit` manually deletes from `habit_logs`, atomic cascading is not guaranteed, and manual SQL queries or transaction interruptions will leave orphaned log records.

---

### 1.5 Defect: HabitController Build Method Returns Empty List Synchronously
- **Severity**: Medium (Visual Jitter / Architecture)
- **Files Affected**:
  - `lib/features/habits/controllers/habit_controller.dart` (lines 9–14)
- **Root Cause**:
  ```dart
  @override
  List<Habit> build() {
    _repository = ref.read(habitRepositoryProvider);
    loadHabits();
    return [];
  }
  ```
  The controller exposes `List<Habit>` rather than `AsyncValue<List<Habit>>`. `build()` immediately returns `[]` before the asynchronous `loadHabits()` resolves.
- **Impact**: When any screen listening to `habitControllerProvider` mounts, it receives an empty list for one or more frames, triggering empty states or layout recalculations before popping into the populated list.

---

### 1.6 Defect: Silent Form Validation Failure in HabitFormDialog
- **Severity**: Medium (UX Friction)
- **Files Affected**:
  - `lib/features/habits/screen/widgets/habit_form_dialog.dart` (lines 49–55)
- **Root Cause**:
  ```dart
  void _submit() {
    final title = _titleController.text.trim();
    if (title.isNotEmpty) {
      widget.onSave(title, _selectedCategory, _selectedColor);
      Navigator.of(context).pop();
    }
  }
  ```
  If `title` is empty or whitespace, the method returns without any UI feedback, error text, or form validation notification.
- **Impact**: Users attempting to save an empty habit title receive zero response from the app, creating the impression that the button or app is unresponsive.

---

### 1.7 Defect: Focus/Pomodoro Timer Resets or Lags When Backgrounded
- **Severity**: Medium (Functional Defect)
- **Files Affected**:
  - `lib/features/focus/screen/focus_screen.dart` (lines 35–49)
- **Root Cause**:
  The timer relies on `Timer.periodic(const Duration(seconds: 1))` decrementing `_remainingSeconds`. Mobile operating systems throttle or freeze Dart timers when apps are backgrounded or the display turns off.
- **Impact**: If a user switches to another app or locks their phone during a 25-minute Pomodoro session, the timer does not track elapsed wall-clock time and will pause until the app is reopened.

---

## 2. Duplicate Code & Redundant Artifacts

### 2.1 Deprecated Export Wrappers
- **Files Affected**:
  - `lib/features/habits/screen/focus_screen.dart` (`export '../../focus/screen/focus_screen.dart';`)
  - `lib/features/habits/screen/stats_screen.dart` (`export '../../analytics/screen/stats_screen.dart';`)
  - `lib/features/habits/screen/main_shell.dart` (`export '../../navigation/screen/main_shell.dart';`)
- **Analysis**: These files are redundant re-exports resulting from an incomplete refactor when screen files were reorganized into separate feature directories.

### 2.2 Duplicated Metric Card Widgets
- **Files Affected**:
  - `_DetailStatCard` in `lib/features/habits/screen/habit_detail_screen.dart`
  - `_KpiCard` in `lib/features/analytics/screen/stats_screen.dart`
  - `_buildQuickStat` in `lib/features/profile/screen/profile_screen.dart`
- **Analysis**: Three distinct private widget implementations build nearly identical stat cards (icon inside colored container + bold number + subtle label). They should be consolidated into a unified `KpiStatCard` component.

---

## 3. Performance Bottlenecks

### 3.1 Massive Uncompressed Assets (11MB Bloat)
- **Files Affected**:
  - `assets/icons/app_icon.png` (5.5 MB)
  - `assets/icons/icon_todo B.png` (5.5 MB)
- **Analysis**: 5.5MB for a single app icon is extremely excessive for a mobile binary. A 1024x1024 PNG should typically be 150KB–400KB when properly compressed.
- **Impact**: Unnecessary app bundle bloat, high memory footprint when decoding image bitmaps on the splash screen, and slower initial cold start on low-memory mobile devices.

### 3.2 O(N * D) Recomputations on Widget Builds
- **Files Affected**:
  - `lib/features/habits/screen/widgets/weekly_overview_card.dart`
  - `lib/features/analytics/screen/stats_screen.dart`
- **Analysis**: `_calculateWeeklyCompletionRate()`, `AppDateUtils.getHeatmapData()`, and `AppDateUtils.getWeekdayCompletionRates()` execute nested iteration loops directly inside the `build()` methods of widgets without memoization or selector caching. As the number of habits and completion dates grows over years of usage, this could introduce frame drops during scrolling.

---

## 4. Security & Data Protection Review

- **Data Encryption**: SQLite database file (`daily_flow.db`) is stored in plaintext on the device filesystem. For a basic habit tracker, this is standard, but sensitive habits (e.g., medical routines, therapy, medication tracking) are unencrypted. If privacy is a core value proposition, `sqflite_sqlcipher` should be considered for at-rest encryption.
- **Input Sanitization**: While SQLite parameterized queries (`whereArgs`) are properly used for deletions and queries, habit title length is unbounded, presenting memory exhaustion or rendering overflow risks if a malicious or corrupted input is imported.

---

## 5. Error Handling & Resilience Gaps

- **Repository Exceptions Unhandled**: In `HabitController` (`addHabit`, `editHabit`, `deleteHabit`, `toggleHabitOnDate`), calls to `_repository` have no `try-catch` blocks. If disk write fails or the database is locked, unhandled exceptions will crash the thread or leave state out of sync.
- **No Global Error Widget / Boundary**: `ErrorWidget.builder` is not configured, meaning unexpected runtime UI rendering exceptions will show the default Flutter red/gray screen of death.

---

## 6. Testing Gaps

| Area | Current Coverage | Status | Criticality |
| :--- | :--- | :--- | :--- |
| **Date & Streak Utilities** | 16 unit tests in `test/date_utils_test.dart` | ✅ Excellent | Low |
| **Widget Rendering & Navigation** | 7 tests in `test/widget_test.dart` | ⚠️ Moderate | Medium |
| **Database Operations (`DBHelper`)** | 0 tests | ❌ Untested | High |
| **Repository CRUD (`SqliteHabitRepository`)** | 0 tests | ❌ Untested | High |
| **HabitController State Transitions** | 0 direct unit tests (only tested via fake) | ❌ Untested | High |
| **Pomodoro Timer Engine** | 0 unit tests | ❌ Untested | Medium |
| **Settings & Theme Persistence** | 0 tests | ❌ Untested | High |
