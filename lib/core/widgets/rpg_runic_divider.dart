import 'package:flutter/material.dart';
import '../theme/rpg_colors.dart';

/// Subtle fantasy horizontal divider with a centered diamond gemstone pip.
class RpgRunicDivider extends StatelessWidget {
  final Color? color;
  final Color? pipColor;
  final double height;
  final double indent;
  final double endIndent;

  const RpgRunicDivider({
    super.key,
    this.color,
    this.pipColor,
    this.height = 24.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveLineColor =
        color ?? (isDark ? RpgColors.rpgBorderDark : RpgColors.rpgBorderLight);
    final effectivePipColor =
        pipColor ?? (isDark ? RpgColors.rpgVioletLight : RpgColors.rpgIndigo);

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.only(left: indent, right: endIndent),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      effectiveLineColor.withValues(alpha: 0.0),
                      effectiveLineColor,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Transform.rotate(
                angle: 0.785398, // 45 degrees diamond
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: effectivePipColor,
                    borderRadius: BorderRadius.circular(1.0),
                    boxShadow: [
                      BoxShadow(
                        color: effectivePipColor.withValues(
                          alpha: isDark ? 0.4 : 0.2,
                        ),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      effectiveLineColor,
                      effectiveLineColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
