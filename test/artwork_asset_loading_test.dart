import 'dart:ui' as ui;
import 'package:daily_flow/core/theme/cozy_artwork.dart';
import 'package:daily_flow/core/widgets/cozy_background.dart';
import 'package:daily_flow/core/widgets/hero_avatar_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cozy Adventure RPG Artwork Verification Suite', () {
    test(
      'All 5 artwork asset binaries load from rootBundle and decode successfully',
      () async {
        final expectedDimensions = <String, Size>{
          CozyArtwork.heroPortraitDefault: const Size(512, 512),
          CozyArtwork.bgFantasyVillage: const Size(1080, 720),
          CozyArtwork.iconQuestJournal: const Size(512, 512),
          CozyArtwork.chestAdventure: const Size(512, 512),
          CozyArtwork.bgFocusChamber: const Size(864, 1080),
        };

        for (final assetPath in CozyArtwork.allAssets) {
          // 1. Verify byte loading
          final byteData = await rootBundle.load(assetPath);
          expect(
            byteData.lengthInBytes,
            greaterThan(0),
            reason: 'Asset $assetPath must contain non-zero bytes',
          );

          // 2. Verify codec decode
          final buffer = byteData.buffer.asUint8List();
          final codec = await ui.instantiateImageCodec(buffer);
          final frameInfo = await codec.getNextFrame();
          final image = frameInfo.image;

          // 3. Verify dimensions
          final expected = expectedDimensions[assetPath]!;
          expect(
            image.width,
            equals(expected.width.toInt()),
            reason: 'Asset $assetPath width must match expected dimensions',
          );
          expect(
            image.height,
            equals(expected.height.toInt()),
            reason: 'Asset $assetPath height must match expected dimensions',
          );
        }
      },
    );

    testWidgets('HeroAvatarFrame renders hero portrait and handles fallbacks', (
      tester,
    ) async {
      // 1. Default hero portrait constructor
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HeroAvatarFrame.heroDefault(size: 80)),
        ),
      );
      await tester.pump();
      expect(find.byType(HeroAvatarFrame), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      // 2. Explicit imageAsset constructor
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeroAvatarFrame(
              size: 80,
              imageAsset: CozyArtwork.heroPortraitDefault,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);

      // 3. Fallback when imageAsset is non-existent
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeroAvatarFrame(
              size: 80,
              imageAsset: 'assets/images/non_existent.png',
              fallbackIcon: Icons.shield_rounded,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);

      // 4. Fallback when imageAsset is null
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeroAvatarFrame(size: 80, fallbackIcon: Icons.person_rounded),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets(
      'CozyBackgroundScaffold renders village and focus chamber backdrops',
      (tester) async {
        // 1. Village backdrop
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const CozyBackgroundScaffold.village(
              body: Text('Fantasy Village Sanctuary'),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(CozyBackgroundScaffold), findsOneWidget);
        expect(find.text('Fantasy Village Sanctuary'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);

        // 2. Focus chamber backdrop
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const CozyBackgroundScaffold.focusChamber(
              body: Text('Arcane Focus Chamber'),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(CozyBackgroundScaffold), findsOneWidget);
        expect(find.text('Arcane Focus Chamber'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);

        // 3. Missing backdrop gracefully falls back to procedural atmosphere
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const CozyBackgroundScaffold(
              backgroundImageAsset: 'assets/images/missing_bg.png',
              body: Text('Fallback Procedural Atmosphere'),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Fallback Procedural Atmosphere'), findsOneWidget);
      },
    );

    testWidgets(
      'Reusable QuestJournalIcon and AdventureChestIcon render properly',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  QuestJournalIcon(size: 40),
                  AdventureChestIcon(size: 56),
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

    testWidgets(
      'CozyArtwork helpers handle forced and missing asset fallbacks',
      (tester) async {
        // 1. Forced fallback
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CozyArtwork.questJournal(size: 36, forceFallback: true),
                  CozyArtwork.adventureChest(size: 48, forceFallback: true),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
        expect(find.byIcon(Icons.inventory_2_rounded), findsOneWidget);

        // 2. Missing asset path fallback
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CozyArtwork.questJournal(
                    size: 36,
                    assetPath: 'assets/images/missing_journal.png',
                  ),
                  CozyArtwork.adventureChest(
                    size: 48,
                    assetPath: 'assets/images/missing_chest.png',
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
        expect(find.byIcon(Icons.inventory_2_rounded), findsOneWidget);

        // 3. Direct fallback builders
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CozyArtwork.questJournalFallback(size: 32),
                  CozyArtwork.adventureChestFallback(size: 44),
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
  });
}
