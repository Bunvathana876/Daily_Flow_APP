import 'package:flutter/material.dart';
import '../theme/rpg_colors.dart';
import '../theme/rpg_spacing.dart';

/// Style variants for RPG Cards
enum RpgCardVariant {
  standard,
  elevated,
  arcane,
  gold,
  emerald,
  glass,
  cozy,
  cozyBounty,
}

/// Cozy Enchanted RPG Card surface with subtle border strokes, layered depth,
/// optional glow, and fantasy corner accents.
class RpgCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double borderWidth;
  final RpgCardVariant variant;
  final bool hasGlow;
  final bool showCornerAccents;
  final bool topHighlight;

  const RpgCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(RpgSpacing.lg),
    this.margin,
    this.color,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.borderRadius,
    this.borderWidth = 1.0,
    this.variant = RpgCardVariant.standard,
    this.hasGlow = false,
    this.showCornerAccents = false,
    this.topHighlight = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderRadius = borderRadius ?? RpgSpacing.roundedCard;

    // Resolve variant-specific colors and decorations
    Color defaultBg;
    Color defaultBorder;
    List<BoxShadow> shadows = [];
    Gradient? effectiveGradient = gradient;

    switch (variant) {
      case RpgCardVariant.standard:
        defaultBg = isDark
            ? RpgColors.rpgSurfaceDark
            : RpgColors.rpgSurfaceLight;
        defaultBorder = isDark
            ? RpgColors.rpgBorderDark
            : RpgColors.rpgBorderLight;
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ];
        break;

      case RpgCardVariant.elevated:
        defaultBg = isDark
            ? RpgColors.rpgSurfaceElevated
            : RpgColors.rpgSurfaceLight;
        defaultBorder = isDark
            ? RpgColors.rpgBorderHighlight
            : RpgColors.rpgBorderLight;
        effectiveGradient ??= isDark ? RpgColors.darkCardSurfaceGradient : null;
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ];
        break;

      case RpgCardVariant.arcane:
        defaultBg = isDark
            ? RpgColors.rpgSurfaceDark
            : RpgColors.rpgSurfaceLight;
        defaultBorder = isDark
            ? RpgColors.rpgViolet.withValues(alpha: 0.6)
            : RpgColors.rpgVioletLight;
        shadows = [
          BoxShadow(
            color: RpgColors.rpgViolet.withValues(alpha: isDark ? 0.22 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];
        break;

      case RpgCardVariant.gold:
        defaultBg = isDark
            ? RpgColors.rpgSurfaceDark
            : RpgColors.rpgSurfaceLight;
        defaultBorder = isDark
            ? RpgColors.rpgGold.withValues(alpha: 0.7)
            : RpgColors.rpgGold;
        shadows = [
          BoxShadow(
            color: RpgColors.rpgGold.withValues(alpha: isDark ? 0.20 : 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];
        break;

      case RpgCardVariant.emerald:
        defaultBg = isDark
            ? RpgColors.rpgSurfaceDark
            : RpgColors.rpgSurfaceLight;
        defaultBorder = isDark
            ? RpgColors.rpgEmerald.withValues(alpha: 0.65)
            : RpgColors.rpgEmerald;
        shadows = [
          BoxShadow(
            color: RpgColors.rpgEmerald.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];
        break;

      case RpgCardVariant.glass:
        defaultBg = isDark
            ? RpgColors.rpgSurfaceGlass
            : Colors.white.withValues(alpha: 0.85);
        defaultBorder = isDark
            ? RpgColors.rpgBorderHighlight
            : RpgColors.rpgBorderLight;
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
        break;

      case RpgCardVariant.cozy:
        defaultBg = isDark ? RpgColors.softIndigo : RpgColors.rpgSurfaceLight;
        defaultBorder = isDark
            ? RpgColors.cozyBorderDark
            : RpgColors.rpgBorderLight;
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];
        break;

      case RpgCardVariant.cozyBounty:
        defaultBg = isDark ? const Color(0xFF231B42) : const Color(0xFFF3E8FF);
        defaultBorder = isDark
            ? const Color(0xFF4C3870)
            : const Color(0xFFD8B4FE);
        effectiveGradient ??= isDark
            ? RpgColors.cozyBountyGradient
            : const LinearGradient(
                colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
              );
        shadows = [
          BoxShadow(
            color: RpgColors.mutedViolet.withValues(
              alpha: isDark ? 0.20 : 0.08,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];
        break;
    }

    if (hasGlow && variant == RpgCardVariant.standard) {
      shadows.insert(
        0,
        BoxShadow(
          color: (borderColor ?? RpgColors.rpgIndigo).withValues(
            alpha: isDark ? 0.20 : 0.10,
          ),
          blurRadius: 14,
          offset: const Offset(0, 3),
        ),
      );
    }

    final effectiveColor = effectiveGradient == null
        ? (color ?? defaultBg)
        : null;
    final effectiveBorder = borderColor ?? defaultBorder;

    final decoration = BoxDecoration(
      color: effectiveColor,
      gradient: effectiveGradient,
      borderRadius: effectiveBorderRadius,
      border: Border.all(color: effectiveBorder, width: borderWidth),
      boxShadow: shadows,
    );

    Widget contentBody = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

    // Subtle inner top highlight to simulate sculpted fantasy stone / glass edge
    if (topHighlight && isDark) {
      contentBody = CustomPaint(
        painter: _TopHighlightPainter(effectiveBorderRadius, effectiveBorder),
        child: contentBody,
      );
    }

    // Optional decorative corner accents
    if (showCornerAccents) {
      contentBody = Stack(
        children: [
          contentBody,
          Positioned(
            top: 4,
            left: 4,
            child: _CornerPip(color: effectiveBorder),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: _CornerPip(color: effectiveBorder),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: _CornerPip(color: effectiveBorder),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: _CornerPip(color: effectiveBorder),
          ),
        ],
      );
    }

    Widget content = Container(
      margin: margin,
      decoration: decoration,
      child: ClipRRect(borderRadius: effectiveBorderRadius, child: contentBody),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Subtle inner top edge highlight painter
class _TopHighlightPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Color borderColor;

  _TopHighlightPainter(this.borderRadius, this.borderColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(borderRadius.topLeft.x, 1)
      ..lineTo(size.width - borderRadius.topRight.x, 1);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TopHighlightPainter oldDelegate) => false;
}

/// Miniature corner diamond pip accent
class _CornerPip extends StatelessWidget {
  final Color color;

  const _CornerPip({required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398, // 45 degrees
      child: Container(
        width: 3.5,
        height: 3.5,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(0.5),
        ),
      ),
    );
  }
}
