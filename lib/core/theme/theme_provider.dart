import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/controllers/settings_controller.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final settings = ref.watch(settingsControllerProvider);
    return settings.themeMode;
  }

  void setThemeMode(ThemeMode mode) {
    ref.read(settingsControllerProvider.notifier).setThemeMode(mode);
  }

  void toggleTheme() {
    ref.read(settingsControllerProvider.notifier).toggleTheme();
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
