# 🌊 DailyFlow v2.0

A clean, modern, and production-ready habit-tracking mobile application built with **Flutter 3**, **Riverpod 3**, and **SQLite v2**. DailyFlow helps users build sustainable daily routines, visualize long-term consistency, boost focus through Pomodoro sessions, and celebrate streak milestones.

---

## ✨ Features & Navigation

DailyFlow is structured around an animated loading splash screen, a 4-tab bottom navigation shell, drill-down detail views, and dedicated settings:

### 1. 🚀 App Loading & Splash Screen (`SplashScreen`)
- **Branded Launch Experience**: Displays the animated app logo (`assets/icons/app_icon.png`), smooth scale & fade-in transitions, and encouragement tagline.
- **Asynchronous Initialization**: Preloads local SQLite habits data in the background during launch.
- **Seamless Page Transition**: Smooth fade transition directly into `MainShell`.

### 2. 📅 Today (`HomeScreen`)
- **Interactive Habit Check-ins**: Check off daily goals with smooth animations and tactile feedback (`HapticFeedback.lightImpact()`).
- **Interactive 7-Day Strip**: Compact weekly timeline on each habit tile allowing immediate backfilling or editing for any of the past 7 days.
- **Category Filter Chips**: Filter habits instantly by category (`All`, `General`, `Health`, `Study`, `Coding`, `Fitness`).
- **Weekly Overview Card**: Animated summary displaying the current 7-day completion rate.
- **Habit CRUD & Undo**:
  - Create and edit habits with title, category, and accent color pickers.
  - Swipe-to-delete with animated confirmation and one-tap **Undo** `SnackBarAction`.
- **Quick Theme Toggle**: One-tap dark/light mode toggle in the AppBar.

### 3. 📊 Insights & Analytics (`StatsScreen`)
- **Key Metric KPI Cards**: Quick overview of Total Check-ins, All-Time Longest Streak, and Active Habits.
- **12-Week Consistency Heatmap**: GitHub-style 84-day contribution grid with dynamic opacity scaling to highlight daily commitment.
- **Weekday Performance Bar Chart**: Custom animated vertical bar chart displaying completion rates across Monday through Sunday.

### 4. ⏱️ Focus / Pomodoro (`FocusScreen`)
- **Linked Habit Selection**: Select which habit you are dedicating time to.
- **Duration Presets**: Instant selection chips for `15 min`, `25 min`, `45 min`, and `60 min` sessions.
- **Animated Circular Countdown**: Large countdown timer with smooth visual feedback and pause/resume/reset controls.
- **Auto-Completion**: Reaching `00:00` triggers completion haptics and automatically logs the habit as completed for today.

### 5. 👤 Profile (`ProfileScreen`)
- **User Dashboard**: Displays user avatar, rank badge ("DailyFlow Champion"), consistency level, and key stats.
- **Achievement Badges**: Visual milestones for streaks and check-ins (*7-Day Club*, *Habit Hero*, *Focused Mind*, *Century Flow*).
- **Category Breakdown**: Dynamic badge overview showing habit counts across all categories.
- **Settings Link**: Direct access to application preferences.

### 6. ⚙️ Settings (`SettingsScreen`)
- **Theme Mode Selector**: Three-way `SegmentedButton` to select between **Light**, **Dark**, and **System Default** themes.
- **Dark Mode Quick Toggle**: Instant switch between light and dark palettes.
- **Preferences**:
  - Haptic feedback toggle.
  - Interactive Daily Reminder `TimePicker`.

### 7. 🔍 Habit Details (`HabitDetailScreen`)
- **Detailed Streak Metrics**: Current streak, all-time best streak, and total completed days.
- **Interactive Monthly Calendar**: Full calendar grid with previous/next month navigation for auditing or backfilling completions.
- **Edit & Delete Actions**: Quick access from the detail screen's AppBar.

---

## 🏗️ Clean Project Architecture

The application follows a modular, feature-first domain architecture using the **Repository Pattern**:

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart        # Centralized categories, presets, and color palettes
│   ├── database/
│   │   └── db_helper.dart            # SQLite v2 setup, migration & cascading foreign keys
│   ├── theme/
│   │   ├── app_theme.dart            # Material 3 Light & Dark themes with custom styling
│   │   └── theme_provider.dart       # Riverpod 3 ThemeModeNotifier (Light/Dark/System)
│   └── utils/
│       └── date_utils.dart           # Streak algorithms, heatmap data & 7-day strip math
├── features/
│   ├── analytics/
│   │   └── screen/
│   │       └── stats_screen.dart     # Insights screen with KPI cards, heatmap & weekday chart
│   ├── focus/
│   │   └── screen/
│   │       └── focus_screen.dart     # Pomodoro focus timer linked to habits
│   ├── habits/
│   │   ├── controllers/
│   │   │   └── habit_controller.dart # Riverpod 3 Notifier with Repository dependency injection
│   │   ├── data/
│   │   │   └── habit_repository.dart # Abstract HabitRepository & SqliteHabitRepository
│   │   ├── models/
│   │   │   └── habit.dart            # Habit model with category, colorValue & copyWith
│   │   └── screen/
│   │       ├── habit_detail_screen.dart # Habit detail with interactive monthly calendar grid
│   │       ├── home_screen.dart      # Main screen layout, filter chips, theme toggle
│   │       └── widgets/
│   │           ├── habit_form_dialog.dart # Reusable add/edit habit dialog
│   │           ├── habit_tile.dart   # Interactive tile with 7-day strip, category badge & haptics
│   │           └── weekly_overview_card.dart # 7-day progress indicator card
│   ├── navigation/
│   │   └── screen/
│   │       └── main_shell.dart       # App shell with 4 tabs (Today, Insights, Focus, Profile)
│   ├── profile/
│   │   └── screen/
│   │       └── profile_screen.dart   # User profile, achievements, category breakdown & settings link
│   ├── settings/
│   │   └── screen/
│   │       └── settings_screen.dart  # Dedicated settings: dark mode, theme selector & preferences
│   └── splash/
│       └── screen/
│           └── splash_screen.dart    # Animated loading splash screen with logo & preload
└── main.dart                         # Entrypoint, ProviderScope, centralized AppTheme binding
```

---

## 💾 Database Schema & Migrations

DailyFlow uses [`sqflite`](https://pub.dev/packages/sqflite) with non-destructive migrations:

- **`habits` table**:
  - `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
  - `title`: `TEXT NOT NULL`
  - `created_at`: `TEXT NOT NULL`
  - `category`: `TEXT NOT NULL DEFAULT 'General'` *(Added in v2)*
  - `color_value`: `INTEGER NOT NULL DEFAULT 4283385573` *(0xFF4F46E5, Added in v2)*
- **`habit_logs` table**:
  - `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
  - `habit_id`: `INTEGER NOT NULL`
  - `completed_date`: `TEXT NOT NULL` (`yyyy-MM-dd`)
  - `FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE`
- **Migration Strategy**:
  - The `onUpgrade` hook automatically alters existing v1 databases to add `category` and `color_value` columns without wiping user data.
  - Transactions ensure atomic updates when restoring deleted habits and cascading deletions.

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: [Flutter](https://flutter.dev) (Dart `^3.11.1`)
- **State Management**: [`flutter_riverpod: ^3.3.2`](https://pub.dev/packages/flutter_riverpod) (`Notifier` & `NotifierProvider`)
- **Local Database**: [`sqflite: ^2.4.2+1`](https://pub.dev/packages/sqflite) & [`path: ^1.9.1`](https://pub.dev/packages/path)
- **Date & Time Utilities**: [`intl: ^0.20.3`](https://pub.dev/packages/intl)
- **Haptics**: `package:flutter/services.dart`
- **Testing**: `flutter_test` (22 automated unit and widget tests)

---

## 🚀 Getting Started

### Prerequisites

Ensure you have Flutter installed:

```bash
flutter --version
```

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/daily_flow.git
   cd daily_flow
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing & Analysis

- **Run Static Analysis** (0 errors, 0 warnings):
  ```bash
  flutter analyze
  ```

- **Run Automated Tests** (23 passing unit & widget tests):
  ```bash
  flutter test
  ```

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
