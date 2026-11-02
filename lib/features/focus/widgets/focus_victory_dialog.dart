import 'package:flutter/material.dart';
import '../../../../core/theme/rpg_colors.dart';
import '../../../../core/theme/rpg_spacing.dart';
import '../../../../core/utils/gamification_math.dart';
import '../../../../core/widgets/cozy_button.dart';
import '../../../../core/widgets/level_badge.dart';
import '../../../../core/widgets/rpg_crest.dart';
import '../../gamification/models/user_profile.dart';

/// Celebratory Cozy Adventure RPG modal presented upon completing a focus trial.
/// Displays actual XP awarded, linked quest fulfillment status, updated hero level,
/// and daily focus XP cap status with rich fantasy styling.
class FocusVictoryDialog extends StatelessWidget {
  final int awardedXp;
  final String? completedHabitTitle;
  final UserProfile profile;
  final VoidCallback? onDismiss;

  const FocusVictoryDialog({
    super.key,
    required this.awardedXp,
    this.completedHabitTitle,
    required this.profile,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required int awardedXp,
    String? completedHabitTitle,
    required UserProfile profile,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => FocusVictoryDialog(
        awardedXp: awardedXp,
        completedHabitTitle: completedHabitTitle,
        profile: profile,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final rankTitle = GamificationMath.rankTitleForLevel(profile.currentLevel);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: disableAnimations ? 1.0 : 0.88, end: 1.0),
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          padding: const EdgeInsets.all(RpgSpacing.xl),
          decoration: BoxDecoration(
            color: isDark ? RpgColors.softIndigo : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? RpgColors.warmGold.withValues(alpha: 0.60)
                  : RpgColors.warmGold.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Arcane Victory Crest
              RpgCrest(
                size: 64,
                shape: RpgCrestShape.shield,
                tier: RpgGemTier.gold,
                hasGlow: true,
                icon: Icons.hourglass_bottom_rounded,
              ),
              const SizedBox(height: RpgSpacing.md),

              // Title
              Text(
                'TRIAL CONQUERED!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: isDark ? RpgColors.rpgGold : const Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: RpgSpacing.sm),

              // XP Reward Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RpgSpacing.md,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: awardedXp > 0 ? RpgColors.goldGradient : null,
                  color: awardedXp == 0
                      ? (isDark ? Colors.white12 : Colors.grey.shade200)
                      : null,
                  borderRadius: RpgSpacing.roundedPill,
                  border: Border.all(
                    color: awardedXp > 0
                        ? RpgColors.rpgGoldBright
                        : Colors.transparent,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: awardedXp > 0
                          ? const Color(0xFF2B1602)
                          : (isDark ? Colors.grey : Colors.black54),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      awardedXp > 0
                          ? '+$awardedXp Focus XP Earned'
                          : 'Daily 180 Focus XP Cap Reached (+0 XP)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: awardedXp > 0
                            ? const Color(0xFF2B1602)
                            : (isDark ? Colors.grey : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RpgSpacing.sm),

              // Daily Focus XP Cap Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      size: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Daily Focus XP Cap: Max ${GamificationMath.maxFocusSessionXpPerDay} XP / day',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RpgSpacing.md),

              // Linked Quest Completed status
              if (completedHabitTitle != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: RpgColors.questEmerald.withValues(
                      alpha: isDark ? 0.16 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(RpgSpacing.radiusSm),
                    border: Border.all(
                      color: RpgColors.questEmerald.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: RpgColors.questEmerald,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Quest "$completedHabitTitle" completed for today!',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: RpgColors.questEmerald,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: RpgSpacing.md),
              ],

              // Player Stats Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? RpgColors.midnightNavy.withValues(alpha: 0.50)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? RpgColors.cozyBorderDark
                        : RpgColors.rpgBorderLight,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LevelBadge(level: profile.currentLevel, compact: true),
                    const SizedBox(width: RpgSpacing.sm),
                    Text(
                      '${profile.totalXp} Total XP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: RpgSpacing.sm),
                    Text(
                      '•  $rankTitle',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? RpgColors.warmGold
                            : RpgColors.arcaneViolet,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RpgSpacing.sm),

              Text(
                'Your deep work channels power to your spirit. Rest well or begin your next quest.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: RpgSpacing.lg),

              // Dismiss Action Button
              CozyButton.primary(
                label: 'Claim Victory',
                leadingIcon: Icons.shield_rounded,
                width: double.infinity,
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
