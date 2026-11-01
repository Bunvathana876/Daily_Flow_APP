import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode themeMode;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final bool isLoaded;

  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.hapticsEnabled = true,
    this.soundEnabled = false,
    this.isLoaded = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? hapticsEnabled,
    bool? soundEnabled,
    bool? isLoaded,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

class SettingsController extends Notifier<SettingsState> {
  static const String themePrefKey = 'daily_flow_theme_mode';
  static const String hapticsPrefKey = 'daily_flow_haptics_enabled';
  static const String soundPrefKey = 'daily_flow_sound_enabled';

  SharedPreferences? _prefs;

  @override
  SettingsState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    if (_prefs != null) {
      return _buildStateFromPrefs(_prefs!);
    } else {
      Future.microtask(() => _asyncLoad());
      return const SettingsState();
    }
  }

  SettingsState _buildStateFromPrefs(SharedPreferences prefs) {
    final themeStr = prefs.getString(themePrefKey);
    final haptics = prefs.getBool(hapticsPrefKey) ?? true;
    final sound = prefs.getBool(soundPrefKey) ?? false;

    ThemeMode mode = ThemeMode.light;
    if (themeStr == 'dark') {
      mode = ThemeMode.dark;
    } else if (themeStr == 'system') {
      mode = ThemeMode.system;
    }

    return SettingsState(
      themeMode: mode,
      hapticsEnabled: haptics,
      soundEnabled: sound,
      isLoaded: true,
    );
  }

  Future<void> _asyncLoad() async {
    _prefs = await SharedPreferences.getInstance();
    state = _buildStateFromPrefs(_prefs!);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    _prefs ??= await SharedPreferences.getInstance();
    final str = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
        ? 'dark'
        : 'system';
    await _prefs?.setString(themePrefKey, str);
  }

  Future<void> toggleTheme() async {
    final next = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(next);
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    state = state.copyWith(hapticsEnabled: enabled);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool(hapticsPrefKey, enabled);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool(soundPrefKey, enabled);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
