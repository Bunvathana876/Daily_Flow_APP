import 'package:flutter/material.dart';
import '../../../core/theme/rpg_colors.dart';
import '../../../core/theme/rpg_spacing.dart';
import '../../../core/widgets/rpg_filled_button.dart';
import '../../gamification/models/achievement.dart';

/// Modal dialog providing lore, requirements, and progress details for an achievement badge.
class AchievementDetailsDialog extends StatelessWidget {
  final Achievement achievement;

  const AchievementDetailsDialog({super.key, required this.achievement});

  static Future<void> show(BuildContext context, Achievement achievement) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AchievementDetailsDialog(achievement: achievement),
    );
  }

  IconData _getIconData(String iconKey) {
    switch (iconKey) {
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      case 'hourglass_top':
        return Icons.hourglass_top_rounded;
      case 'timer':
        return Icons.timer_rounded;
      case 'group_work':
        return Icons.group_work_rounded;
      case 'category':
        return Icons.category_rounded;
      case 'check_circle':
        return Icons.check_circle_rounded;
      case 'auto_stories':
        return Icons.auto_stories_rounded;
      default:
        return Icons.stars_rounded;
    }
  }

  String _getPathTitle(String category) {
    switch (category.toLowerCase()) {
      case 'streaks':
        return "The Warrior's Path";
      case 'focus':
        return "The Scholar's Path";
      case 'habits':
      case 'mastery':
      default:
        return "The Architect's Path";
    }
  }

  String _getRarityLabel(int targetValue) {
    if (targetValue >= 100) return 'LEGENDARY';
    if (targetValue >= 30) return 'EPIC';
    if (targetValue >= 7) return 'RARE';
    return 'COMMON';
  }

  Color _getRarityColor(int targetValue) {
    if (targetValue >= 100) return RpgColors.rpgGold;
    if (targetValue >= 30) return RpgColors.arcaneViolet;
    if (targetValue >= 7) return const Color(0xFF38BDF8);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnlocked = achievement.isUnlocked;
    final progress = achievement.currentProgress;
    final target = achievement.targetValue;
    final ratio = achievement.progressRatio;
    final pathTitle = _getPathTitle(achievement.category);
    final iconData = _getIconData(achievement.iconKey);
    final rarityLabel = _getRarityLabel(achievement.targetValue);
    final rarityColor = _getRarityColor(achievement.targetValue);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(RpgSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? RpgColors.abyssNavySurface : Colors.white,
          borderRadius: BorderRadius.circular(RpgSpacing.radiusLg),
          border: Border.all(
            color: isUnlocked
                ? RpgColors.rpgGold.withValues(alpha: 0.6)
                : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: isUnlocked ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? RpgColors.rpgGold.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Seal Emblem
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isUnlocked
                      ? RpgColors.goldGradient
                      : LinearGradient(
                          colors: isDark
                              ? [Colors.white12, Colors.white10]
                              : [Colors.grey.shade300, Colors.grey.shade200],
                        ),
                  border: Border.all(
                    color: isUnlocked
                        ? RpgColors.rpgGold
                        : (isDark ? Colors.white24 : Colors.grey.shade400),
                    width: 2.0,
                  ),
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: RpgColors.rpgGold.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    size: 40,
                    color: isUnlocked
                        ? Colors.white
                        : (isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade600),
                  ),
                ),
              ),
              const SizedBox(height: RpgSpacing.md),

              // Rarity & Path Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: RpgColors.arcaneViolet.withValues(alpha: 0.14),
                      borderRadius: RpgSpacing.roundedPill,
                      border: Border.all(
                        color: RpgColors.arcaneViolet.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      pathTitle.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: RpgColors.arcaneViolet,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.15),
                      borderRadius: RpgSpacing.roundedPill,
                      border: Border.all(
                        color: rarityColor.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      rarityLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: rarityColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Lore / Description
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 18),

              // Progress Bar & Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROGRESS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    isUnlocked
                        ? 'COMPLETED ($target / $target)'
                        : '$progress / $target (${(ratio * 100).round()}%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? RpgColors.questEmerald
                          : (isDark ? Colors.grey.shade300 : Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? Colors.white10
                      : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUnlocked ? RpgColors.rpgGold : RpgColors.questEmerald,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reward & Status Row
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  // XP Reward
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: RpgColors.rpgGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: RpgColors.rpgGold.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: RpgColors.rpgGold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${achievement.xpReward} XP Reward',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: RpgColors.rpgGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? RpgColors.questEmerald.withValues(alpha: 0.15)
                          : (isDark ? Colors.white10 : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isUnlocked
                            ? RpgColors.questEmerald.withValues(alpha: 0.4)
                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUnlocked
                              ? Icons.check_circle_rounded
                              : Icons.lock_outline_rounded,
                          size: 13,
                          color: isUnlocked
                              ? RpgColors.questEmerald
                              : (isDark ? Colors.grey : Colors.grey.shade600),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isUnlocked
                              ? (achievement.unlockedAt != null
                                    ? 'Unlocked ${achievement.unlockedAt!.toIso8601String().substring(0, 10)}'
                                    : 'Unlocked')
                              : 'Locked',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? RpgColors.questEmerald
                                : (isDark ? Colors.grey : Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action
              RpgFilledButton(
                label: 'Claim Honor',
                icon: Icons.shield_rounded,
                width: double.infinity,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
