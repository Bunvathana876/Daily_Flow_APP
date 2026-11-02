import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/rpg_colors.dart';
import '../theme/rpg_spacing.dart';
import '../theme/rpg_text_styles.dart';

/// Style variants for Cozy Adventure RPG Buttons
enum CozyButtonVariant { primary, secondary, pill, ghost }

/// Cozy Adventure RPG Button with warm amber/gold surfaces,
/// tactile response, gentle ambient lighting, and accessibility compliance.
class CozyButton extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final CozyButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? customColor;
  final Color? customTextColor;
  final bool enableHaptics;

  const CozyButton({
    super.key,
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.onPressed,
    this.variant = CozyButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = RpgSpacing.minTouchTarget,
    this.borderRadius,
    this.customColor,
    this.customTextColor,
    this.enableHaptics = true,
  });

  /// Primary Warm Gold CTA button (matches "+ New Quest" & "Start Focus")
  factory CozyButton.primary({
    Key? key,
    required String label,
    IconData? leadingIcon,
    IconData? trailingIcon,
    VoidCallback? onPressed,
    bool isLoading = false,
    double? width,
    double height = RpgSpacing.minTouchTarget,
    BorderRadius? borderRadius,
  }) => CozyButton(
    key: key,
    label: label,
    leadingIcon: leadingIcon,
    trailingIcon: trailingIcon,
    onPressed: onPressed,
    variant: CozyButtonVariant.primary,
    isLoading: isLoading,
    width: width,
    height: height,
    borderRadius: borderRadius ?? BorderRadius.circular(24.0),
  );

  /// Secondary Soft Indigo button with subtle border
  factory CozyButton.secondary({
    Key? key,
    required String label,
    IconData? leadingIcon,
    IconData? trailingIcon,
    VoidCallback? onPressed,
    bool isLoading = false,
    double? width,
    double height = RpgSpacing.minTouchTarget,
    BorderRadius? borderRadius,
  }) => CozyButton(
    key: key,
    label: label,
    leadingIcon: leadingIcon,
    trailingIcon: trailingIcon,
    onPressed: onPressed,
    variant: CozyButtonVariant.secondary,
    isLoading: isLoading,
    width: width,
    height: height,
    borderRadius: borderRadius ?? BorderRadius.circular(20.0),
  );

  /// Compact toggle pill button (e.g. Focus Time / Rest Time)
  factory CozyButton.pill({
    Key? key,
    required String label,
    IconData? leadingIcon,
    VoidCallback? onPressed,
    bool isSelected = false,
    double height = 36.0,
  }) => CozyButton(
    key: key,
    label: label,
    leadingIcon: leadingIcon,
    onPressed: onPressed,
    variant: isSelected ? CozyButtonVariant.primary : CozyButtonVariant.ghost,
    height: height,
    borderRadius: BorderRadius.circular(RpgSpacing.radiusPill),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = onPressed != null && !isLoading;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(22.0);

    Gradient? bgGradient;
    Color? bgColor;
    Color textColor;
    Color? borderColor;
    List<BoxShadow> shadows = [];

    switch (variant) {
      case CozyButtonVariant.primary:
        if (isEnabled) {
          bgGradient = RpgColors.cozyGoldGradient;
          textColor = customTextColor ?? const Color(0xFF2B1602);
          borderColor = isDark
              ? RpgColors.rpgGoldGlint.withValues(alpha: 0.35)
              : RpgColors.warmGold.withValues(alpha: 0.45);
          shadows = [
            BoxShadow(
              color: RpgColors.warmGold.withValues(alpha: isDark ? 0.20 : 0.14),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ];
        } else {
          bgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
          textColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
        }
        break;

      case CozyButtonVariant.secondary:
        if (isEnabled) {
          bgColor = isDark ? RpgColors.softIndigo : Colors.white;
          textColor =
              customTextColor ??
              (isDark ? Colors.white : RpgColors.textPrimaryLight);
          borderColor = isDark
              ? RpgColors.cozyBorderDark
              : RpgColors.rpgBorderLight;
          shadows = [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];
        } else {
          bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade200;
          textColor = Colors.grey.shade500;
          borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
        }
        break;

      case CozyButtonVariant.pill:
      case CozyButtonVariant.ghost:
        if (isEnabled) {
          bgColor = isDark ? const Color(0x331A2447) : Colors.grey.shade100;
          textColor =
              customTextColor ??
              (isDark ? Colors.grey.shade300 : Colors.grey.shade700);
          borderColor = isDark
              ? RpgColors.cozyBorderDark.withValues(alpha: 0.5)
              : Colors.transparent;
        } else {
          bgColor = Colors.transparent;
          textColor = Colors.grey.shade600;
        }
        break;
    }

    if (customColor != null && isEnabled) {
      bgColor = customColor;
      bgGradient = null;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 18, color: textColor),
          const SizedBox(width: RpgSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: RpgTextStyles.cozyButtonLabel.copyWith(
              color: textColor,
              fontSize: height < 40 ? 13 : 15,
            ),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: RpgSpacing.sm),
          Icon(trailingIcon, size: 18, color: textColor),
        ],
      ],
    );

    if (isLoading) {
      content = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: bgGradient == null ? bgColor : null,
          gradient: bgGradient,
          borderRadius: effectiveRadius,
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1.0)
              : null,
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled
                ? () {
                    if (enableHaptics) {
                      HapticFeedback.lightImpact();
                    }
                    onPressed!();
                  }
                : null,
            borderRadius: effectiveRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular or squircle cozy icon button (Reset, Settings, Close)
class CozyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;

  const CozyIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44.0,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        backgroundColor ?? (isDark ? RpgColors.softIndigo : Colors.white);
    final ic =
        iconColor ?? (isDark ? Colors.white70 : RpgColors.textPrimaryLight);

    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? RpgColors.cozyBorderDark : RpgColors.rpgBorderLight,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed != null
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          child: Center(
            child: Icon(icon, size: size * 0.48, color: ic),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
