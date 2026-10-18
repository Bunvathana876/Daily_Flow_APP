import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hapticsEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Appearance & Dark Mode Section
          _buildSectionHeader(context, 'Appearance', Icons.palette_outlined),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        currentThemeMode == ThemeMode.dark
                            ? Icons.dark_mode
                            : currentThemeMode == ThemeMode.light
                                ? Icons.light_mode
                                : Icons.brightness_auto,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Theme Mode',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_outlined),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_outlined),
                        ),
                      ],
                      selected: {currentThemeMode},
                      onSelectionChanged: (newSelection) {
                        if (_hapticsEnabled) {
                          HapticFeedback.lightImpact();
                        }
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(newSelection.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Dark Mode Quick Toggle',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      currentThemeMode == ThemeMode.dark
                          ? 'Dark mode is currently active'
                          : 'Light mode is currently active',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    value: currentThemeMode == ThemeMode.dark,
                    onChanged: (bool value) {
                      if (_hapticsEnabled) {
                        HapticFeedback.lightImpact();
                      }
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Preferences Section
          _buildSectionHeader(context, 'Preferences', Icons.tune_rounded),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.vibration_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Haptic Feedback'),
                  subtitle: const Text(
                    'Vibrate on checking habits and completing timers',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _hapticsEnabled,
                  onChanged: (val) {
                    setState(() {
                      _hapticsEnabled = val;
                    });
                    if (val) {
                      HapticFeedback.lightImpact();
                    }
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(
                    Icons.alarm_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Daily Reminder Time'),
                  subtitle: Text(
                    _reminderTime.format(context),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _reminderTime,
                    );
                    if (picked != null) {
                      setState(() {
                        _reminderTime = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

