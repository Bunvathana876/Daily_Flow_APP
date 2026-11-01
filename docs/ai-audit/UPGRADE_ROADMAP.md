# Upgrade Roadmap: DailyFlow

This document outlines a phased engineering roadmap to modernize **DailyFlow**, elevate its architecture to enterprise-grade quality, resolve known bugs, and introduce high-impact productivity capabilities.

---

## Roadmap Overview & Prioritization Matrix

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        UPGRADE ROADMAP PHASES                          │
├────────────────────────────────────────────────────────────────────────┤
│  Phase 1: Critical Fixes & Data Integrity          (Immediate)         │
│  Phase 2: UI/UX Modernization & Accessibility      (High Impact)       │
│  Phase 3: Existing Feature Hardening               (Product Depth)     │
│  Phase 4: High-Value New Features                  (Expansion)         │
│  Phase 5: Performance, Security & Automated CI/CD  (Production Ready)  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Priority 1: Critical Fixes & Data Integrity

### 1.1 Persistent User Settings & Preferences
- **Why Needed**: Theme mode, haptics toggle, and reminder preferences currently reset on app restart because they reside in-memory. User preferences must persist across sessions.
- **Affected Files**:
  - `pubspec.yaml` (Add `shared_preferences`)
  - `lib/core/theme/theme_provider.dart`
  - `lib/features/settings/screen/settings_screen.dart`
  - `lib/features/settings/controllers/settings_controller.dart` (New)
- **Implementation Difficulty**: Low (1–2 hours)

### 1.2 Enable SQLite Foreign Key Enforcement (`PRAGMA foreign_keys = ON;`)
- **Why Needed**: Prevents orphaned records in `habit_logs` if a habit is deleted outside of a manual script or during interrupted operations.
- **Affected Files**:
  - `lib/core/database/db_helper.dart` (Add `onConfigure` handler in `openDatabase`)
- **Implementation Difficulty**: Very Low (15 mins)

### 1.3 Asynchronous State Representation in HabitController (`AsyncValue`)
- **Why Needed**: Prevents cold-start flashing of the empty state while habits are loading from SQLite. Allows clean presentation of skeleton loading placeholders.
- **Affected Files**:
  - `lib/features/habits/controllers/habit_controller.dart`
  - `lib/features/habits/screen/home_screen.dart`
  - `lib/features/analytics/screen/stats_screen.dart`
- **Implementation Difficulty**: Medium (2–3 hours)

### 1.4 Form Validation & Error Feedback in `HabitFormDialog`
- **Why Needed**: Tapping "Save" with an empty title currently fails silently without user feedback.
- **Affected Files**:
  - `lib/features/habits/screen/widgets/habit_form_dialog.dart`
- **Implementation Difficulty**: Low (30 mins)

### 1.5 Optimize Massive App Icon Assets
- **Why Needed**: Two PNG files in `assets/icons/` consume 11MB of disk and uncompressed RAM during app launch.
- **Affected Files**:
  - `assets/icons/app_icon.png`
  - `assets/icons/icon_todo B.png`
- **Implementation Difficulty**: Very Low (Asset compression using `pngquant` / `tinypng`)

---

## Priority 2: UI/UX Modernization & Accessibility

### 2.1 Modern Bottom Sheet Form with Draggable Expansion
- **Why Needed**: Replaces the desktop-style `AlertDialog` with a modern, touch-friendly bottom sheet (`showModalBottomSheet`) that adjusts smoothly with keyboard appearance.
- **Affected Files**:
  - `lib/features/habits/screen/widgets/habit_form_sheet.dart` (Refactor `habit_form_dialog.dart`)
  - `lib/features/habits/screen/home_screen.dart`
- **Implementation Difficulty**: Medium (2 hours)

### 2.2 Expand Touch Targets on 7-Day Mini Timeline
- **Why Needed**: Current 28x28px circles violate WCAG 2.1 target size standards (minimum 48x48px hit area), resulting in mis-taps on small screens.
- **Affected Files**:
  - `lib/features/habits/screen/widgets/habit_tile.dart`
- **Implementation Difficulty**: Low (45 mins)

### 2.3 Rich Empty States & Onboarding CTAs
- **Why Needed**: Currently displays plain gray text `"No habits yet."`. Replacing with an engaging vector illustration and a primary "Create Habit" button improves day-1 activation.
- **Affected Files**:
  - `lib/features/habits/screen/home_screen.dart`
  - `lib/features/analytics/screen/stats_screen.dart`
- **Implementation Difficulty**: Low (1–2 hours)

### 2.4 Unified Global Design Tokens & Shared KPI Card
- **Why Needed**: Eliminates duplicate micro-stat card implementations (`_DetailStatCard`, `_KpiCard`, `_buildQuickStat`) and establishes a clean design token system.
- **Affected Files**:
  - `lib/core/widgets/kpi_stat_card.dart` (New)
  - `lib/features/habits/screen/habit_detail_screen.dart`
  - `lib/features/analytics/screen/stats_screen.dart`
  - `lib/features/profile/screen/profile_screen.dart`
- **Implementation Difficulty**: Low to Medium (1.5 hours)

---

## Priority 3: Existing Feature Improvements

### 3.1 Background-Resilient Pomodoro Timer (Wall-Clock Synchronization)
- **Why Needed**: Timer currently lags or resets when the app is placed in the background or the screen locks. Calculating time against a target `DateTime` timestamp guarantees true wall-clock tracking.
- **Affected Files**:
  - `lib/features/focus/screen/focus_screen.dart`
- **Implementation Difficulty**: Medium (2–3 hours)

### 3.2 True Local Notifications for Daily Reminders
- **Why Needed**: Enables actual daily reminders at the user's scheduled time using platform alarm schedulers.
- **Affected Files**:
  - `pubspec.yaml` (Add `flutter_local_notifications` & `timezone`)
  - `lib/core/services/notification_service.dart` (New)
  - `lib/features/settings/screen/settings_screen.dart`
- **Implementation Difficulty**: Medium to High (3–4 hours)

### 3.3 Connected Global Haptics Service
- **Why Needed**: Connects the Haptics setting toggle in `SettingsScreen` to all app check-in interactions.
- **Affected Files**:
  - `lib/core/services/haptics_service.dart` (New)
  - `lib/features/habits/screen/widgets/habit_tile.dart`
  - `lib/features/focus/screen/focus_screen.dart`
  - `lib/features/habits/screen/habit_detail_screen.dart`
- **Implementation Difficulty**: Low (1 hour)

### 3.4 Custom Categories & Color Customization
- **Why Needed**: Allows users to define their own habit categories and choose from an expanded color palette or custom hex picker.
- **Affected Files**:
  - `lib/core/constants/app_constants.dart`
  - `lib/core/database/db_helper.dart` (Optional category table or JSON list)
  - `lib/features/habits/screen/widgets/habit_form_dialog.dart`
- **Implementation Difficulty**: Medium (2–3 hours)

---

## Priority 4: High-Value New Feature Recommendations

### 4.1 Data Backup, Export, and Import (JSON / CSV)
- **Why Needed**: Since DailyFlow is offline-first, users need a way to backup their streak history or transfer habits when switching devices.
- **Affected Files**:
  - `lib/core/services/backup_service.dart` (New)
  - `lib/features/settings/screen/settings_screen.dart`
- **Implementation Difficulty**: Medium (3 hours)

### 4.2 Habit Scheduling (Custom Frequency / Weekday Selection)
- **Why Needed**: Not all habits occur daily (e.g., "Gym on Mon/Wed/Fri", "Weekly Review on Sunday"). Allows setting custom target days and calculates streaks accordingly.
- **Affected Files**:
  - `lib/features/habits/models/habit.dart` (Add `targetDays` bitmask or list)
  - `lib/core/utils/date_utils.dart` (Adjust streak math for scheduled habits)
  - `lib/core/database/db_helper.dart` (Schema v3 migration)
- **Implementation Difficulty**: High (5–6 hours)

### 4.3 Habit Archiving
- **Why Needed**: Users often want to pause a habit without deleting its complete historical log data from their consistency heatmaps.
- **Affected Files**:
  - `lib/features/habits/models/habit.dart` (Add `isArchived` flag)
  - `lib/core/database/db_helper.dart`
  - `lib/features/habits/controllers/habit_controller.dart`
- **Implementation Difficulty**: Medium (2 hours)

### 4.4 Completion Audio Effects & Milestone Celebrations
- **Why Needed**: Completing a Pomodoro session or hitting a 7-day / 30-day streak milestone deserves celebratory auditory feedback and confetti animations (`confetti` package).
- **Affected Files**:
  - `pubspec.yaml` (Add `audioplayers` or `soundpool`)
  - `lib/features/focus/screen/focus_screen.dart`
  - `lib/features/habits/screen/widgets/habit_tile.dart`
- **Implementation Difficulty**: Low to Medium (2 hours)

---

## Priority 5: Performance, Security, and Automated CI/CD

### 5.1 Repository & Database Automated Test Suite
- **Why Needed**: Currently, zero unit tests exist for `SqliteHabitRepository`, `DBHelper`, or SQLite migrations.
- **Affected Files**:
  - `test/sqlite_habit_repository_test.dart` (New, using `sqflite_common_ffi`)
  - `test/db_helper_test.dart` (New)
- **Implementation Difficulty**: Medium (3 hours)

### 5.2 GitHub Actions CI/CD Pipeline
- **Why Needed**: Guarantees that every pull request or commit automatically passes `flutter analyze` and `flutter test` across macOS, Linux, and Windows runners.
- **Affected Files**:
  - `.github/workflows/ci.yml` (New)
- **Implementation Difficulty**: Low (1 hour)

### 5.3 At-Rest Database Encryption (Optional Enterprise Upgrade)
- **Why Needed**: Encrypts `daily_flow.db` using 256-bit AES SQLCipher for users storing sensitive habits.
- **Affected Files**:
  - `pubspec.yaml` (Replace `sqflite` with `sqflite_sqlcipher`)
  - `lib/core/database/db_helper.dart`
- **Implementation Difficulty**: Medium to High (3–4 hours)
