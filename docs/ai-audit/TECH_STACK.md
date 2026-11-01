# Technology Stack: DailyFlow

This document provides a verified, file-by-file audit of the technology stack utilized in the **DailyFlow** codebase.

---

## 1. Stack Summary Table

| Category | Technology / Library | Version | Verification Source | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Language** | Dart | `^3.11.1` | `pubspec.yaml` (line 22) | Confirmed |
| **UI Framework** | Flutter SDK | Channel stable / `sdk: flutter` | `pubspec.yaml` (lines 31–32) | Confirmed |
| **Design System** | Material 3 (`useMaterial3: true`) | Default Flutter M3 | `lib/core/theme/app_theme.dart` | Confirmed |
| **State Management** | `flutter_riverpod` | `^3.3.2` | `pubspec.yaml` (line 40) | Confirmed |
| **Local Database** | `sqflite` | `^2.4.2+1` | `pubspec.yaml` (line 37) | Confirmed |
| **File Path Utility** | `path` | `^1.9.1` | `pubspec.yaml` (line 38) | Confirmed |
| **Date & Time Formatting**| `intl` | `^0.20.3` | `pubspec.yaml` (line 39) | Confirmed |
| **Icons** | `cupertino_icons` & Material Icons | `^1.0.8` | `pubspec.yaml` (lines 36, 75) | Confirmed |
| **Asset Tooling** | `flutter_launcher_icons` | `^0.14.4` | `pubspec.yaml` (line 52) | Confirmed |
| **Linter** | `flutter_lints` | `^6.0.0` | `pubspec.yaml` (line 51) | Confirmed |
| **Test Framework** | `flutter_test` | `sdk: flutter` | `pubspec.yaml` (line 43) | Confirmed |
| **Backend & Cloud APIs** | None (Client-side offline-first) | N/A | Entire codebase scan | Confirmed |
| **Auth & Authorization** | None (Local single-user) | N/A | Entire codebase scan | Confirmed |
| **Docker Configuration** | None | N/A | Root workspace scan | Confirmed |

---

## 2. Detailed Technology Breakdown

### 2.1 Frontend Framework & Libraries
- **Flutter & Dart**: The app is built targeting modern Flutter 3.x with Dart 3.11+. The code takes advantage of Dart 3 features like pattern matching, record types, and collection-if/for constructs.
- **Design System**: Material Design 3 is explicitly enabled (`ThemeData(useMaterial3: true)`).
  - Custom Color Schemes generated via `ColorScheme.fromSeed(seedColor: Color(0xFF4F46E5))` for both Light and Dark modes.
  - The styling is applied across components via custom `NavigationBarThemeData`, `CardThemeData`, and `AppBarTheme`.
- **Typography & Assets**:
  - Uses Flutter system typography. No custom TTF/OTF fonts are declared in `pubspec.yaml`.
  - Asset directories declared: `assets/icons/` and `assets/images/`.

### 2.2 Backend Framework & APIs
- **Finding (Confirmed)**: **There is no remote backend server or network API integration.**
  - There is no `http`, `dio`, `grpc`, or Firebase SDK included in `pubspec.yaml`.
  - The app communicates exclusively with the local on-device SQLite database.
  - No network permission is requested in `android/app/src/main/AndroidManifest.xml` (no `android.permission.INTERNET`).

### 2.3 Database & Data Models
- **Database Engine**: `sqflite: ^2.4.2+1` paired with `path: ^1.9.1`.
- **Database Helper (`DBHelper`)**: Located at `lib/core/database/db_helper.dart`. Singleton pattern (`DBHelper._init()`).
- **Database File**: `daily_flow.db` stored in the OS default database directory (`getDatabasesPath()`).
- **Schema Version**: `version: 2`.
- **Tables**:
  1. `habits`:
     - `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
     - `title`: `TEXT NOT NULL`
     - `created_at`: `TEXT NOT NULL` (ISO-8601 string)
     - `category`: `TEXT NOT NULL DEFAULT 'General'`
     - `color_value`: `INTEGER NOT NULL DEFAULT 4283385573` (`0xFF4F46E5`)
  2. `habit_logs`:
     - `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
     - `habit_id`: `INTEGER NOT NULL`
     - `completed_date`: `TEXT NOT NULL` (`yyyy-MM-dd`)
     - `FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE`
     - `UNIQUE(habit_id, completed_date)`
- **Data Models**:
  - `Habit` (`lib/features/habits/models/habit.dart`): Immutable Dart model with `copyWith` method and computed getters (`isCompletedToday`, `currentStreak`, `bestStreak`, `totalCompletions`).
  - `DayInfo` (`lib/core/utils/date_utils.dart`): Value object encapsulating `DateTime date`, `String label`, and `String dateStr`.

### 2.4 Authentication & Authorization
- **Finding (Confirmed)**: **No authentication or authorization system exists.**
  - The app is an offline, single-user mobile application.
  - The "Profile" tab (`lib/features/profile/screen/profile_screen.dart`) displays hardcoded profile data ("DailyFlow Champion", "Consistency Master • Level 3") and calculates achievements dynamically by querying local SQLite counts.

### 2.5 State Management
- **Library**: `flutter_riverpod: ^3.3.2`.
- **Patterns Used**:
  - `Notifier` and `NotifierProvider` (Riverpod 3 / 2.x modern notifier paradigm):
    - `HabitController` (`lib/features/habits/controllers/habit_controller.dart`): Manages `List<Habit>`. Interacts with `HabitRepository`.
    - `ThemeModeNotifier` (`lib/core/theme/theme_provider.dart`): Manages `ThemeMode` (`light`, `dark`, `system`).
    - `CategoryFilterNotifier` (`lib/features/habits/screen/home_screen.dart`): Manages active category filter string (`All`, `General`, etc.).
  - `Provider`:
    - `habitRepositoryProvider`: Supplies the singleton instance of `SqliteHabitRepository`.
- **State Persistence Observation**:
  - Riverpod state is strictly **in-memory**. When the app process is terminated, `ThemeMode` and active category filters reset to their initial defaults.

### 2.6 Navigation and Routing
- **Pattern**: Imperative Flutter Navigator 1.0 combined with `IndexedStack`.
- **Tab Navigation**: `lib/features/navigation/screen/main_shell.dart` uses `IndexedStack` to persist tab states across tab switching (`HomeScreen`, `StatsScreen`, `FocusScreen`, `ProfileScreen`).
- **Drill-Down Navigation**:
  - `Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habitId: habit.id!)))`
  - `Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))`
  - `SplashScreen` transitions to `MainShell` using `Navigator.of(context).pushReplacement` with a custom `PageRouteBuilder` fade animation.
- **Declarative Router**: Neither `go_router` nor `auto_route` is used. Deep linking and web URL synchronization are currently not supported.

### 2.7 Dependencies & Development Tools
- **Runtime Dependencies**:
  - `cupertino_icons: ^1.0.8` (iOS icon typography)
  - `sqflite: ^2.4.2+1` (SQLite mobile bindings)
  - `path: ^1.9.1` (Filesystem path string manipulation)
  - `intl: ^0.20.3` (Date formatting & internationalization utilities)
  - `flutter_riverpod: ^3.3.2` (Reactive state management)
- **Dev Dependencies**:
  - `flutter_test`: Unit & widget test harness.
  - `flutter_lints: ^6.0.0`: Recommended community linting rules activated via `analysis_options.yaml`.
  - `flutter_launcher_icons: ^0.14.4`: Generates platform-specific launcher icons from `assets/icons/app_icon.png` across Android, iOS, Web, and macOS.

### 2.8 Docker Configuration
- **Finding (Confirmed)**: **No Dockerfile, `docker-compose.yml`, or container configuration exists.**
- **Reasoning**: DailyFlow is a client-side Flutter mobile and desktop application with no backend services, server daemons, or microservices requiring containerized orchestration. Standard Flutter CLI workflows (`flutter build apk`, `flutter build ios`, etc.) apply.

---

## 3. Assumptions vs Confirmed Findings

| Aspect | Status | Notes |
| :--- | :--- | :--- |
| Client-side offline-first architecture | **Confirmed** | Verified via source inspection and `pubspec.yaml`. |
| Zero network calls | **Confirmed** | Verified absence of HTTP/network dependencies. |
| Riverpod 3 Notifiers | **Confirmed** | Verified in `habit_controller.dart` and `theme_provider.dart`. |
| sqflite database migrations | **Confirmed** | Verified `onUpgrade` logic in `db_helper.dart`. |
| Settings persistence via SharedPreferences | **DISPROVEN** | Assumed by many UI flows, but `shared_preferences` is **not installed**; settings are purely ephemeral. |
| Background timer capabilities | **DISPROVEN** | Focus timer is a simple Dart `Timer` and ceases running when the app is suspended by the OS. |
| Scheduled push notifications | **DISPROVEN** | Notification settings in `SettingsScreen` are purely cosmetic UI controls without any background scheduler. |
