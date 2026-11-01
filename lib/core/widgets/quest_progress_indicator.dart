import 'package:flutter/material.dart';
import '../theme/rpg_colors.dart';
import '../theme/rpg_spacing.dart';

/// Compact visual indicator displaying quest progress (e.g., 3 of 5 daily quests completed).
class QuestProgressIndicator extends StatelessWidget {
  final int completedQuests;
  final int totalQuests;
  final bool isCircular;
  final double size;

  const QuestProgressIndicator({
    super.key,
    required this.completedQuests,
    required this.totalQuests,
    this.isCircular = false,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final ratio = totalQuests > 0
        ? (completedQuests / totalQuests).clamp(0.0, 1.0)
        : 0.0;
    final percentage = (ratio * 100).round();

    if (isCircular) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 3.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: ratio),
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 3.5,
                  strokeCap: StrokeCap.round,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    RpgColors.rpgEmerald,
                  ),
                );
              },
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: size * 0.28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quest Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            Text(
              '$completedQuests / $totalQuests ($percentage%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ratio >= 1.0
                    ? RpgColors.rpgEmerald
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
        const SizedBox(height: RpgSpacing.xs),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isDark ? const Color(0xFF0F1526) : Colors.grey.shade200,
            border: Border.all(
              color: isDark
                  ? RpgColors.rpgBorderDark
                  : RpgColors.rpgBorderLight,
              width: 0.8,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: ratio),
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: ratio >= 1.0
                          ? RpgColors.emeraldGradient
                          : RpgColors.xpProgressGradient,
                      boxShadow: [
                        BoxShadow(
                          color: ratio >= 1.0
                              ? RpgColors.rpgEmerald
                              : RpgColors.rpgCyan,
                          blurRadius: 4,
                        ),
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
