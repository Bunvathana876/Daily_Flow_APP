import 'package:daily_flow/core/theme/cozy_artwork.dart';
import 'package:daily_flow/core/theme/cozy_icons.dart';
import 'package:daily_flow/core/theme/rpg_colors.dart';
import 'package:daily_flow/core/theme/rpg_text_styles.dart';
import 'package:daily_flow/core/widgets/cozy_background.dart';
import 'package:daily_flow/core/widgets/cozy_button.dart';
import 'package:daily_flow/core/widgets/cozy_card.dart';
import 'package:daily_flow/core/widgets/compact_xp_indicator.dart';
import 'package:daily_flow/core/widgets/hero_avatar_frame.dart';
import 'package:daily_flow/core/widgets/kpi_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cozy Adventure RPG 3.0 Tokens & Styles', () {
    test('Cozy color tokens match design reference specification', () {
      expect(RpgColors.midnightNavy, const Color(0xFF0B1224));
      expect(RpgColors.softIndigo, const Color(0xFF1A2447));
      expect(RpgColors.mutedViolet, const Color(0xFF8B48A7));
      expect(RpgColors.warmGold, const Color(0xFFF3B74A));
      expect(RpgColors.cozyAmber, const Color(0xFFF99A5A));
      expect(RpgColors.emeraldComplete, const Color(0xFF2EBF7E));

      // Check scaffold and surface mapping
      expect(RpgColors.rpgAbyss, RpgColors.midnightNavy);
      expect(RpgColors.rpgSurfaceDark, RpgColors.softIndigo);
      expect(RpgColors.rpgGold, RpgColors.warmGold);
      expect(RpgColors.rpgEmerald, RpgColors.emeraldComplete);
    });

    test('Typography fallbacks include serif headings and sans body', () {
      expect(RpgTextStyles.fantasyHeadingFallbacks, contains('Cinzel'));
      expect(RpgTextStyles.fantasyHeadingFallbacks, contains('serif'));
      expect(RpgTextStyles.modernBodyFallbacks, contains('Inter'));
      expect(RpgTextStyles.modernBodyFallbacks, contains('sans-serif'));
    });
  });

  group('CozyButton Widget Tests', () {
    testWidgets('renders primary warm gold button and responds to tap', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CozyButton.primary(
              label: '+ New Quest',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('+ New Quest'), findsOneWidget);
      await tester.tap(find.text('+ New Quest'));
      expect(tapped, isTrue);
    });

    testWidgets('renders secondary and pill variants with correct states', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CozyButton.secondary(label: 'Cancel', onPressed: () {}),
                CozyButton.pill(
                  label: 'Focus Time',
                  isSelected: true,
                  onPressed: () {},
                ),
                CozyButton.pill(
                  label: 'Rest Time',
                  isSelected: false,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Focus Time'), findsOneWidget);
      expect(find.text('Rest Time'), findsOneWidget);
    });

    testWidgets('renders loading state when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CozyButton.primary(
              label: 'Starting',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Starting'), findsNothing);
    });

    testWidgets('CozyIconButton responds to tap callback', (tester) async {
      bool resetPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CozyIconButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Reset',
              onPressed: () => resetPressed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      expect(resetPressed, isTrue);
    });
  });

  group('HeroAvatarFrame Widget Tests', () {
    testWidgets('renders hero avatar frame with level and fallback icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeroAvatarFrame(
              size: 72,
              fallbackIcon: Icons.shield_rounded,
              level: 7,
              showFlourish: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
      expect(find.byType(HeroAvatarFrame), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeroAvatarFrame(size: 64, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(HeroAvatarFrame));
      expect(tapped, isTrue);
    });
  });

  group('CompactXpIndicator & XpRewardBadge Tests', () {
    testWidgets('renders CompactXpBar with correct label and ratio', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactXpBar(
              currentXp: 420,
              requiredXp: 700,
              progressRatio: 0.6,
            ),
          ),
        ),
      );

      expect(find.text('420 / 700 XP'), findsOneWidget);
    });

    testWidgets('renders XpRewardBadge with warm gold text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: XpRewardBadge(xp: 120))),
      );

      expect(find.text('+120 XP'), findsOneWidget);
    });
  });

  group('DailyFlowBrandLogo & CozyCard & CozyStatChip Tests', () {
    testWidgets('renders DailyFlowBrandLogo with title and subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DailyFlowBrandLogo(showText: true, showSubtitle: true),
          ),
        ),
      );

      expect(find.text('DailyFlow'), findsOneWidget);
      expect(find.text('Level Up Your Daily Life ✨'), findsOneWidget);
    });

    testWidgets('renders CozyCard with custom content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CozyCard.bounty(child: const Text('Daily Bounty Mission')),
          ),
        ),
      );

      expect(find.text('Daily Bounty Mission'), findsOneWidget);
    });

    testWidgets('renders CozyStatChip with value and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CozyStatChip(
              icon: CozyIcons.streak,
              iconColor: RpgColors.cozyAmber,
              value: '12',
              label: 'Day Streak',
            ),
          ),
        ),
      );

      expect(find.text('12'), findsOneWidget);
      expect(find.text('Day Streak'), findsOneWidget);
    });

    testWidgets('renders CozyBackgroundScaffold with child content', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CozyBackgroundScaffold(body: Text('Sanctuary Content')),
        ),
      );

      expect(find.text('Sanctuary Content'), findsOneWidget);
    });
  });

  group('Artwork Loading & Graceful Fallbacks Tests', () {
    testWidgets(
      'HeroAvatarFrame falls back gracefully when imageAsset is missing',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: HeroAvatarFrame(
                imageAsset: 'assets/images/missing_hero_avatar.png',
                fallbackIcon: Icons.shield_rounded,
              ),
            ),
          ),
        );
        await tester.pump();

        // Should render fallback icon without throwing an unhandled exception
        expect(find.byType(HeroAvatarFrame), findsOneWidget);
        expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'HeroAvatarFrame renders hero portrait image when asset is present',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: HeroAvatarFrame.heroDefault()),
          ),
        );
        await tester.pump();

        expect(find.byType(HeroAvatarFrame), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
      },
    );

    testWidgets(
      'CozyBackgroundScaffold handles missing background image safely',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: CozyBackgroundScaffold(
              backgroundImageAsset: 'assets/images/missing_bg_art.png',
              isFullScreenImage: true,
              body: Text('Village Realm'),
            ),
          ),
        );

        expect(find.byType(CozyBackgroundScaffold), findsOneWidget);
        expect(find.text('Village Realm'), findsOneWidget);
      },
    );

    testWidgets('CozyBackgroundScaffold renders fantasy village backdrop', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const CozyBackgroundScaffold.village(
            body: Text('Village Sanctuary'),
          ),
        ),
      );

      expect(find.byType(CozyBackgroundScaffold), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Village Sanctuary'), findsOneWidget);
    });

    testWidgets(
      'CozyArtwork helpers render safe vector fallbacks when missing or forced',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CozyArtwork.questJournal(size: 32, forceFallback: true),
                  CozyArtwork.adventureChest(size: 44, forceFallback: true),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
        expect(find.byIcon(Icons.inventory_2_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'CozyArtwork helpers and reusable widgets render image assets',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  QuestJournalIcon(size: 32),
                  AdventureChestIcon(size: 44),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(QuestJournalIcon), findsOneWidget);
        expect(find.byType(AdventureChestIcon), findsOneWidget);
        expect(find.byType(Image), findsNWidgets(2));
      },
    );
  });
}
