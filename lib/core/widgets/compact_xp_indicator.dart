import 'package:flutter/material.dart';
import '../theme/rpg_colors.dart';
import '../theme/rpg_spacing.dart';
import '../theme/rpg_text_styles.dart';

/// Compact, elegant XP progress bar designed for header HUDs and character sheets.
class CompactXpBar extends StatelessWidget {
  final int currentXp;
  final int requiredXp;
  final double progressRatio;
  final double height;
  final bool showLabel;
  final Gradient? gradient;

  const CompactXpBar({
    super.key,
    required this.currentXp,
    required this.requiredXp,
    required this.progressRatio,
    this.height = 6.0,
    this.showLabel = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clampedRatio = progressRatio.clamp(0.0, 1.0);
    final effectiveGradient =
        gradient ??
        const LinearGradient(
          colors: [
            RpgColors.mutedViolet,
            Color(0xFF6B58B8),
            RpgColors.warmGold,
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(
            '$currentXp / $requiredXp XP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFFB0B9D0)
                  : RpgColors.textSecondaryLight,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 3),
        ],
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            color: isDark ? const Color(0xFF0F162B) : Colors.grey.shade200,
            border: Border.all(
              color: isDark
                  ? RpgColors.cozyBorderDark
                  : RpgColors.rpgBorderLight,
              width: 0.6,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clampedRatio,
              child: Container(
                decoration: BoxDecoration(
                  gradient: effectiveGradient,
                  boxShadow: [
                    BoxShadow(
                      color: RpgColors.warmGold.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact XP Reward Tag Badge (e.g. "+120 XP", "+25 XP")
/// Used in quest cards, focus timer, and bounty headers.
class XpRewardBadge extends StatelessWidget {
  final int xp;
  final IconData? icon;
  final bool isGlowing;
  final VoidCallback? onTap;

  const XpRewardBadge({
    super.key,
    required this.xp,
    this.icon = Icons.auto_awesome_rounded,
    this.isGlowing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark
            ? RpgColors.warmGold.withValues(alpha: 0.16)
            : RpgColors.warmGold.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(RpgSpacing.radiusPill),
        border: Border.all(
          color: RpgColors.warmGold.withValues(alpha: isDark ? 0.40 : 0.50),
          width: 0.9,
        ),
        boxShadow: isGlowing
            ? [
                BoxShadow(
                  color: RpgColors.warmGold.withValues(
                    alpha: isDark ? 0.35 : 0.20,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: RpgColors.warmGold),
            const SizedBox(width: 3.5),
          ],
          Text(
            '+$xp XP',
            style: RpgTextStyles.xpBadgeText.copyWith(
              color: isDark ? RpgColors.warmGold : const Color(0xFFB45309),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      badge = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: badge,
      );
    }

    return badge;
  }
}
