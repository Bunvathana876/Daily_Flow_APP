import 'package:flutter/material.dart';
import '../theme/rpg_colors.dart';
import '../theme/rpg_spacing.dart';
import '../theme/rpg_text_styles.dart';
import 'rpg_card.dart';

/// Reusable analytical metric card for KPI displays across DailyFlow screens.
/// Features a faceted gemstone icon container and crisp RPG typography.
class KpiStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isCompact;
  final bool prominentValue;

  const KpiStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    this.onTap,
    this.isCompact = false,
    this.prominentValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RpgCard(
      onTap: onTap,
      variant: RpgCardVariant.standard,
      padding: prominentValue
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
          : EdgeInsets.symmetric(
              horizontal: isCompact ? RpgSpacing.sm : RpgSpacing.md,
              vertical: isCompact ? RpgSpacing.sm : RpgSpacing.md,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(prominentValue ? 4 : 6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: RpgSpacing.roundedSmall,
                  border: Border.all(
                    color: iconColor.withValues(alpha: isDark ? 0.40 : 0.25),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: isDark ? 0.20 : 0.08),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: prominentValue ? 14 : (isCompact ? 16 : 20),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtitle!,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(
            height: prominentValue
                ? 4
                : (isCompact ? RpgSpacing.xs : RpgSpacing.sm),
          ),
          Text(
            value,
            style: prominentValue
                ? TextStyle(
                    fontSize: isCompact ? 19 : 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black87,
                  )
                : (isCompact
                          ? RpgTextStyles.titleMedium
                          : RpgTextStyles.headlineMedium)
                      .copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: prominentValue ? 1 : 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: prominentValue ? 10.5 : (isCompact ? 10 : 12),
              fontWeight: prominentValue ? FontWeight.w600 : FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact horizontal hero stat chip as seen on the Cozy RPG Home HUD
/// (e.g. "12 Day Streak", "8 Badges", "4,320 Total XP").
class CozyStatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const CozyStatChip({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F3F) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF263359) : RpgColors.rpgBorderLight,
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : RpgColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      chip = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: chip,
      );
    }

    return chip;
  }
}
