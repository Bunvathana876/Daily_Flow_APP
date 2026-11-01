import 'package:flutter/material.dart';
import '../theme/rpg_colors.dart';
import '../theme/rpg_spacing.dart';

/// Sculpted fantasy RPG Button with minimum 48px touch target, subtle top-edge
/// highlight, delicate ambient glow, and crisp feedback.
class RpgFilledButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Gradient? gradient;
  final bool isLoading;
  final double? width;
  final double height;

  const RpgFilledButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.gradient,
    this.isLoading = false,
    this.width,
    this.height = RpgSpacing.minTouchTarget,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = backgroundColor ?? RpgColors.rpgIndigo;
    final txtColor = textColor ?? Colors.white;
    final effectiveGradient = isEnabled ? gradient : null;
    final bgColor = isEnabled
        ? (effectiveGradient == null ? baseColor : null)
        : Colors.grey.shade400;

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          gradient: effectiveGradient,
          borderRadius: RpgSpacing.roundedMedium,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: baseColor.withValues(alpha: isDark ? 0.35 : 0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: FilledButton(
          onPressed: isEnabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: effectiveGradient != null
                ? Colors.transparent
                : bgColor,
            disabledBackgroundColor: Colors.grey.shade400,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: RpgSpacing.xl),
            shape: RoundedRectangleBorder(
              borderRadius: RpgSpacing.roundedMedium,
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: txtColor),
                      const SizedBox(width: RpgSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: txtColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
