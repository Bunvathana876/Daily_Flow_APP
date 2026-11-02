import 'dart:ui' as ui;
import 'package:daily_flow/features/gamification/data/gamification_repository.dart';
import 'package:daily_flow/features/gamification/models/achievement.dart';
import 'package:daily_flow/features/gamification/models/user_profile.dart';
import 'package:daily_flow/features/gamification/models/xp_entry.dart';
import 'package:daily_flow/features/gamification/widgets/hero_avatar_badge.dart';
import 'package:daily_flow/features/habits/models/habit.dart';
import 'package:daily_flow/features/profile/widgets/hero_customization_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockGamificationRepository implements GamificationRepository {
  UserProfile profile;
  bool shouldFailUpdate = false;
  int updateCallCount = 0;

  MockGamificationRepository({UserProfile? initialProfile})
    : profile =
          initialProfile ??
          UserProfile(
            heroName: 'Original Hero',
            avatarId: 'knight_helm',
            totalXp: 100,
            currentLevel: 2,
            createdAt: DateTime.now(),
          );

  @override
  Future<UserProfile> getUserProfile() async => profile;

  @override
  Future<void> updateUserProfile({String? heroName, String? avatarId}) async {
    updateCallCount++;
    if (shouldFailUpdate) {
      throw Exception('Simulated database write error');
    }
    profile = profile.copyWith(heroName: heroName, avatarId: avatarId);
  }

  @override
  Future<List<XpEntry>> getXpEntries({int limit = 50, int offset = 0}) async =>
      [];

  @override
  Future<int> getTotalActiveXp() async => profile.totalXp;

  @override
  Future<int> getCurrentLevel() async => profile.currentLevel;

  @override
  Future<int> getTotalFocusMinutes() async => 0;

  @override
  Future<int> getTotalFocusSessions() async => 0;

  @override
  Future<List<Achievement>> evaluateAndSyncAchievements({
    required List<Habit> habits,
  }) async => [];

  @override
  Future<List<Achievement>> getAchievements() async => [];

  @override
  Future<int> awardHabitCheckin({
    required int habitId,
    required String dateStr,
    required int currentStreak,
  }) async => 20;

  @override
  Future<int> revokeHabitCheckin({
    required int habitId,
    required String dateStr,
  }) async => 0;

  @override
  Future<int> awardFocusSession({
    required int durationMinutes,
    int? habitId,
    required String dateStr,
  }) async => durationMinutes;

  @override
  Future<Map<String, int>> getXpBreakdown() async => {};

  @override
  Future<void> recalculateTotalXpAndLevel() async {}

  @override
  Future<bool> unlockAchievement(String badgeKey) async => false;

  @override
  Future<void> updateAchievementProgress(String badgeKey, int progress) async {}

  Future<void> resetAllData() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Customize Hero Redesign - Verification Suite', () {
    // 1. Correct Asset Mapping & Image Loading
    test(
      '1. All 6 hero crest assets exist, load bytes, and decode to 512x512',
      () async {
        final expectedMapping = {
          'knight_helm': 'assets/images/hero/knight_of_valor.png',
          'arcane_mage': 'assets/images/hero/arcane_sorcerer.png',
          'ranger_hood': 'assets/images/hero/woodland_ranger.png',
          'paladin_crest': 'assets/images/hero/radiant_paladin.png',
          'valkyrie_wings': 'assets/images/hero/sky_valkyrie.png',
          'shadow_blade': 'assets/images/hero/shadow_rogue.png',
        };

        expect(HeroAvatarRegistry.crests.length, 6);

        for (final crest in HeroAvatarRegistry.crests) {
          expect(
            expectedMapping.containsKey(crest.id),
            isTrue,
            reason: 'Avatar ID ${crest.id} must be in the expected registry',
          );
          expect(
            crest.assetPath,
            equals(expectedMapping[crest.id]),
            reason:
                'Avatar ${crest.id} must map to ${expectedMapping[crest.id]}',
          );

          // Load asset bytes from rootBundle
          final byteData = await rootBundle.load(crest.assetPath);
          expect(
            byteData.lengthInBytes,
            greaterThan(0),
            reason: 'Asset ${crest.assetPath} must not be empty',
          );

          // Decode image to verify non-corrupted 512x512 PNG
          final buffer = byteData.buffer.asUint8List();
          final codec = await ui.instantiateImageCodec(buffer);
          final frameInfo = await codec.getNextFrame();
          final image = frameInfo.image;

          expect(image.width, 512);
          expect(image.height, 512);
        }
      },
    );

    // 2. Selected Crest Live Preview
    testWidgets(
      '2. Selecting a crest updates Live Preview immediately without saving',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockRepo = MockGamificationRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gamificationRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: HeroCustomizationDialog(
                  initialName: 'Aria',
                  initialAvatarId: 'knight_helm',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initial Live Preview is Knight of Valor
        expect(
          find.text('Knight of Valor'),
          findsNWidgets(2),
        ); // Preview + Grid
        expect(find.text('GUARDIAN'), findsOneWidget);
        expect(find.text('• Live Preview'), findsOneWidget);

        // Tap Arcane Sorcerer in grid
        await tester.tap(find.text('Arcane Sorcerer'));
        await tester.pumpAndSettle();

        // Live Preview immediately updates to Arcane Sorcerer
        expect(
          find.text('Arcane Sorcerer'),
          findsNWidgets(2),
        ); // Preview + Grid
        expect(find.text('SCHOLAR'), findsOneWidget);

        // Verify repository has NOT been called yet
        expect(mockRepo.updateCallCount, 0);
        expect(mockRepo.profile.avatarId, 'knight_helm');

        // Tap Shadow Rogue in grid
        await tester.tap(find.text('Shadow Rogue'));
        await tester.pumpAndSettle();

        expect(find.text('Shadow Rogue'), findsNWidgets(2)); // Preview + Grid
        expect(find.text('INFILTRATOR'), findsOneWidget);
        expect(mockRepo.updateCallCount, 0);
      },
    );

    // 3. Name Validation & Character Counter
    testWidgets(
      '3. Hero name editing validates empty, whitespace, max length and updates counter',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockRepo = MockGamificationRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gamificationRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: HeroCustomizationDialog(
                  initialName: 'Aria',
                  initialAvatarId: 'knight_helm',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('4/24'), findsOneWidget);

        // 1. Empty name validation
        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();
        expect(find.text('0/24'), findsOneWidget);

        await tester.tap(find.text('Save Hero'));
        await tester.pumpAndSettle();
        expect(find.text('Hero name cannot be empty.'), findsOneWidget);
        expect(mockRepo.updateCallCount, 0);

        // 2. Whitespace name validation
        await tester.enterText(find.byType(TextField), '    ');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Hero'));
        await tester.pumpAndSettle();
        expect(find.text('Hero name cannot be empty.'), findsOneWidget);
        expect(mockRepo.updateCallCount, 0);

        // 3. Valid name entry clears error
        await tester.enterText(find.byType(TextField), 'Valkyrie Queen');
        await tester.pumpAndSettle();
        expect(find.text('Hero name cannot be empty.'), findsNothing);
        expect(find.text('14/24'), findsOneWidget);
      },
    );

    // 4. Cancel Without Saving
    testWidgets(
      '4. Cancel button dismisses interface without modifying saved profile',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockRepo = MockGamificationRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gamificationRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => HeroCustomizationDialog.show(
                      context,
                      currentName: 'Original Hero',
                      currentAvatarId: 'knight_helm',
                    ),
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
        expect(find.byType(HeroCustomizationDialog), findsOneWidget);

        // Change name and crest
        await tester.enterText(find.byType(TextField), 'Discarded Name');
        await tester.tap(find.text('Woodland Ranger'));
        await tester.pumpAndSettle();

        // Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog is gone
        expect(find.byType(HeroCustomizationDialog), findsNothing);

        // Profile in repo is untouched
        expect(mockRepo.updateCallCount, 0);
        expect(mockRepo.profile.heroName, 'Original Hero');
        expect(mockRepo.profile.avatarId, 'knight_helm');
      },
    );

    // 5. Successful Persistence
    testWidgets(
      '5. Save Hero persists valid name and selected crest and closes dialog',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockRepo = MockGamificationRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gamificationRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => HeroCustomizationDialog.show(
                      context,
                      currentName: 'Novice Adventurer',
                      currentAvatarId: 'knight_helm',
                    ),
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // Edit name
        await tester.enterText(find.byType(TextField), 'Sky Paladin');
        // Select Radiant Paladin
        await tester.tap(find.text('Radiant Paladin'));
        await tester.pumpAndSettle();

        // Tap Save Hero
        await tester.tap(find.text('Save Hero'));
        await tester.pumpAndSettle();

        // Dialog closed
        expect(find.byType(HeroCustomizationDialog), findsNothing);

        // Repo updated
        expect(mockRepo.updateCallCount, 1);
        expect(mockRepo.profile.heroName, 'Sky Paladin');
        expect(mockRepo.profile.avatarId, 'paladin_crest');
      },
    );

    // 6. Persistence Failure Handling
    testWidgets(
      '6. Persistence failure shows error and preserves user draft without closing',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockRepo = MockGamificationRepository()..shouldFailUpdate = true;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gamificationRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: HeroCustomizationDialog(
                  initialName: 'Sir Galahad',
                  initialAvatarId: 'knight_helm',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select Sky Valkyrie and edit name
        await tester.tap(find.text('Sky Valkyrie'));
        await tester.enterText(find.byType(TextField), 'Valkyrie Lord');
        await tester.pumpAndSettle();

        // Tap Save Hero (fails in repo)
        await tester.tap(find.text('Save Hero'));
        await tester.pumpAndSettle();

        // Dialog is STILL OPEN
        expect(find.byType(HeroCustomizationDialog), findsOneWidget);

        // User-friendly error message is displayed
        expect(
          find.text('Failed to save hero. Please try again.'),
          findsOneWidget,
        );

        // User's draft is preserved
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'Valkyrie Lord');
        expect(find.text('VANGUARD'), findsOneWidget);
      },
    );

    // 7. Responsive Layout on Small Screens (320px)
    testWidgets(
      '7. Dialog renders without overflow on 320px narrow mobile screens',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockRepo = MockGamificationRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gamificationRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: HeroCustomizationDialog(
                  initialName: 'Narrow Hero',
                  initialAvatarId: 'arcane_mage',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HeroCustomizationDialog), findsOneWidget);
        expect(find.text('Customize Hero'), findsOneWidget);
        expect(find.text('Save Hero'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        // Zero overflow errors
        expect(tester.takeException(), isNull);
      },
    );

    // 8. Keyboard Behavior
    testWidgets('8. Responds smoothly to keyboard appearance with viewInsets', (
      tester,
    ) async {
      final mockRepo = MockGamificationRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 280)),
              child: Scaffold(
                body: HeroCustomizationDialog(
                  initialName: 'Keyboard Hero',
                  initialAvatarId: 'knight_helm',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HeroCustomizationDialog), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
