import 'package:daily_flow/core/theme/rpg_colors.dart';
import 'package:daily_flow/core/widgets/kpi_stat_card.dart';
import 'package:daily_flow/core/widgets/level_badge.dart';
import 'package:daily_flow/core/widgets/quest_progress_indicator.dart';
import 'package:daily_flow/core/widgets/rpg_card.dart';
import 'package:daily_flow/core/widgets/rpg_crest.dart';
import 'package:daily_flow/core/widgets/rpg_crest_checkbox.dart';
import 'package:daily_flow/core/widgets/rpg_decorative_frame.dart';
import 'package:daily_flow/core/widgets/rpg_filled_button.dart';
import 'package:daily_flow/core/widgets/rpg_gemstone_badge.dart';
import 'package:daily_flow/core/widgets/rpg_runic_divider.dart';
import 'package:daily_flow/core/widgets/xp_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RpgCard Widget Tests', () {
    testWidgets('renders child content and triggers onTap callback', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RpgCard(
              onTap: () => tapped = true,
              child: const Text('Rpg Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Rpg Card Content'), findsOneWidget);
      await tester.tap(find.text('Rpg Card Content'));
      expect(tapped, isTrue);
    });

    testWidgets('renders with various variants and corner accents', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RpgCard(
                  variant: RpgCardVariant.arcane,
                  hasGlow: true,
                  showCornerAccents: true,
                  child: Text('Arcane Card'),
                ),
                RpgCard(variant: RpgCardVariant.gold, child: Text('Gold Card')),
                RpgCard(
                  variant: RpgCardVariant.emerald,
                  child: Text('Emerald Card'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Arcane Card'), findsOneWidget);
      expect(find.text('Gold Card'), findsOneWidget);
      expect(find.text('Emerald Card'), findsOneWidget);
    });
  });

  group('RpgFilledButton Widget Tests', () {
    testWidgets('renders label and icon and responds to taps', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RpgFilledButton(
              label: 'Claim Bounty',
              icon: Icons.check,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Claim Bounty'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text('Claim Bounty'));
      expect(pressed, isTrue);
    });

    testWidgets('renders loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RpgFilledButton(label: 'Loading Quest', isLoading: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Quest'), findsNothing);
    });

    testWidgets('disabled button does not trigger callback', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RpgFilledButton(label: 'Disabled', onPressed: null),
          ),
        ),
      );

      await tester.tap(find.text('Disabled'));
      expect(pressed, isFalse);
    });
  });

  group('KpiStatCard Widget Tests', () {
    testWidgets('renders KPI title, value, icon, and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KpiStatCard(
              title: 'Total Quests',
              value: '42',
              icon: Icons.shield,
              iconColor: RpgColors.rpgEmerald,
              subtitle: '+5 today',
            ),
          ),
        ),
      );

      expect(find.text('Total Quests'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('+5 today'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
    });
  });

  group('XpProgressBar Widget Tests', () {
    testWidgets('renders labels and progress correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XpProgressBar(
              currentXp: 150,
              requiredXp: 300,
              progressRatio: 0.5,
              leadingLabel: 'Level 2',
            ),
          ),
        ),
      );

      expect(find.text('Level 2'), findsOneWidget);
      expect(find.text('150 / 300 XP'), findsOneWidget);
    });

    testWidgets('respects disableAnimations setting', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: XpProgressBar(
                currentXp: 200,
                requiredXp: 400,
                progressRatio: 0.5,
              ),
            ),
          ),
        ),
      );

      expect(find.text('200 / 400 XP'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(XpProgressBar), findsOneWidget);
    });
  });

  group('LevelBadge Widget Tests', () {
    testWidgets('renders level number and rank title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LevelBadge(level: 14, rankTitle: 'Consistency Knight'),
          ),
        ),
      );

      expect(find.text('Lv. 14'), findsOneWidget);
      expect(find.text('Consistency Knight'), findsOneWidget);
    });
  });

  group('QuestProgressIndicator Widget Tests', () {
    testWidgets('renders linear quest completion progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestProgressIndicator(completedQuests: 3, totalQuests: 5),
          ),
        ),
      );

      expect(find.text('Quest Progress'), findsOneWidget);
      expect(find.text('3 / 5 (60%)'), findsOneWidget);
    });

    testWidgets('renders circular quest completion progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuestProgressIndicator(
              completedQuests: 4,
              totalQuests: 4,
              isCircular: true,
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('RpgCrest Widget Tests', () {
    testWidgets('renders with icon and responds to taps', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RpgCrest(
              icon: Icons.shield_rounded,
              tier: RpgGemTier.arcane,
              shape: RpgCrestShape.shield,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
      await tester.tap(find.byType(RpgCrest));
      expect(tapped, isTrue);
    });

    testWidgets('renders with diamond and circle shapes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RpgCrest(
                  icon: Icons.star,
                  shape: RpgCrestShape.diamond,
                  tier: RpgGemTier.gold,
                ),
                RpgCrest(
                  icon: Icons.local_fire_department,
                  shape: RpgCrestShape.octagon,
                  tier: RpgGemTier.ruby,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });
  });

  group('RpgCrestCheckbox Widget Tests', () {
    testWidgets('renders unchecked state and toggles on tap', (tester) async {
      bool value = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return RpgCrestCheckbox(
                  isCompleted: value,
                  onChanged: (newVal) => setState(() => value = newVal),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('unchecked_icon')), findsOneWidget);
      expect(find.byKey(const ValueKey('checked_icon')), findsNothing);

      await tester.tap(find.byType(RpgCrestCheckbox));
      await tester.pumpAndSettle();

      expect(value, isTrue);
      expect(find.byKey(const ValueKey('checked_icon')), findsOneWidget);
    });
  });

  group('RpgDecorativeFrame Widget Tests', () {
    testWidgets('renders framed content with corner brackets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RpgDecorativeFrame(
              showCornerBrackets: true,
              child: Text('Legendary Bounty Frame'),
            ),
          ),
        ),
      );

      expect(find.text('Legendary Bounty Frame'), findsOneWidget);
      expect(find.byType(RpgDecorativeFrame), findsOneWidget);
    });
  });

  group('RpgGemstoneBadge Widget Tests', () {
    testWidgets('renders category label, icon, and handles selection', (
      tester,
    ) async {
      bool selected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return RpgGemstoneBadge(
                  label: 'Health',
                  icon: Icons.spa_rounded,
                  isSelected: selected,
                  onTap: () => setState(() => selected = !selected),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Health'), findsOneWidget);
      expect(find.byIcon(Icons.spa_rounded), findsOneWidget);

      await tester.tap(find.byType(RpgGemstoneBadge));
      await tester.pump();
      expect(selected, isTrue);
    });

    testWidgets('renders XP and streak factory badges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [RpgGemstoneBadge.xp(35), RpgGemstoneBadge.streak(14)],
            ),
          ),
        ),
      );

      expect(find.text('+35 XP'), findsOneWidget);
      expect(find.text('14d'), findsOneWidget);
    });
  });

  group('RpgRunicDivider Widget Tests', () {
    testWidgets('renders horizontal line with center diamond pip', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RpgRunicDivider())),
      );

      expect(find.byType(RpgRunicDivider), findsOneWidget);
    });
  });

  group('Accessibility & Responsiveness Tests', () {
    testWidgets(
      'renders RPG components without overflow on 320px narrow screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const RpgDecorativeFrame(
                      child: Text('Narrow Frame Content'),
                    ),
                    const RpgCard(
                      variant: RpgCardVariant.arcane,
                      child: Text('Narrow Card'),
                    ),
                    RpgGemstoneBadge.xp(100),
                    const LevelBadge(level: 5, rankTitle: 'Adept'),
                    const XpProgressBar(
                      currentXp: 50,
                      requiredXp: 100,
                      progressRatio: 0.5,
                    ),
                    const QuestProgressIndicator(
                      completedQuests: 2,
                      totalQuests: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Narrow Frame Content'), findsOneWidget);
        expect(find.text('Narrow Card'), findsOneWidget);
      },
    );

    testWidgets(
      'renders RPG components with 2.0x large accessibility text scaling',
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      const LevelBadge(level: 12),
                      RpgGemstoneBadge.xp(50),
                      const XpProgressBar(
                        currentXp: 80,
                        requiredXp: 100,
                        progressRatio: 0.8,
                      ),
                      const KpiStatCard(
                        title: 'Total Quests',
                        value: '24',
                        icon: Icons.shield,
                        iconColor: RpgColors.rpgEmerald,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Lv. 12'), findsOneWidget);
        expect(find.text('+50 XP'), findsOneWidget);
      },
    );
  });
}
