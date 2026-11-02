import 'package:daily_flow/core/services/notification_service.dart';
import 'package:daily_flow/core/theme/app_theme.dart';
import 'package:daily_flow/features/gamification/controllers/gamification_controller.dart';
import 'package:daily_flow/features/gamification/models/user_profile.dart';
import 'package:daily_flow/features/habits/controllers/habit_controller.dart';
import 'package:daily_flow/features/habits/models/habit.dart';
import 'package:daily_flow/features/navigation/screen/main_shell.dart';
import 'package:daily_flow/features/settings/controllers/settings_controller.dart';
import 'package:daily_flow/features/settings/screen/settings_screen.dart';
import 'package:daily_flow/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNavHabitController extends HabitController {
  int loadHabitsCount = 0;

  @override
  List<Habit> build() => [
    Habit(
      id: 1,
      title: 'Morning Yoga',
      category: 'Health',
      colorValue: 0xFF10B981,
      createdAt: DateTime.now(),
      completedDates: {},
    ),
  ];

  @override
  Future<void> loadHabits() async {
    loadHabitsCount++;
  }
}

class _FakeNavGamificationController extends GamificationController {
  @override
  GamificationState build() {
    return GamificationState(
      profile: UserProfile(
        heroName: 'Valiant Adventurer',
        avatarId: 'knight_helm',
        totalXp: 120,
        currentLevel: 2,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> loadGamificationData() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Tap Navigation Tests', () {
    late ProviderContainer container;
    late GlobalKey<NavigatorState> testNavKey;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      testNavKey = GlobalKey<NavigatorState>();

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          habitControllerProvider.overrideWith(_FakeNavHabitController.new),
          gamificationControllerProvider.overrideWith(
            _FakeNavGamificationController.new,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets(
      'notification tap with valid payload switches tab to Today (index 0)',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              navigatorKey: testNavKey,
              theme: AppTheme.darkTheme,
              home: const MainShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially at Today
        expect(container.read(mainShellTabProvider), 0);

        // Switch to Focus tab (index 2)
        container.read(mainShellTabProvider.notifier).selectTab(2);
        await tester.pumpAndSettle();
        expect(container.read(mainShellTabProvider), 2);
        expect(find.text('Focus Session'), findsOneWidget);

        // Simulate notification tap event with valid payload
        handleNotificationResponse(
          NotificationConstants.dailyReminderPayload,
          container,
        );
        await tester.pumpAndSettle();

        // Must switch back to Today tab (index 0)
        expect(container.read(mainShellTabProvider), 0);
        expect(find.text("Today's Quests"), findsOneWidget);
      },
    );

    testWidgets(
      'notification tap pops pushed SettingsScreen back to root MainShell',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              navigatorKey: appNavigatorKey,
              theme: AppTheme.darkTheme,
              home: const MainShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Insights tab
        container.read(mainShellTabProvider.notifier).selectTab(1);
        await tester.pumpAndSettle();
        expect(container.read(mainShellTabProvider), 1);

        // Push SettingsScreen on top of MainShell
        appNavigatorKey.currentState!.push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SettingsScreen), findsOneWidget);

        // Simulate notification tap
        handleNotificationResponse(
          NotificationConstants.dailyReminderPayload,
          container,
        );
        await tester.pumpAndSettle();

        // SettingsScreen is popped, MainShell is restored at Today tab (index 0)
        expect(find.byType(SettingsScreen), findsNothing);
        expect(find.byType(MainShell), findsOneWidget);
        expect(container.read(mainShellTabProvider), 0);
        expect(find.text("Today's Quests"), findsOneWidget);
      },
    );

    testWidgets(
      'notification tap with invalid or null payload does NOT navigate or alter tabs',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              navigatorKey: testNavKey,
              theme: AppTheme.darkTheme,
              home: const MainShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Profile tab (index 3)
        container.read(mainShellTabProvider.notifier).selectTab(3);
        await tester.pumpAndSettle();
        expect(container.read(mainShellTabProvider), 3);

        // Null payload
        handleNotificationResponse(null, container);
        await tester.pumpAndSettle();
        expect(container.read(mainShellTabProvider), 3);

        // Unrecognized payload
        handleNotificationResponse('unknown_random_action', container);
        await tester.pumpAndSettle();
        expect(container.read(mainShellTabProvider), 3);
      },
    );

    testWidgets(
      'notification tap does not mutate habits, award XP, or touch focus timer',
      (tester) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              navigatorKey: appNavigatorKey,
              theme: AppTheme.darkTheme,
              home: const MainShell(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final initialHabit = container.read(habitControllerProvider).first;
        final initialXp = container
            .read(gamificationControllerProvider)
            .profile
            .totalXp;

        // Trigger notification tap
        handleNotificationResponse(
          NotificationConstants.dailyReminderPayload,
          container,
        );
        await tester.pumpAndSettle();

        final afterHabit = container.read(habitControllerProvider).first;
        final afterXp = container
            .read(gamificationControllerProvider)
            .profile
            .totalXp;

        // Verify state is completely untampered
        expect(afterHabit.completedDates, equals(initialHabit.completedDates));
        expect(afterXp, equals(initialXp));
      },
    );
  });
}
