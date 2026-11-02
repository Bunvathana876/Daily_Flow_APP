import 'package:flutter/material.dart';
import '../../../core/theme/rpg_colors.dart';
import '../../../core/theme/rpg_spacing.dart';
import '../../gamification/models/achievement.dart';
import 'achievement_details_dialog.dart';

/// Compact RPG trophy tile displaying an achievement emblem and status in the Trophy Room Grid.
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isUnlocked
                ? (isDark ? RpgColors.abyssNavySurface : Colors.white)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(RpgSpacing.radiusMd),
            border: Border.all(
              color: isUnlocked
                  ? RpgColors.rpgGold.withValues(alpha: 0.45)
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
              width: isUnlocked ? 1.2 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnlocked
                    ? RpgColors.rpgGold.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top tags row: Rarity tag + XP tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(
                          alpha: isDark ? 0.18 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: rarityColor.withValues(
                            alpha: isDark ? 0.4 : 0.25,
                          ),
                          width: 0.7,
                        ),
                      ),
                      child: Text(
                        rarityLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: rarityColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: RpgColors.rpgGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '+${achievement.xpReward} XP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: RpgColors.rpgGold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Emblem Circle with Icon & Status Lock/Check badge
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
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
                                color: RpgColors.rpgGold.withValues(
                                  alpha: 0.30,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        iconData,
                        size: 20,
                        color: isUnlocked
                            ? Colors.white
                            : (isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade600),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? RpgColors.abyssNavySurface
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isUnlocked
                              ? RpgColors.questEmerald
                              : (isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        isUnlocked
                            ? Icons.check_circle_rounded
                            : Icons.lock_outline_rounded,
                        size: 11,
                        color: isUnlocked
                            ? RpgColors.questEmerald
                            : (isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Title
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),

              // Progress Bar & Counter (or Status when Unlocked)
              if (isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: RpgColors.questEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'UNLOCKED',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: RpgColors.questEmerald,
                      letterSpacing: 0.4,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 3.5,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            RpgColors.questEmerald,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${achievement.currentProgress}/${achievement.targetValue}',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
