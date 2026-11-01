import 'package:flutter/material.dart';
import '../theme/rpg_colors.dart';
import '../theme/rpg_spacing.dart';

/// Animated fantasy XP Progress Bar with gradient filling, subtle glowing head,
/// and reduced-motion adaptation.
class XpProgressBar extends StatelessWidget {
  final int currentXp;
  final int requiredXp;
  final double progressRatio;
  final double height;
  final bool showLabels;
  final String? leadingLabel;

  const XpProgressBar({
    super.key,
    required this.currentXp,
    required this.requiredXp,
    required this.progressRatio,
    this.height = 10.0,
    this.showLabels = true,
    this.leadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final targetProgress = progressRatio.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabels) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (leadingLabel != null)
                Flexible(
                  child: Text(
                    leadingLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: RpgColors.rpgGold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '$currentXp / $requiredXp XP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: RpgSpacing.xs),
        ],
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            color: isDark ? const Color(0xFF0F1526) : Colors.grey.shade200,
            border: Border.all(
              color: isDark
                  ? RpgColors.rpgBorderDark
                  : RpgColors.rpgBorderLight,
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: targetProgress),
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RpgColors.xpProgressGradient,
                      boxShadow: [
                        BoxShadow(color: RpgColors.rpgCyan, blurRadius: 6),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
