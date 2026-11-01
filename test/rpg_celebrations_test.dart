import 'package:daily_flow/core/widgets/rpg_celebration_banner.dart';
import 'package:daily_flow/features/gamification/models/achievement.dart';
import 'package:daily_flow/features/habits/screen/widgets/level_up_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RPG Celebrations & Feedback Tests', () {
    testWidgets('RpgCelebrationBanner displays achievement unlocked toast', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  RpgCelebrationBanner.showAchievementUnlocked(
                    context,
                    const Achievement(
                      badgeKey: 'flame_keeper',
                      currentProgress: 7,
                      isUnlocked: true,
                    ),
                  );
                },
                child: const Text('Trigger Achievement'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Achievement'));
      await tester.pumpAndSettle();

      expect(find.text('Achievement Unlocked!'), findsOneWidget);
      expect(find.text('Flame Keeper (+100 XP)'), findsOneWidget);
      expect(find.byIcon(Icons.military_tech_rounded), findsOneWidget);
    });

    testWidgets('RpgCelebrationBanner displays milestone toast', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  RpgCelebrationBanner.showMilestone(
                    context,
                    title: 'Flawless Victory!',
                    subtitle: 'All daily quests completed for today!',
                  );
                },
                child: const Text('Trigger Milestone'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Milestone'));
      await tester.pumpAndSettle();

      expect(find.text('Flawless Victory!'), findsOneWidget);
      expect(
        find.text('All daily quests completed for today!'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    });

    testWidgets(
      'LevelUpDialog renders celebration modal with new level and rank',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    LevelUpDialog.show(context, 5);
                  },
                  child: const Text('Level Up'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Level Up'));
        await tester.pumpAndSettle();

        expect(find.byType(LevelUpDialog), findsOneWidget);
        expect(find.text('LEVEL UP!'), findsOneWidget);
        expect(find.text('Rank Unlocked: Flow Adept'), findsOneWidget);
        expect(find.text('Continue Journey'), findsOneWidget);

        await tester.tap(find.text('Continue Journey'));
        await tester.pumpAndSettle();
        expect(find.byType(LevelUpDialog), findsNothing);
      },
    );

    testWidgets(
      'LevelUpDialog respects reduced motion and renders without scale error',
      (tester) async {
        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              home: Scaffold(body: LevelUpDialog(newLevel: 10)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('LEVEL UP!'), findsOneWidget);
        expect(find.text('Rank Unlocked: Consistency Knight'), findsOneWidget);
      },
    );
  });
}
