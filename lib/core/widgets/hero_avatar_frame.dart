import 'package:flutter/material.dart';
import '../theme/rpg_colors.dart';

/// Ornate Cozy Adventure RPG Hero Avatar Frame.
/// Features a circular golden metallic bevel, delicate lower wings/laurel flourish,
/// and integrated support for avatar images or fallback role crests.
class HeroAvatarFrame extends StatelessWidget {
  final double size;
  final String? imageAsset;
  final ImageProvider? imageProvider;
  final Widget? child;
  final IconData? fallbackIcon;
  final int? level;
  final VoidCallback? onTap;
  final bool showFlourish;
  final bool showEditBadge;

  const HeroAvatarFrame({
    super.key,
    this.size = 76.0,
    this.imageAsset,
    this.imageProvider,
    this.child,
    this.fallbackIcon = Icons.person_rounded,
    this.level,
    this.onTap,
    this.showFlourish = true,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalWidth = size * (showFlourish ? 1.25 : 1.0);
    final totalHeight = size * (showFlourish ? 1.15 : 1.0);

    Widget buildFallback() {
      return Container(
        width: size * 0.88,
        height: size * 0.88,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF322359), Color(0xFF1E284E)],
          ),
        ),
        child: Center(
          child: Icon(
            fallbackIcon ?? Icons.person_rounded,
            size: size * 0.48,
            color: RpgColors.warmGold,
          ),
        ),
      );
    }

    Widget avatarCore;
    if (child != null) {
      avatarCore = child!;
    } else if (imageAsset != null) {
      avatarCore = SizedBox(
        width: size * 0.88,
        height: size * 0.88,
        child: ClipOval(
          child: Image.asset(
            imageAsset!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => buildFallback(),
          ),
        ),
      );
    } else if (imageProvider != null) {
      avatarCore = SizedBox(
        width: size * 0.88,
        height: size * 0.88,
        child: ClipOval(
          child: Image(
            image: imageProvider!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => buildFallback(),
          ),
        ),
      );
    } else {
      avatarCore = buildFallback();
    }

    Widget framedAvatar = SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Lower wings / laurel flourish ornament
          if (showFlourish)
            Positioned(
              bottom: 0,
              child: CustomPaint(
                size: Size(size * 1.24, size * 0.45),
                painter: _AvatarFlourishPainter(isDark: isDark),
              ),
            ),

          // Outer golden bevel rim
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RpgColors.goldBevelGradient,
              boxShadow: [
                BoxShadow(
                  color: RpgColors.warmGold.withValues(
                    alpha: isDark ? 0.35 : 0.20,
                  ),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.04),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(size * 0.045),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: RpgColors.softIndigo,
              ),
              padding: EdgeInsets.all(size * 0.025),
              child: ClipOval(child: avatarCore),
            ),
          ),

          // Integrated Level Tag or Edit Badge
          if (level != null && !showFlourish)
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: RpgColors.goldBevelGradient,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white70, width: 0.8),
                ),
                child: Text(
                  'Lv. $level',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF381B03),
                  ),
                ),
              ),
            ),

          if (showEditBadge)
            Positioned(
              right: (totalWidth - size) / 2,
              bottom: (totalHeight - size) / 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: RpgColors.warmGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: RpgColors.softIndigo, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 4),
                  ],
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 11,
                  color: Color(0xFF2E1500),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      framedAvatar = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: framedAvatar,
      );
    }

    return framedAvatar;
  }
}

/// Custom painter for the ornate golden wings & leaves flanking the frame base
class _AvatarFlourishPainter extends CustomPainter {
  final bool isDark;

  _AvatarFlourishPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final goldPaint = Paint()
      ..shader = RpgColors.goldBevelGradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Left wing/leaf sweep
    final leftPath = Path()
      ..moveTo(w * 0.42, h * 0.55)
      ..cubicTo(w * 0.30, h * 0.65, w * 0.16, h * 0.48, w * 0.05, h * 0.20)
      ..cubicTo(w * 0.10, h * 0.40, w * 0.22, h * 0.70, w * 0.38, h * 0.78)
      ..cubicTo(w * 0.26, h * 0.85, w * 0.12, h * 0.75, w * 0.08, h * 0.55)
      ..cubicTo(w * 0.18, h * 0.82, w * 0.35, h * 0.95, w * 0.48, h * 0.85)
      ..close();

    // Right wing/leaf sweep
    final rightPath = Path()
      ..moveTo(w * 0.58, h * 0.55)
      ..cubicTo(w * 0.70, h * 0.65, w * 0.84, h * 0.48, w * 0.95, h * 0.20)
      ..cubicTo(w * 0.90, h * 0.40, w * 0.78, h * 0.70, w * 0.62, h * 0.78)
      ..cubicTo(w * 0.74, h * 0.85, w * 0.88, h * 0.75, w * 0.92, h * 0.55)
      ..cubicTo(w * 0.82, h * 0.82, w * 0.65, h * 0.95, w * 0.52, h * 0.85)
      ..close();

    // Center bottom leaf / ribbon clasp
    final centerClasp = Path()
      ..moveTo(w * 0.46, h * 0.78)
      ..lineTo(w * 0.50, h * 0.98)
      ..lineTo(w * 0.54, h * 0.78)
      ..close();

    canvas.drawPath(leftPath, goldPaint);
    canvas.drawPath(rightPath, goldPaint);
    canvas.drawPath(centerClasp, goldPaint);

    canvas.drawPath(leftPath, shadowPaint);
    canvas.drawPath(rightPath, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant _AvatarFlourishPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
