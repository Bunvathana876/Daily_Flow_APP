import 'package:flutter/material.dart';
import '../theme/rpg_colors.dart';
import '../theme/rpg_spacing.dart';

/// Compact fantasy RPG Level Badge displaying current player level with a gold crown crest.
class LevelBadge extends StatelessWidget {
  final int level;
  final String? rankTitle;
  final bool compact;

  const LevelBadge({
    super.key,
    required this.level,
    this.rankTitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? RpgSpacing.sm : RpgSpacing.md,
        vertical: compact ? 3.5 : 5.5,
      ),
      decoration: BoxDecoration(
        gradient: RpgColors.goldBevelGradient,
        borderRadius: RpgSpacing.roundedPill,
        border: Border.all(
          color: RpgColors.rpgGoldGlint.withValues(alpha: 0.6),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: RpgColors.rpgGold.withValues(alpha: isDark ? 0.40 : 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: compact ? 13 : 16,
            color: const Color(0xFF451A03), // Deep bronze contrast against gold
          ),
          const SizedBox(width: 4),
          Text(
            'Lv. $level',
            style: TextStyle(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF451A03),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (rankTitle == null) return badge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: RpgSpacing.sm),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 2.5 : 3.5,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x551A2447) : Colors.grey.shade100,
            borderRadius: RpgSpacing.roundedPill,
            border: Border.all(
              color: isDark
                  ? RpgColors.warmGold.withValues(alpha: 0.35)
                  : RpgColors.rpgBorderLight,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                size: 12,
                color: RpgColors.warmGold,
              ),
              const SizedBox(width: 4),
              Text(
                rankTitle!,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
