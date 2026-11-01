import 'package:flutter/material.dart';
import '../theme/rpg_colors.dart';
import '../theme/rpg_spacing.dart';

/// Decorative fantasy frame container with corner brackets, subtle glow,
/// and layered surface depth for hero headers, quest boards, and achievement panels.
class RpgDecorativeFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? accentColor;
  final Gradient? gradient;
  final double borderRadius;
  final bool hasGlow;
  final bool showCornerBrackets;

  const RpgDecorativeFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(RpgSpacing.lg),
    this.margin,
    this.backgroundColor,
    this.accentColor,
    this.gradient,
    this.borderRadius = RpgSpacing.radiusCard,
    this.hasGlow = true,
    this.showCornerBrackets = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveAccent =
        accentColor ?? (isDark ? RpgColors.rpgViolet : RpgColors.rpgIndigo);
    final effectiveBg =
        backgroundColor ??
        (isDark ? RpgColors.rpgSurfaceDark : RpgColors.rpgSurfaceLight);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? effectiveBg : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveAccent.withValues(alpha: isDark ? 0.35 : 0.20),
          width: 1.2,
        ),
        boxShadow: [
          if (hasGlow)
            BoxShadow(
              color: effectiveAccent.withValues(alpha: isDark ? 0.18 : 0.08),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Inner content
            Padding(padding: padding ?? EdgeInsets.zero, child: child),

            // Corner Brackets
            if (showCornerBrackets) ...[
              Positioned(
                top: 0,
                left: 0,
                child: CustomPaint(
                  size: const Size(20, 20),
                  painter: _CornerBracketPainter(
                    color: effectiveAccent,
                    isTop: true,
                    isLeft: true,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: CustomPaint(
                  size: const Size(20, 20),
                  painter: _CornerBracketPainter(
                    color: effectiveAccent,
                    isTop: true,
                    isLeft: false,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: CustomPaint(
                  size: const Size(20, 20),
                  painter: _CornerBracketPainter(
                    color: effectiveAccent,
                    isTop: false,
                    isLeft: true,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CustomPaint(
                  size: const Size(20, 20),
                  painter: _CornerBracketPainter(
                    color: effectiveAccent,
                    isTop: false,
                    isLeft: false,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Painter for delicate fantasy corner brackets
class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final bool isTop;
  final bool isLeft;

  _CornerBracketPainter({
    required this.color,
    required this.isTop,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    final startX = isLeft ? 5.0 : w - 5.0;
    final startY = isTop ? 14.0 : h - 14.0;
    final cornerX = isLeft ? 5.0 : w - 5.0;
    final cornerY = isTop ? 5.0 : h - 5.0;
    final endX = isLeft ? 14.0 : w - 14.0;
    final endY = isTop ? 5.0 : h - 5.0;

    path.moveTo(startX, startY);
    path.lineTo(cornerX, cornerY);
    path.lineTo(endX, endY);

    canvas.drawPath(path, paint);

    // Mini diamond tip at corner
    final pipPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cornerX, cornerY), 1.5, pipPaint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isTop != isTop ||
        oldDelegate.isLeft != isLeft;
  }
}
