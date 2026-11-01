import 'package:flutter/material.dart';
import '../theme/rpg_colors.dart';
import '../theme/rpg_spacing.dart';
import '../../features/gamification/models/achievement.dart';

/// Reusable non-blocking RPG celebration toast / banner.
class RpgCelebrationBanner {
  static void showAchievementUnlocked(
    BuildContext context,
    Achievement achievement,
  ) {
    show(
      context,
      title: 'Achievement Unlocked!',
      subtitle: '${achievement.title} (+${achievement.xpReward} XP)',
      icon: Icons.military_tech_rounded,
      iconColor: RpgColors.rpgGold,
    );
  }

  static void showMilestone(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData icon = Icons.workspace_premium_rounded,
    Color iconColor = RpgColors.rpgGold,
  }) {
    show(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData icon = Icons.auto_awesome_rounded,
    Color iconColor = RpgColors.rpgGold,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? RpgColors.abyssNavySurface
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(RpgSpacing.radiusMd),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: iconColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
