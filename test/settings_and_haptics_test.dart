import 'package:daily_flow/core/services/haptics_service.dart';
import 'package:daily_flow/features/settings/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsController & Persistence Tests', () {
    test(
      'defaults to light theme and haptics enabled when no prefs exist',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final state = container.read(settingsControllerProvider);
        expect(state.themeMode, ThemeMode.light);
        expect(state.hapticsEnabled, isTrue);
      },
    );

    test(
      'restores saved dark theme and disabled haptics from SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({
          SettingsController.themePrefKey: 'dark',
          SettingsController.hapticsPrefKey: false,
        });
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final state = container.read(settingsControllerProvider);
        expect(state.themeMode, ThemeMode.dark);
        expect(state.hapticsEnabled, isFalse);
      },
    );

    test(
      'setThemeMode updates state and persists to SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final controller = container.read(settingsControllerProvider.notifier);
        await controller.setThemeMode(ThemeMode.light);

        expect(
          container.read(settingsControllerProvider).themeMode,
          ThemeMode.light,
        );
        expect(prefs.getString(SettingsController.themePrefKey), 'light');

        await controller.setThemeMode(ThemeMode.dark);
        expect(
          container.read(settingsControllerProvider).themeMode,
          ThemeMode.dark,
        );
        expect(prefs.getString(SettingsController.themePrefKey), 'dark');
      },
    );

    test('toggleTheme toggles between dark and light', () async {
      SharedPreferences.setMockInitialValues({
        SettingsController.themePrefKey: 'light',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final controller = container.read(settingsControllerProvider.notifier);
      await controller.toggleTheme();
      expect(
        container.read(settingsControllerProvider).themeMode,
        ThemeMode.dark,
      );
      expect(prefs.getString(SettingsController.themePrefKey), 'dark');

      await controller.toggleTheme();
      expect(
        container.read(settingsControllerProvider).themeMode,
        ThemeMode.light,
      );
      expect(prefs.getString(SettingsController.themePrefKey), 'light');
    });

    test('setHapticsEnabled persists preference', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final controller = container.read(settingsControllerProvider.notifier);
      await controller.setHapticsEnabled(false);

      expect(
        container.read(settingsControllerProvider).hapticsEnabled,
        isFalse,
      );
      expect(prefs.getBool(SettingsController.hapticsPrefKey), isFalse);

      await controller.setHapticsEnabled(true);
      expect(container.read(settingsControllerProvider).hapticsEnabled, isTrue);
      expect(prefs.getBool(SettingsController.hapticsPrefKey), isTrue);
    });

    test(
      'soundEnabled defaults to false and persists to SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final controller = container.read(settingsControllerProvider.notifier);
        expect(
          container.read(settingsControllerProvider).soundEnabled,
          isFalse,
        );

        await controller.setSoundEnabled(true);
        expect(container.read(settingsControllerProvider).soundEnabled, isTrue);
        expect(prefs.getBool(SettingsController.soundPrefKey), isTrue);

        await controller.setSoundEnabled(false);
        expect(
          container.read(settingsControllerProvider).soundEnabled,
          isFalse,
        );
        expect(prefs.getBool(SettingsController.soundPrefKey), isFalse);
      },
    );
  });

  group('HapticsService Tests', () {
    test('dispatches impact when haptics are enabled', () async {
      bool lightFired = false;
      bool mediumFired = false;
      bool heavyFired = false;
      bool selectionFired = false;

      final service = HapticsService(
        isEnabledOverride: () => true,
        onLightImpact: () async => lightFired = true,
        onMediumImpact: () async => mediumFired = true,
        onHeavyImpact: () async => heavyFired = true,
        onSelectionClick: () async => selectionFired = true,
      );

      await service.lightImpact();
      await service.mediumImpact();
      await service.heavyImpact();
      await service.selectionClick();

      expect(lightFired, isTrue);
      expect(mediumFired, isTrue);
      expect(heavyFired, isTrue);
      expect(selectionFired, isTrue);

      lightFired = false;
      mediumFired = false;
      await service.milestoneReached();
      expect(lightFired, isTrue);
      expect(mediumFired, isTrue);
    });

    test('does NOT dispatch impact when haptics are disabled', () async {
      bool lightFired = false;
      bool mediumFired = false;
      bool heavyFired = false;
      bool selectionFired = false;

      final service = HapticsService(
        isEnabledOverride: () => false,
        onLightImpact: () async => lightFired = true,
        onMediumImpact: () async => mediumFired = true,
        onHeavyImpact: () async => heavyFired = true,
        onSelectionClick: () async => selectionFired = true,
      );

      await service.lightImpact();
      await service.mediumImpact();
      await service.heavyImpact();
      await service.selectionClick();

      expect(lightFired, isFalse);
      expect(mediumFired, isFalse);
      expect(heavyFired, isFalse);
      expect(selectionFired, isFalse);
    });
  });
}
