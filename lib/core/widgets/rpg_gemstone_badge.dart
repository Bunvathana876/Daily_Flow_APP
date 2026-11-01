import 'package:flutter/material.dart';
import '../theme/rpg_colors.dart';
import '../theme/rpg_spacing.dart';
import '../theme/rpg_text_styles.dart';

/// Compact faceted gemstone badge / chip for quest categories, XP rewards,
/// and streak counters.
class RpgGemstoneBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool isSelected;
  final bool isGlow;
  final bool compact;
  final VoidCallback? onTap;

  const RpgGemstoneBadge({
    super.key,
    required this.label,
    this.icon,
    this.color = RpgColors.rpgIndigo,
    this.isSelected = false,
    this.isGlow = false,
    this.compact = false,
    this.onTap,
  });

  /// Factory helper for golden XP reward tags (e.g. "+25 XP")
  factory RpgGemstoneBadge.xp(int amount, {bool compact = false}) {
    return RpgGemstoneBadge(
      label: '+$amount XP',
      icon: Icons.auto_awesome_rounded,
      color: RpgColors.rpgGold,
      isGlow: true,
      compact: compact,
    );
  }

  /// Factory helper for streak fire tags (e.g. "🔥 12d")
  factory RpgGemstoneBadge.streak(int streakDays, {bool compact = false}) {
    return RpgGemstoneBadge(
      label: '${streakDays}d',
      icon: Icons.local_fire_department_rounded,
      color: RpgColors.rpgGoldBright,
      isGlow: true,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = color;
    final bg = isSelected
        ? baseColor
        : (isDark
              ? baseColor.withValues(alpha: 0.16)
              : baseColor.withValues(alpha: 0.10));

    final textColor = isSelected
        ? Colors.white
        : (isDark ? baseColor : Color.lerp(baseColor, Colors.black, 0.25)!);

    final borderColor = isSelected
        ? baseColor
        : (isDark
              ? baseColor.withValues(alpha: 0.35)
              : baseColor.withValues(alpha: 0.25));

    Widget badgeContent = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? RpgSpacing.sm : RpgSpacing.md,
        vertical: compact ? 3.0 : 6.0,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(RpgSpacing.radiusPill),
        border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        boxShadow: (isGlow || isSelected)
            ? [
                BoxShadow(
                  color: baseColor.withValues(alpha: isDark ? 0.30 : 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style:
                (compact ? RpgTextStyles.labelSmall : RpgTextStyles.labelMedium)
                    .copyWith(color: textColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: badgeContent,
      );
    }

    return badgeContent;
  }
}
