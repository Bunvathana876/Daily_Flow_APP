import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/rpg_colors.dart';
import '../../../../core/theme/rpg_spacing.dart';
import '../controllers/focus_timer_controller.dart';

/// Cozy Adventure RPG Arcane Countdown Ring.
/// Features a large circular countdown, mode-specific color palette:
/// - Focus Trial: muted violet and warm gold
/// - Short Rest: soft emerald
/// - Deep Rest: celestial cyan
/// High-contrast digital time display and actual XP reward preview.
class ArcaneTimerRing extends StatelessWidget {
  final Duration remainingDuration;
  final Duration totalDuration;
  final double progressRatio;
  final bool isRunning;
  final bool isPaused;
  final FocusMode mode;
  final Color activeColor;
  final String? habitTitle;
  final int presetMinutes;

  const ArcaneTimerRing({
    super.key,
    required this.remainingDuration,
    required this.totalDuration,
    required this.progressRatio,
    required this.isRunning,
    required this.isPaused,
    required this.mode,
    required this.activeColor,
    this.habitTitle,
    required this.presetMinutes,
  });

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final clampedRatio = progressRatio.clamp(0.0, 1.0);

    // Color Palette per Mode:
    // Focus Trial: Muted violet & warm gold
    // Short Rest: Soft emerald
    // Deep Rest: Celestial cyan
    final Color progressColor;
    final Color accentColor;

    switch (mode) {
      case FocusMode.focus:
        progressColor = const Color(0xFF8B5CF6); // Muted violet
        accentColor = RpgColors.warmGold; // Warm gold
        break;
      case FocusMode.shortBreak:
        progressColor = const Color(0xFF2EBF7E); // Soft emerald
        accentColor = const Color(0xFF2EBF7E);
        break;
      case FocusMode.longBreak:
        progressColor = const Color(0xFF38BDF8); // Celestial cyan
        accentColor = const Color(0xFF38BDF8);
        break;
    }

    return Center(
      child: SizedBox(
        width: 256,
        height: 256,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Atmosphere Glow (Soft, non-distracting)
            if (isRunning && !disableAnimations)
              Container(
                width: 232,
                height: 232,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: progressColor.withValues(
                        alpha: isDark ? 0.22 : 0.12,
                      ),
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

            // High-Contrast Concentric Inner Disc for Maximum Readability
            Container(
              width: 202,
              height: 202,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? const Color(0xFF0F1528) : Colors.white)
                        .withValues(alpha: isDark ? 0.88 : 0.92),
                    (isDark ? const Color(0xFF182042) : Colors.white)
                        .withValues(alpha: isDark ? 0.72 : 0.80),
                  ],
                ),
                border: Border.all(
                  color:
                      (mode == FocusMode.focus
                              ? RpgColors.warmGold
                              : accentColor)
                          .withValues(alpha: isDark ? 0.25 : 0.18),
                  width: 1.0,
                ),
              ),
            ),

            // Custom Painted Arcane Double-Ring with Markers
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: clampedRatio, end: clampedRatio),
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, animatedRatio, _) {
                return CustomPaint(
                  size: const Size(256, 256),
                  painter: _CozyArcaneRingPainter(
                    progressRatio: animatedRatio,
                    progressColor: progressColor,
                    accentColor: accentColor,
                    isDark: isDark,
                    isRunning: isRunning,
                    mode: mode,
                  ),
                );
              },
            ),

            // Center Display Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Digital Countdown
                  Text(
                    _formatTime(remainingDuration),
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white : const Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Mode / Channeling Status Pill
                  if (mode == FocusMode.focus) ...[
                    // XP Channel Preview Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: RpgColors.warmGold.withValues(
                          alpha: isDark ? 0.20 : 0.15,
                        ),
                        borderRadius: RpgSpacing.roundedPill,
                        border: Border.all(
                          color: RpgColors.warmGold.withValues(
                            alpha: isDark ? 0.60 : 0.45,
                          ),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 12,
                            color: isDark
                                ? RpgColors.rpgGoldGlint
                                : const Color(0xFF92400E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+$presetMinutes XP Channel',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? RpgColors.rpgGoldGlint
                                  : const Color(0xFF92400E),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      habitTitle != null
                          ? (isRunning
                                ? 'Channeling: $habitTitle'
                                : isPaused
                                ? 'Paused: $habitTitle'
                                : 'Empowers: $habitTitle')
                          : 'General Focus Trial',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ] else ...[
                    // Rest Mode Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: progressColor.withValues(
                          alpha: isDark ? 0.20 : 0.15,
                        ),
                        borderRadius: RpgSpacing.roundedPill,
                        border: Border.all(
                          color: progressColor.withValues(
                            alpha: isDark ? 0.60 : 0.45,
                          ),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            mode == FocusMode.shortBreak
                                ? Icons.coffee_rounded
                                : Icons.spa_rounded,
                            size: 12,
                            color: progressColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mode == FocusMode.shortBreak
                                ? 'Short Rest'
                                : 'Deep Rest',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: progressColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Restoring mana & focus...',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the Cozy Adventure RPG Arcane Timer Ring
class _CozyArcaneRingPainter extends CustomPainter {
  final double progressRatio;
  final Color progressColor;
  final Color accentColor;
  final bool isDark;
  final bool isRunning;
  final FocusMode mode;

  _CozyArcaneRingPainter({
    required this.progressRatio,
    required this.progressColor,
    required this.accentColor,
    required this.isDark,
    required this.isRunning,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 14;
    const strokeWidth = 9.0;

    // 1. Concentric Outer Accent Ring
    final outerAccentPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.28 : 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, outerRadius + 6, outerAccentPaint);

    // 2. Background Track Ring
    final trackColor = isDark
        ? (mode == FocusMode.focus
              ? const Color(0xFF231C44) // Muted violet track
              : (mode == FocusMode.shortBreak
                    ? const Color(0xFF132A24) // Soft emerald track
                    : const Color(0xFF13283B))) // Celestial cyan track
        : const Color(0xFFEAE7F4);

    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, outerRadius, trackPaint);

    // 3. Active Progress Arc
    if (progressRatio > 0.0) {
      final sweepAngle = 2 * math.pi * progressRatio;
      const startAngle = -math.pi / 2;

      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );

      // Glowing Head Bead on Progress Edge
      if (isRunning) {
        final headAngle = startAngle + sweepAngle;
        final headOffset = Offset(
          center.dx + outerRadius * math.cos(headAngle),
          center.dy + outerRadius * math.sin(headAngle),
        );

        // Soft outer glow halo
        final haloPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.40)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(headOffset, strokeWidth * 0.75, haloPaint);

        // Bright white/accent inner pip
        final headPipPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(headOffset, strokeWidth * 0.35, headPipPaint);
      }
    }

    // 4. 12 Progress & Rune Markers
    const int totalMarkers = 12;
    for (int i = 0; i < totalMarkers; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * (i / totalMarkers));
      final markerRadius = outerRadius;
      final markerOffset = Offset(
        center.dx + markerRadius * math.cos(angle),
        center.dy + markerRadius * math.sin(angle),
      );

      final isCardinal = i % 3 == 0; // 12, 3, 6, 9 o'clock
      final markerProgress = i / totalMarkers;
      final isActivated = progressRatio >= markerProgress;

      final markerColor = isActivated
          ? (isDark ? RpgColors.rpgGoldBright : accentColor)
          : (isDark
                ? accentColor.withValues(alpha: 0.35)
                : Colors.grey.shade400);

      final markerPaint = Paint()
        ..color = markerColor
        ..style = PaintingStyle.fill;

      if (i == 0) {
        // 12 o'clock Golden Fleur-de-lis Motif
        _drawFleurDeLis(canvas, markerOffset, markerColor);
      } else if (isCardinal) {
        // 3, 6, 9 o'clock: Crisp Diamond Rune Pip
        final pipPath = Path()
          ..moveTo(markerOffset.dx, markerOffset.dy - 3.2)
          ..lineTo(markerOffset.dx + 3.2, markerOffset.dy)
          ..lineTo(markerOffset.dx, markerOffset.dy + 3.2)
          ..lineTo(markerOffset.dx - 3.2, markerOffset.dy)
          ..close();
        canvas.drawPath(pipPath, markerPaint);
      } else {
        // Small Circular Bead Tick
        canvas.drawCircle(markerOffset, 1.8, markerPaint);
      }
    }
  }

  /// Draws a delicate golden triple-leaf / fleur-de-lis ornament at the 12 o'clock apex
  void _drawFleurDeLis(Canvas canvas, Offset offset, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Center leaf
    final centerLeaf = Path()
      ..moveTo(offset.dx, offset.dy - 5.5)
      ..cubicTo(
        offset.dx + 2.0,
        offset.dy - 3.0,
        offset.dx + 1.8,
        offset.dy,
        offset.dx,
        offset.dy + 1.5,
      )
      ..cubicTo(
        offset.dx - 1.8,
        offset.dy,
        offset.dx - 2.0,
        offset.dy - 3.0,
        offset.dx,
        offset.dy - 5.5,
      )
      ..close();
    canvas.drawPath(centerLeaf, paint);

    // Left petal
    final leftPetal = Path()
      ..moveTo(offset.dx, offset.dy)
      ..cubicTo(
        offset.dx - 3.5,
        offset.dy - 2.5,
        offset.dx - 4.5,
        offset.dy - 0.5,
        offset.dx - 2.5,
        offset.dy + 1.0,
      )
      ..close();
    canvas.drawPath(leftPetal, paint);

    // Right petal
    final rightPetal = Path()
      ..moveTo(offset.dx, offset.dy)
      ..cubicTo(
        offset.dx + 3.5,
        offset.dy - 2.5,
        offset.dx + 4.5,
        offset.dy - 0.5,
        offset.dx + 2.5,
        offset.dy + 1.0,
      )
      ..close();
    canvas.drawPath(rightPetal, paint);
  }

  @override
  bool shouldRepaint(covariant _CozyArcaneRingPainter oldDelegate) {
    return oldDelegate.progressRatio != progressRatio ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.mode != mode;
  }
}
