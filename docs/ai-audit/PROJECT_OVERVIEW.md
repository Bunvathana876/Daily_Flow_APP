# Project Overview: DailyFlow

**Project Name:** `daily_flow`  
**Current Version:** `1.0.0+1` (Tagged internally as v2.0 in README)  
**Author / Organization:** Private / Open-Source Project  
**Repository State:** Flutter mobile application targeting iOS, Android, macOS, Linux, Windows, and Web.  
**Analysis Date:** 2026-11-01  

---

## 1. Executive Summary & Purpose

**DailyFlow** is a modern, offline-first personal habit tracker and productivity utility built with Flutter and Dart. The application is designed to help individuals build sustainable daily habits, maintain motivation through streak tracking, gain actionable behavioral insights via historical consistency heatmaps, and practice focused work through an integrated Pomodoro timer.

Unlike heavyweight productivity tools that require cloud account creation, continuous internet connectivity, and monthly subscriptions, DailyFlow operates entirely on-device using a local SQLite database (`sqflite`). It offers immediate startup times, full privacy, and offline functionality.

---

## 2. Target Users

1. **Productivity Enthusiasts & Habit Builders**: Users who follow habit-building methodologies (e.g., *Atomic Habits*, "Don't Break the Chain") seeking a frictionless way to check off daily tasks and visually celebrate momentum.
2. **Students & Knowledge Workers**: Individuals looking for an integrated daily workflow that bridges habit tracking (e.g., studying, coding, reading) with dedicated focus intervals (Pomodoro sessions).
3. **Privacy-Conscious Individuals**: Users who prefer local-only data retention without mandatory account sign-up, tracking telemetry, or cloud synchronization.
4. **Visual Learners & Data-Driven Self-Improvers**: Users who want to visualize consistency patterns over 84-day (12-week) GitHub-style contribution heatmaps and weekday performance graphs.

---

## 3. Problems the Application Solves

| Problem | DailyFlow Solution | Status |
| :--- | :--- | :--- |
| **Lack of habit consistency** | Daily streak counter, best-streak tracking, and 7-day completion progress indicator. | ✅ Implemented |
| **Inconvenient check-in logging** | Quick one-tap check-in on the home screen plus an inline 7-day interactive history strip on each habit card for immediate backfilling. | ✅ Implemented |
| **Context switching between timer & habits** | Integrated Pomodoro focus timer that directly marks the selected habit as complete upon timer conclusion. | ✅ Implemented |
| **Inability to identify failure patterns** | Weekday completion analytics highlighting which days of the week have the lowest adherence. | ✅ Implemented |
| **Long-term consistency visibility** | 12-week GitHub-style heatmap displaying daily completion intensity. | ✅ Implemented |
| **Accidental habit deletion** | Swipe-to-delete with instantaneous "Undo" snackbar action. | ✅ Implemented |
| **Visual fatigue & personalization** | Dark mode toggle, light/dark themes, and custom color categorization per habit. | ⚠️ Partially Implemented (Theme not persisted) |

---

## 4. Current Feature Audit

### 4.1 Implemented & Verified Features

The following features have been inspected in code and confirmed working:

- **Launch Splash Screen (`SplashScreen`)**:
  - Located in `lib/features/splash/screen/splash_screen.dart`.
  - Animated branded intro with scale and fade animations.
  - Asynchronously preloads initial habit data from SQLite before transitioning via `FadeTransition` to `MainShell`.

- **Main Navigation Shell (`MainShell`)**:
  - Located in `lib/features/navigation/screen/main_shell.dart`.
  - 4-tab bottom navigation using Material 3 `NavigationBar` with `IndexedStack` preserving screen states across tab switches:
    1. `Today` (`HomeScreen`)
    2. `Insights` (`StatsScreen`)
    3. `Focus` (`FocusScreen`)
    4. `Profile` (`ProfileScreen`)

- **Today / Habits Screen (`HomeScreen`)**:
  - Located in `lib/features/habits/screen/home_screen.dart`.
  - **Weekly Overview Card (`WeeklyOverviewCard`)**: Displays animated 7-day completion percentage and progress bar.
  - **Category Filter Chips**: Horizontal scroll list filtering habits by category (`All`, `General`, `Health`, `Study`, `Coding`, `Fitness`).
  - **Habit Tile (`HabitTile`)**: Displays habit title, category badge, current streak with fire icon, and an interactive 7-day mini-timeline (`M`, `T`, `W`, `T`, `F`, `S`, `S`) allowing direct date toggling.
  - **Habit CRUD**:
    - Add and edit habits via `HabitFormDialog` (title, category choice chips, accent color selector).
    - Dismissible swipe-to-delete with `SnackBarAction` Undo capability.
  - **Theme Toggle**: Quick dark/light toggle in the top AppBar.

- **Habit Detail Screen (`HabitDetailScreen`)**:
  - Located in `lib/features/habits/screen/habit_detail_screen.dart`.
  - Displays KPI metric cards: *Current Streak*, *Best Streak*, and *Total Days*.
  - Full interactive monthly calendar grid with previous/next month navigation for auditing and backfilling completed days.
  - Quick edit and delete actions in the AppBar.

- **Insights & Analytics (`StatsScreen`)**:
  - Located in `lib/features/analytics/screen/stats_screen.dart`.
  - Top KPI cards: *Total Check-ins*, *Best Streak*, *Active Habits*.
  - **12-Week Heatmap Grid (`_HeatmapGrid`)**: 84-day contribution grid displaying relative completion ratios with a 5-step intensity legend.
  - **Weekday Bar Chart (`_WeekdayBarChart`)**: Animated vertical bars showing percentage completion from Monday to Sunday.

- **Focus / Pomodoro Screen (`FocusScreen`)**:
  - Located in `lib/features/focus/screen/focus_screen.dart`.
  - Habit dropdown selection linked to existing active habits.
  - Preset duration chips (`15 min`, `25 min`, `45 min`, `60 min`).
  - Animated circular progress indicator countdown with Start, Pause, and Reset controls.
  - Auto-checks off the linked habit for today upon timer completion.

- **User Profile Screen (`ProfileScreen`)**:
  - Located in `lib/features/profile/screen/profile_screen.dart`.
  - Static user profile card with avatar and rank title ("DailyFlow Champion", "Level 3").
  - Quick stat summary (*Active Habits*, *Total Check-ins*, *Best Streak*).
  - Achievement Badges (*7-Day Club*, *Habit Hero*, *Focused Mind*, *Century Flow*) with dynamic lock/unlock state based on database records.
  - Category breakdown summary showing habit count per category.

- **Settings Screen (`SettingsScreen`)**:
  - Located in `lib/features/settings/screen/settings_screen.dart`.
  - Accessible from the Profile screen.
  - Segmented button for theme mode (`Light`, `Dark`, `System`).
  - Dark mode quick toggle switch.
  - Preference switches for Haptic Feedback and Daily Reminder time picker.

---

## 5. Incomplete, Missing, or Stubbed Features

Despite the functional core, several features are incomplete, mockups, or non-functional:

1. **Theme Mode & Settings Persistence**:
   - `themeModeProvider` is an in-memory `Notifier<ThemeMode>`. The selected theme reverts to `ThemeMode.light` whenever the app is restarted.
   - `_hapticsEnabled` and `_reminderTime` in `SettingsScreen` are stored only in local `_SettingsScreenState`. They are destroyed when leaving the screen and are never written to disk.

2. **Notifications & Daily Reminders**:
   - The "Daily Reminder Time" time picker in `SettingsScreen` is a placeholder UI. No local notification plugin (such as `flutter_local_notifications`) is installed, and no OS alarms are scheduled.

3. **Global Haptics Setting Integration**:
   - The Haptic Feedback toggle in `SettingsScreen` does not affect the rest of the application. `HabitTile`, `FocusScreen`, and `HabitDetailScreen` directly invoke `HapticFeedback.lightImpact()` without reading any settings provider.

4. **Background Pomodoro Timer Execution**:
   - The Pomodoro timer relies strictly on a standard Dart `Timer.periodic(const Duration(seconds: 1))` inside UI state. If the user navigates away or puts the app into the background / locks the screen, the timer stops ticking or gets paused by the mobile OS.

5. **Profile Customization**:
   - The user profile ("DailyFlow Champion", "Level 3", avatar) is hardcoded. There is no user profile data model or screen to edit user name, goal settings, or avatar.

6. **Custom Categories & Custom Colors**:
   - Habit categories and accent colors are restricted to hardcoded lists in `AppConstants`. Users cannot add, edit, or delete categories or pick arbitrary hex colors.

7. **Data Backup & Restore / Export**:
   - There is no mechanism to export data (JSON/CSV) or restore data upon device migration, risking data loss on app re-installation.

8. **Habit Frequency & Scheduling**:
   - All habits are treated as daily habits. There is currently no support for alternate schedules (e.g., "3 times a week", "weekdays only", or specific day selection).

---

## 6. Current Product Value & Future Scope

DailyFlow already possesses a solid, polished visual foundation and responsive user interactions. The core habit-tracking loop and analytical visualizations are visually compelling and fast.

However, moving DailyFlow from a prototype/MVP to a production-grade utility requires addressing local state persistence, background timer resilience, local notification support, database integrity hardening, and expanded habit scheduling.
