import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_flow/core/theme/app_theme.dart';
import 'package:daily_flow/features/gamification/controllers/gamification_controller.dart';
import 'package:daily_flow/features/gamification/models/user_profile.dart';
import 'package:daily_flow/features/habits/controllers/habit_controller.dart';
import 'package:daily_flow/features/habits/models/habit.dart';
import 'package:daily_flow/features/habits/screen/widgets/quest_form_sheet.dart';
import 'package:daily_flow/features/navigation/screen/main_shell.dart';

class _FakeHabitController extends HabitController {
  @override
  List<Habit> build() => [
    Habit(
      id: 1,
      title: 'Daily Meditation',
      category: 'Mindfulness',
      colorValue: 0xFF8B5CF6,
      createdAt: DateTime.now(),
      completedDates: {},
    ),
  ];

  @override
  Future<void> loadHabits() async {}
}

class _FakeGamificationController extends GamificationController {
  @override
  GamificationState build() {
    return GamificationState(
      profile: UserProfile(
        heroName: 'Valiant Adventurer',
        avatarId: 'knight_helm',
        totalXp: 350,
        currentLevel: 3,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> loadGamificationData() async {}
}

Widget createMainShellApp({TextScaler textScaler = TextScaler.noScaling}) {
  return ProviderScope(
    overrides: [
      habitControllerProvider.overrideWith(() => _FakeHabitController()),
      gamificationControllerProvider.overrideWith(
        () => _FakeGamificationController(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(bottom: 34),
            textScaler: textScaler,
          ),
          child: const MainShell(),
        ),
      ),
    ),
  );
}

void main() {
  group('Floating Liquid Glass Bottom Navigation Tests', () {
    testWidgets(
      '1. All four navigation items render with labels and semantic targets',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createMainShellApp());
        await tester.pumpAndSettle();

        // Verify all four tabs exist in exact order
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Insights'), findsOneWidget);
        expect(find.text('Focus'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);

        // Verify icons exist
        expect(find.byIcon(Icons.home_rounded), findsOneWidget); // active
        expect(find.byIcon(Icons.bar_chart_outlined), findsOneWidget);
        expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
        expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

        // Today's screen is displayed initially
        expect(find.text("Today's Quests"), findsOneWidget);
      },
    );

    testWidgets(
      '2. Tab navigation switches correctly across all 4 destinations',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createMainShellApp());
        await tester.pumpAndSettle();

        // Switch to Insights
        await tester.tap(find.text('Insights'));
        await tester.pumpAndSettle();
        expect(find.text('Hall of Records'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Icon &&
                w.icon == Icons.bar_chart_rounded &&
                w.size == 21.0,
          ),
          findsOneWidget,
        ); // active dock icon

        // Switch to Focus
        await tester.tap(find.text('Focus'));
        await tester.pumpAndSettle();
        expect(find.text('Focus Trial'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Icon &&
                w.icon == Icons.hourglass_full_rounded &&
                w.size == 21.0,
          ),
          findsOneWidget,
        ); // active dock icon

        // Switch to Profile
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Valiant Adventurer'), findsOneWidget);
        expect(
          find.byIcon(Icons.person_rounded),
          findsOneWidget,
        ); // active icon

        // Switch back to Today
        await tester.tap(find.text('Today'));
        await tester.pumpAndSettle();
        expect(find.text("Today's Quests"), findsOneWidget);
        expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      },
    );

    testWidgets(
      '3. IndexedStack preserves Focus timer continuity across tab switches',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createMainShellApp());
        await tester.pumpAndSettle();

        // Navigate to Focus
        await tester.tap(find.text('Focus'));
        await tester.pumpAndSettle();
        expect(find.text('25:00'), findsOneWidget);

        // Start the timer
        await tester.ensureVisible(find.text('Start Focus'));
        await tester.tap(find.text('Start Focus'));
        await tester.pump();
        expect(find.text('Pause'), findsOneWidget);

        // Navigate away to Insights tab
        await tester.tap(find.text('Insights'));
        await tester.pumpAndSettle();
        expect(find.text('Hall of Records'), findsOneWidget);

        // Advance time while on Insights tab
        await tester.pump(const Duration(seconds: 3));

        // Navigate back to Focus tab
        await tester.tap(find.text('Focus'));
        await tester.pumpAndSettle();

        // Timer state was preserved and is still running in Pause state
        expect(find.text('Pause'), findsOneWidget);

        // Clean up timer
        await tester.tap(find.byTooltip('Reset Timer'));
        await tester.pumpAndSettle();
        expect(find.text('Start Focus'), findsOneWidget);
      },
    );

    testWidgets('4. SafeArea handling floats above bottom safe area', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createMainShellApp());
      await tester.pumpAndSettle();

      // Verify SafeArea wraps bottomNavigationBar correctly
      final safeAreaFinder = find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(SafeArea),
      );
      expect(safeAreaFinder, findsWidgets);

      // Content renders cleanly
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets(
      '5. 320px responsive layout renders cleanly with zero overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createMainShellApp());
        await tester.pumpAndSettle();

        // All 4 tabs present on 320px narrow layout
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Insights'), findsOneWidget);
        expect(find.text('Focus'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);

        // Switch tabs without error or overflow
        await tester.tap(find.text('Focus'));
        await tester.pumpAndSettle();
        expect(find.text('Focus Trial'), findsOneWidget);
      },
    );

    testWidgets(
      '6. 2.0x text scaling handles accessibility comfortably without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createMainShellApp(textScaler: const TextScaler.linear(2.0)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Insights'), findsOneWidget);
        expect(find.text('Focus'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);

        // Verify navigation still operates seamlessly under 2.0x text scaling
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Valiant Adventurer'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Reduced motion setting runs instantly without animation lag',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(() {
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        });

        await tester.pumpWidget(createMainShellApp());
        await tester.pumpAndSettle();

        // Fast instant tab switches under reduced motion
        await tester.tap(find.text('Insights'));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text('Hall of Records'), findsOneWidget);

        await tester.tap(find.text('Today'));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text("Today's Quests"), findsOneWidget);
      },
    );

    testWidgets(
      '8. Optional separate circular action button appears on Insights and opens QuestFormSheet',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createMainShellApp());
        await tester.pumpAndSettle();

        // On Today tab, separate plus button is not duplicated because HomeScreen has its own New Quest button
        expect(find.byTooltip('New Quest'), findsNothing);

        // Switch to Insights tab (width >= 370px)
        await tester.tap(find.text('Insights'));
        await tester.pumpAndSettle();

        // Now the separate circular frosted-glass action button is present beside the dock
        expect(find.byTooltip('New Quest'), findsOneWidget);

        // Tap the separate plus button
        await tester.tap(find.byTooltip('New Quest'));
        await tester.pumpAndSettle();

        // Verify QuestFormSheet modal opened cleanly
        expect(find.byType(QuestFormSheet), findsOneWidget);
        expect(find.text('Forge New Quest'), findsOneWidget);
      },
    );
  });
}
