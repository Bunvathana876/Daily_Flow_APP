import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_flow/features/habits/controllers/habit_controller.dart';
import 'package:daily_flow/features/habits/models/habit.dart';
import 'package:daily_flow/features/habits/screen/habit_detail_screen.dart';
import 'package:daily_flow/features/navigation/screen/main_shell.dart';
import 'package:daily_flow/features/profile/screen/profile_screen.dart';
import 'package:daily_flow/features/settings/screen/settings_screen.dart';
import 'package:daily_flow/features/splash/screen/splash_screen.dart';
import 'package:daily_flow/main.dart';

class FakeHabitController extends HabitController {
  final List<Habit> initialHabits;
  FakeHabitController([this.initialHabits = const []]);

  @override
  List<Habit> build() => initialHabits;

  @override
  Future<void> loadHabits() async {}

  @override
  Future<void> addHabit(
    String title, {
    String category = 'General',
    int colorValue = 0xFF4F46E5,
  }) async {
    final habit = Habit(
      id: state.length + 1,
      title: title,
      createdAt: DateTime.now(),
      completedDates: {},
      category: category,
      colorValue: colorValue,
    );
    state = [habit, ...state];
  }

  @override
  Future<void> toggleHabitOnDate(Habit habit, String dateStr) async {
    final updatedDates = Set<String>.from(habit.completedDates);
    if (updatedDates.contains(dateStr)) {
      updatedDates.remove(dateStr);
    } else {
      updatedDates.add(dateStr);
    }
    state = [
      for (final h in state)
        if (h.id == habit.id) h.copyWith(completedDates: updatedDates) else h,
    ];
  }

  @override
  Future<void> deleteHabit(int id) async {
    state = state.where((h) => h.id != id).toList();
  }

  @override
  Future<void> restoreHabit(Habit habit) async {
    state = [habit, ...state];
  }
}

void main() {
  testWidgets('DailyFlowApp renders headers and category filter chips in Today tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitControllerProvider.overrideWith(FakeHabitController.new),
        ],
        child: const DailyFlowApp(home: MainShell()),
      ),
    );

    expect(find.text('DailyFlow'), findsOneWidget);
    expect(find.text("Today's Habits"), findsOneWidget);
    expect(find.text('7-Day Completion Rate'), findsOneWidget);

    // 4 NavigationBar destinations
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // FilterChips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Study'), findsOneWidget);
    expect(find.text('Coding'), findsOneWidget);
    expect(find.text('Fitness'), findsOneWidget);
  });

  testWidgets('Theme toggle toggles dark and light mode',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitControllerProvider.overrideWith(FakeHabitController.new),
        ],
        child: const DailyFlowApp(home: MainShell()),
      ),
    );

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.light);

    await tester.tap(find.byTooltip('Toggle Theme'));
    await tester.pumpAndSettle();

    final updatedApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(updatedApp.themeMode, ThemeMode.dark);
  });

  testWidgets('MainShell navigates to Insights tab and renders analytics',
      (WidgetTester tester) async {
    final sampleHabit = Habit(
      id: 1,
      title: 'Morning Run',
      createdAt: DateTime.now(),
      completedDates: {'2026-10-18'},
      category: 'Fitness',
      colorValue: 0xFF059669,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitControllerProvider.overrideWith(
            () => FakeHabitController([sampleHabit]),
          ),
        ],
        child: const DailyFlowApp(home: MainShell()),
      ),
    );

    // Tap the 'Insights' tab in the bottom NavigationBar
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    expect(find.text('Insights & Analytics'), findsOneWidget);
    expect(find.text('Total Check-ins'), findsOneWidget);
    expect(find.text('Best Streak'), findsOneWidget);
    expect(find.text('Active Habits'), findsOneWidget);
    expect(find.text('12-Week Consistency'), findsOneWidget);
    expect(find.text('Weekday Performance'), findsOneWidget);
  });

  testWidgets('MainShell navigates to Focus tab and controls Pomodoro timer',
      (WidgetTester tester) async {
    final sampleHabit = Habit(
      id: 1,
      title: 'Meditation',
      createdAt: DateTime.now(),
      completedDates: {},
      category: 'Health',
      colorValue: 0xFF10B981,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitControllerProvider.overrideWith(
            () => FakeHabitController([sampleHabit]),
          ),
        ],
        child: const DailyFlowApp(home: MainShell()),
      ),
    );

    // Tap the 'Focus' tab in the bottom NavigationBar
    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();

    expect(find.text('Focus Session'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('25 min'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);
    expect(find.text('60 min'), findsOneWidget);
    expect(find.text('Start Focus'), findsOneWidget);

    // Switch to 15 min preset
    await tester.tap(find.text('15 min'));
    await tester.pumpAndSettle();
    expect(find.text('15:00'), findsOneWidget);

    // Start timer
    await tester.ensureVisible(find.text('Start Focus'));
    await tester.tap(find.text('Start Focus'));
    await tester.pump();
    expect(find.text('Pause'), findsOneWidget);

    // Pause timer
    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Start Focus'), findsOneWidget);

    // Reset timer
    await tester.tap(find.byTooltip('Reset Timer'));
    await tester.pumpAndSettle();
    expect(find.text('15:00'), findsOneWidget);
  });

  testWidgets('Tapping habit tile navigates to HabitDetailScreen',
      (WidgetTester tester) async {
    final sampleHabit = Habit(
      id: 1,
      title: 'Study Flutter',
      createdAt: DateTime.now(),
      completedDates: {'2026-10-18'},
      category: 'Study',
      colorValue: 0xFF4F46E5,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitControllerProvider.overrideWith(
            () => FakeHabitController([sampleHabit]),
          ),
        ],
        child: const DailyFlowApp(home: MainShell()),
      ),
    );

    expect(find.text('Study Flutter'), findsOneWidget);

    // Tap on the tile title
    await tester.tap(find.text('Study Flutter'));
    await tester.pumpAndSettle();

    // Verify HabitDetailScreen is pushed
    expect(find.byType(HabitDetailScreen), findsOneWidget);
    expect(find.text('Current Streak'), findsOneWidget);
    expect(find.text('Best Streak'), findsOneWidget);
    expect(find.text('Total Days'), findsOneWidget);
    expect(find.byTooltip('Edit Habit'), findsOneWidget);
    expect(find.byTooltip('Delete Habit'), findsOneWidget);
  });

  testWidgets('MainShell navigates to Profile tab, displays profile stats and sets dark mode',
      (WidgetTester tester) async {
    final sampleHabit = Habit(
      id: 1,
      title: 'Read Book',
      createdAt: DateTime.now(),
      completedDates: {'2026-10-18', '2026-10-17'},
      category: 'Study',
      colorValue: 0xFF4F46E5,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitControllerProvider.overrideWith(
            () => FakeHabitController([sampleHabit]),
          ),
        ],
        child: const DailyFlowApp(home: MainShell()),
      ),
    );

    // Initial theme is light
    final initialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(initialApp.themeMode, ThemeMode.light);

    // Tap Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Verify ProfileScreen components
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('DailyFlow Champion'), findsOneWidget);
    expect(find.text('Active Habits'), findsOneWidget);
    expect(find.text('Total Check-ins'), findsOneWidget);
    expect(find.text('Best Streak'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);

    // Scroll to check Category Breakdown
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('Category Breakdown'), findsOneWidget);

    // Scroll back up
    await tester.drag(find.byType(ListView), const Offset(0, 200));
    await tester.pumpAndSettle();

    // Verify Data & Storage and About are removed from Profile
    expect(find.text('Data & Storage'), findsNothing);
    expect(find.text('About'), findsNothing);

    // Navigate to SettingsScreen by tapping the Settings card
    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();

    // Verify SettingsScreen is pushed
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Theme Mode'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Dark Mode Quick Toggle'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Haptic Feedback'), findsOneWidget);

    // Verify Data & Storage and About are NOT in Settings either
    expect(find.text('Data & Storage'), findsNothing);
    expect(find.text('About'), findsNothing);

    // Tap 'Dark' button in the SegmentedButton
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    // Verify MaterialApp switched to dark mode
    final darkApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(darkApp.themeMode, ThemeMode.dark);

    // Tap 'Light' button in the SegmentedButton
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    final lightApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(lightApp.themeMode, ThemeMode.light);
  });

  testWidgets('DailyFlowApp launches SplashScreen and transitions to MainShell',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitControllerProvider.overrideWith(FakeHabitController.new),
        ],
        child: const DailyFlowApp(),
      ),
    );

    // Verify SplashScreen is rendered on app launch
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('DailyFlow'), findsOneWidget);
    expect(find.text('Build consistency, one day at a time'), findsOneWidget);
    expect(find.text('Preparing your daily flow...'), findsOneWidget);

    // Fast forward animation and duration
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    // Verify it transitioned to MainShell
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text("Today's Habits"), findsOneWidget);
  });
}
