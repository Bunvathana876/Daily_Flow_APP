import 'package:flutter/material.dart';
import '../../../core/theme/rpg_colors.dart';
import '../../../core/theme/rpg_spacing.dart';
import '../../gamification/models/achievement.dart';
import 'achievement_details_dialog.dart';

/// Compact RPG card tile displaying an achievement badge in the Illuminated Trophy Case.
class AchievementBadgeTile extends StatelessWidget {
  final Achievement achievement;

  const AchievementBadgeTile({super.key, required this.achievement});

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

  String _getRarityLabel(int targetValue) {
    if (targetValue >= 100) return 'LEGENDARY';
    if (targetValue >= 30) return 'EPIC';
    if (targetValue >= 7) return 'RARE';
    return 'COMMON';
  }

  Color _getRarityColor(int targetValue) {
    if (targetValue >= 100) return RpgColors.rpgGold;
    if (targetValue >= 30) return RpgColors.arcaneViolet;
    if (targetValue >= 7) return const Color(0xFF38BDF8); // Cyan
    return const Color(0xFF10B981); // Emerald
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnlocked = achievement.isUnlocked;
    final ratio = achievement.progressRatio;
    final iconData = _getIconData(achievement.iconKey);
    final rarityLabel = _getRarityLabel(achievement.targetValue);
    final rarityColor = _getRarityColor(achievement.targetValue);

    return Semantics(
      button: true,
      label:
          '${achievement.title}, $rarityLabel, ${isUnlocked ? "Unlocked" : "Locked (${achievement.currentProgress} of ${achievement.targetValue})"}. Reward: ${achievement.xpReward} XP',
      child: InkWell(
        onTap: () => AchievementDetailsDialog.show(context, achievement),
        borderRadius: BorderRadius.circular(RpgSpacing.radiusMd),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: RpgSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isUnlocked
                ? (isDark ? RpgColors.abyssNavySurface : Colors.white)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(RpgSpacing.radiusMd),
            border: Border.all(
              color: isUnlocked
                  ? RpgColors.rpgGold.withValues(alpha: 0.5)
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
              width: isUnlocked ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnlocked
                    ? RpgColors.rpgGold.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Badge Icon Seal with Rarity Glow
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isUnlocked ? RpgColors.goldGradient : null,
                  color: isUnlocked
                      ? null
                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                  border: Border.all(
                    color: isUnlocked
                        ? RpgColors.rpgGold
                        : (isDark ? Colors.white12 : Colors.grey.shade300),
                    width: 1.2,
                  ),
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: RpgColors.rpgGold.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    size: 24,
                    color: isUnlocked
                        ? Colors.white
                        : (isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade600),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Lore & Progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  achievement.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Rarity Tag
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: rarityColor.withValues(
                                    alpha: isDark ? 0.18 : 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: rarityColor.withValues(
                                      alpha: isDark ? 0.4 : 0.25,
                                    ),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  rarityLabel,
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: rarityColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // XP Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: RpgColors.rpgGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+${achievement.xpReward} XP',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: RpgColors.rpgGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Progress bar & counter
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 4,
                              backgroundColor: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isUnlocked
                                    ? RpgColors.rpgGold
                                    : RpgColors.questEmerald,
                              ),
                            ),
                          ),
                        ),
                        if (!isUnlocked) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${achievement.currentProgress}/${achievement.targetValue}',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Status Icon / Lock
              Icon(
                isUnlocked
                    ? Icons.check_circle_rounded
                    : Icons.lock_outline_rounded,
                size: 20,
                color: isUnlocked
                    ? RpgColors.questEmerald
                    : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
