import 'package:flutter/material.dart';
import '../theme/rpg_colors.dart';

/// Available crest silhouette shapes
enum RpgCrestShape { shield, circle, diamond, octagon }

/// Gemstone elemental tiers
enum RpgGemTier { gold, arcane, emerald, cyan, ruby }

/// Sculpted fantasy crest / medallion container for avatars, badges, and gemstone emblems.
class RpgCrest extends StatelessWidget {
  final Widget? child;
  final IconData? icon;
  final double size;
  final RpgCrestShape shape;
  final RpgGemTier tier;
  final bool hasGlow;
  final double borderWidth;
  final VoidCallback? onTap;

  const RpgCrest({
    super.key,
    this.child,
    this.icon,
    this.size = 48.0,
    this.shape = RpgCrestShape.shield,
    this.tier = RpgGemTier.gold,
    this.hasGlow = true,
    this.borderWidth = 1.8,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve tier colors and gradients
    Color primaryColor;
    Color secondaryColor;
    Color glowColor;
    LinearGradient borderGradient;
    LinearGradient fillGradient;

    switch (tier) {
      case RpgGemTier.gold:
        primaryColor = RpgColors.rpgGold;
        secondaryColor = RpgColors.rpgGoldBright;
        glowColor = RpgColors.rpgGold;
        borderGradient = RpgColors.goldBevelGradient;
        fillGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2E220D), const Color(0xFF191307)]
              : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
        );
        break;

      case RpgGemTier.arcane:
        primaryColor = RpgColors.rpgIndigo;
        secondaryColor = RpgColors.rpgViolet;
        glowColor = RpgColors.rpgViolet;
        borderGradient = RpgColors.violetGradient;
        fillGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1F1B3E), const Color(0xFF141229)]
              : [const Color(0xFFEDE9FE), const Color(0xFFDDD6FE)],
        );
        break;

      case RpgGemTier.emerald:
        primaryColor = RpgColors.rpgEmerald;
        secondaryColor = RpgColors.rpgForestJade;
        glowColor = RpgColors.rpgEmerald;
        borderGradient = RpgColors.emeraldGradient;
        fillGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F291E), const Color(0xFF0A1B14)]
              : [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
        );
        break;

      case RpgGemTier.cyan:
        primaryColor = RpgColors.rpgCyan;
        secondaryColor = RpgColors.rpgSkyCrystal;
        glowColor = RpgColors.rpgCyan;
        borderGradient = RpgColors.manaCrystalGradient;
        fillGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0E2833), const Color(0xFF0A1C24)]
              : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
        );
        break;

      case RpgGemTier.ruby:
        primaryColor = RpgColors.rpgCrimson;
        secondaryColor = RpgColors.rpgCrimsonSpark;
        glowColor = RpgColors.rpgCrimson;
        borderGradient = RpgColors.streakFlameGradient;
        fillGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF331118), const Color(0xFF220B10)]
              : [const Color(0xFFFFE4E6), const Color(0xFFFECDD3)],
        );
        break;
    }

    Widget content = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft ambient glow background
          if (hasGlow)
            Container(
              width: size * 0.85,
              height: size * 0.85,
              decoration: BoxDecoration(
                shape: shape == RpgCrestShape.circle
                    ? BoxShape.circle
                    : BoxShape.rectangle,
                borderRadius: shape == RpgCrestShape.circle
                    ? null
                    : BorderRadius.circular(size * 0.28),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: isDark ? 0.35 : 0.20),
                    blurRadius: size * 0.35,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),

          // Outer Beveled Container
          CustomPaint(
            size: Size(size, size),
            painter: _CrestPainter(
              shape: shape,
              borderGradient: borderGradient,
              fillGradient: fillGradient,
              borderWidth: borderWidth,
              isDark: isDark,
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child:
                    child ??
                    (icon != null
                        ? Icon(
                            icon,
                            size: size * 0.48,
                            color: isDark ? secondaryColor : primaryColor,
                          )
                        : null),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}

/// Custom painter for crisp silhouette borders & bevels
class _CrestPainter extends CustomPainter {
  final RpgCrestShape shape;
  final LinearGradient borderGradient;
  final LinearGradient fillGradient;
  final double borderWidth;
  final bool isDark;

  _CrestPainter({
    required this.shape,
    required this.borderGradient,
    required this.fillGradient,
    required this.borderWidth,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = _getPath(shape, size);

    // 1. Fill interior
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 2. Stroke outer border with metallic gradient
    final strokePaint = Paint()
      ..shader = borderGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // 3. Subtle inner highlight line
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.12 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, innerPaint);
  }

  Path _getPath(RpgCrestShape shape, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    switch (shape) {
      case RpgCrestShape.circle:
        path.addOval(Rect.fromLTWH(0, 0, w, h));
        break;

      case RpgCrestShape.shield:
        // Shield silhouette
        path.moveTo(w * 0.15, h * 0.08);
        path.lineTo(w * 0.85, h * 0.08);
        path.quadraticBezierTo(w, h * 0.08, w, h * 0.25);
        path.lineTo(w, h * 0.55);
        path.cubicTo(w, h * 0.82, w * 0.6, h * 0.95, w * 0.5, h);
        path.cubicTo(w * 0.4, h * 0.95, 0, h * 0.82, 0, h * 0.55);
        path.lineTo(0, h * 0.25);
        path.quadraticBezierTo(0, h * 0.08, w * 0.15, h * 0.08);
        path.close();
        break;

      case RpgCrestShape.diamond:
        // Diamond silhouette
        path.moveTo(w * 0.5, 0);
        path.lineTo(w, h * 0.5);
        path.lineTo(w * 0.5, h);
        path.lineTo(0, h * 0.5);
        path.close();
        break;

      case RpgCrestShape.octagon:
        // Beveled octagon
        final corner = w * 0.25;
        path.moveTo(corner, 0);
        path.lineTo(w - corner, 0);
        path.lineTo(w, corner);
        path.lineTo(w, h - corner);
        path.lineTo(w - corner, h);
        path.lineTo(corner, h);
        path.lineTo(0, h - corner);
        path.lineTo(0, corner);
        path.close();
        break;
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _CrestPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.isDark != isDark;
  }
}
