import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_flow/core/theme/rpg_colors.dart';
import 'package:daily_flow/features/gamification/controllers/gamification_controller.dart';
import 'package:daily_flow/features/gamification/models/user_profile.dart';
import 'package:daily_flow/features/habits/controllers/habit_controller.dart';
import 'package:daily_flow/features/habits/models/habit.dart';
import 'package:daily_flow/features/navigation/screen/main_shell.dart';
import 'package:daily_flow/features/splash/screen/splash_screen.dart';

class _FakeHabitController extends HabitController {
  final bool shouldThrow;
  _FakeHabitController({this.shouldThrow = false});

  @override
  List<Habit> build() => [];

  @override
  Future<void> loadHabits() async {
    if (shouldThrow) throw Exception('Simulated loadHabits error');
  }
}

class _FakeGamificationController extends GamificationController {
  final bool shouldThrow;
  _FakeGamificationController({this.shouldThrow = false});

  @override
  GamificationState build() {
    return GamificationState(
      profile: UserProfile(
        heroName: 'DailyFlow Champion',
        avatarId: 'knight_helm',
        totalXp: 100,
        currentLevel: 2,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> loadGamificationData() async {
    if (shouldThrow) throw Exception('Simulated loadGamification error');
  }
}

void main() {
  group('Cozy Adventure Splash Screen Tests', () {
    testWidgets(
      '1. Renders DailyFlow adventurer icon, title, tagline, and gold indicator',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              habitControllerProvider.overrideWith(
                () => _FakeHabitController(),
              ),
              gamificationControllerProvider.overrideWith(
                () => _FakeGamificationController(),
              ),
            ],
            child: const MaterialApp(
              home: SplashScreen(minDuration: Duration(milliseconds: 300)),
            ),
          ),
        );

        // Verify Midnight Navy background is applied
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, RpgColors.midnightNavy);

        // Verify Adventurer icon, title, tagline, and adventure progress message
        expect(find.text('DailyFlow'), findsOneWidget);
        expect(find.text('Level Up Your Daily Life ✨'), findsOneWidget);
        expect(find.text('Preparing your adventure...'), findsOneWidget);

        // Verify gold circular progress indicator
        final progressIndicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(
          progressIndicator.valueColor,
          const AlwaysStoppedAnimation<Color>(RpgColors.warmGold),
        );

        // Fast forward past duration
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Verify successful transition to MainShell
        expect(find.byType(MainShell), findsOneWidget);
      },
    );

    testWidgets('2. Reduced motion setting navigates without animation delay', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitControllerProvider.overrideWith(() => _FakeHabitController()),
            gamificationControllerProvider.overrideWith(
              () => _FakeGamificationController(),
            ),
          ],
          child: const MaterialApp(
            home: SplashScreen(minDuration: Duration.zero),
          ),
        ),
      );

      // Settle immediately
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify it transitions to MainShell smoothly without waiting
      expect(find.byType(MainShell), findsOneWidget);

      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    });

    testWidgets(
      '3. Handles database startup failure gracefully and continues to MainShell',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              habitControllerProvider.overrideWith(
                () => _FakeHabitController(shouldThrow: true),
              ),
              gamificationControllerProvider.overrideWith(
                () => _FakeGamificationController(shouldThrow: true),
              ),
            ],
            child: const MaterialApp(
              home: SplashScreen(minDuration: Duration(milliseconds: 100)),
            ),
          ),
        );

        // Initial frame renders cleanly
        expect(find.byType(SplashScreen), findsOneWidget);

        // Fast forward through duration
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        // Verify app does not crash or stall on splash screen
        expect(find.byType(MainShell), findsOneWidget);
      },
    );
  });
}
