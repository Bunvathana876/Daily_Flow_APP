import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/rpg_colors.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsControllerProvider);
    final hapticsEnabled = settings.hapticsEnabled;
    final reminderEnabled = settings.reminderEnabled;
    final reminderTime = TimeOfDay(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
    );

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
                  value: hapticsEnabled,
                  onChanged: (val) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setHapticsEnabled(val);
                    if (val) {
                      ref.read(hapticsServiceProvider).lightImpact();
                    }
                  },
                ),
                const Divider(height: 1, indent: 56),

                // Daily Reminder Toggle
                SwitchListTile(
                  secondary: Icon(
                    reminderEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_outlined,
                    color: reminderEnabled
                        ? RpgColors.warmGold
                        : theme.colorScheme.primary,
                  ),
                  title: const Text('Daily Reminders'),
                  subtitle: Text(
                    _buildReminderSubtitle(settings),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          settings.permissionStatus ==
                                  NotificationPermissionStatus.denied ||
                              settings.permissionStatus ==
                                  NotificationPermissionStatus.permanentlyDenied
                          ? Colors.amber.shade300
                          : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                    ),
                  ),
                  value: reminderEnabled,
                  onChanged: (val) async {
                    ref.read(hapticsServiceProvider).lightImpact();
                    final success = await ref
                        .read(settingsControllerProvider.notifier)
                        .setReminderEnabled(val);
                    if (!context.mounted) return;
                    if (!success && settings.reminderErrorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(settings.reminderErrorMessage!),
                          backgroundColor: Colors.amber.shade900,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 56),

                // Daily Reminder Time Picker
                ListTile(
                  leading: Icon(
                    Icons.alarm_rounded,
                    color: reminderEnabled
                        ? RpgColors.warmGold
                        : theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  title: const Text('Daily Reminder Time'),
                  subtitle: Text(
                    reminderEnabled
                        ? '${reminderTime.format(context)} (Active)'
                        : '${reminderTime.format(context)} (When reminders enabled)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: reminderTime,
                    );
                    if (picked != null) {
                      ref.read(hapticsServiceProvider).selectionClick();
                      final success = await ref
                          .read(settingsControllerProvider.notifier)
                          .setReminderTime(picked);
                      if (!context.mounted) return;
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not reschedule notification for the selected time.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          // In-line Warning/Error Banner if reminder configuration had issues
          if (settings.reminderErrorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.shade600.withValues(alpha: 0.40),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.shade300,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      settings.reminderErrorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFBF8EE),
                        height: 1.3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .clearReminderErrorMessage();
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _buildReminderSubtitle(SettingsState settings) {
    if (settings.reminderEnabled) {
      return 'Active — daily quests reminder scheduled';
    }
    if (settings.permissionStatus == NotificationPermissionStatus.denied ||
        settings.permissionStatus ==
            NotificationPermissionStatus.permanentlyDenied) {
      return 'Permission required — enable notifications in settings';
    }
    return 'Off — turn on to stay consistent with your quests';
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
