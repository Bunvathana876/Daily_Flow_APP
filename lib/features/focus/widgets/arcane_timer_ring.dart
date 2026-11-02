import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/rpg_colors.dart';
import '../../../../core/theme/rpg_spacing.dart';
import '../controllers/focus_timer_controller.dart';

/// Cozy Adventure RPG Arcane Countdown Ring.
/// Features a large circular countdown, soft violet progress ring,
/// warm gold progress markers, clear digital time display,
/// and actual XP reward preview.
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

    final modeColor = mode == FocusMode.focus
        ? (activeColor != Theme.of(context).colorScheme.primary
              ? activeColor
              : RpgColors.arcaneViolet)
        : (mode == FocusMode.shortBreak
              ? RpgColors.questEmerald
              : RpgColors.rpgCyan);

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
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: modeColor.withValues(alpha: isDark ? 0.20 : 0.12),
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

            // Concentric Inner Soft Disc for Readability over Background Artwork
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? RpgColors.midnightNavy : Colors.white).withValues(
                      alpha: isDark ? 0.72 : 0.85,
                    ),
                    (isDark ? RpgColors.softIndigo : Colors.white).withValues(
                      alpha: isDark ? 0.40 : 0.50,
                    ),
                  ],
                ),
                border: Border.all(
                  color: isDark
                      ? RpgColors.warmGold.withValues(alpha: 0.18)
                      : RpgColors.rpgBorderLight,
                  width: 1.0,
                ),
              ),
            ),

            // Custom Painted Arcane Double-Ring with Warm Gold Markers & Fleur-de-lis
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
                    activeColor: modeColor,
                    isDark: isDark,
                    isRunning: isRunning,
                    isFocusMode: mode == FocusMode.focus,
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
                        horizontal: 9,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: RpgColors.warmGold.withValues(
                          alpha: isDark ? 0.16 : 0.12,
                        ),
                        borderRadius: RpgSpacing.roundedPill,
                        border: Border.all(
                          color: RpgColors.warmGold.withValues(
                            alpha: isDark ? 0.45 : 0.35,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 11,
                            color: RpgColors.warmGold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+$presetMinutes XP Channel',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: RpgColors.warmGold,
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
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ] else ...[
                    // Rest Mode Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: modeColor.withValues(
                          alpha: isDark ? 0.16 : 0.12,
                        ),
                        borderRadius: RpgSpacing.roundedPill,
                        border: Border.all(
                          color: modeColor.withValues(
                            alpha: isDark ? 0.40 : 0.25,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.spa_rounded, size: 11, color: modeColor),
                          const SizedBox(width: 4),
                          Text(
                            mode == FocusMode.shortBreak
                                ? 'Short Rest'
                                : 'Deep Rest',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: modeColor,
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
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
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
  final Color activeColor;
  final bool isDark;
  final bool isRunning;
  final bool isFocusMode;

  _CozyArcaneRingPainter({
    required this.progressRatio,
    required this.activeColor,
    required this.isDark,
    required this.isRunning,
    required this.isFocusMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 14;
    const strokeWidth = 9.0;

    // 1. Concentric Outer Accent Ring
    final outerAccentPaint = Paint()
      ..color = (isDark ? RpgColors.warmGold : RpgColors.arcaneViolet)
          .withValues(alpha: isDark ? 0.22 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, outerRadius + 6, outerAccentPaint);

    // 2. Background Track Ring (Soft Violet / Indigo)
    final trackPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1E2447).withValues(alpha: 0.85)
          : const Color(0xFFE8E5F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, outerRadius, trackPaint);

    // 3. Active Progress Arc
    if (progressRatio > 0.0) {
      final sweepAngle = 2 * math.pi * progressRatio;
      const startAngle = -math.pi / 2;

      final progressPaint = Paint()
        ..color = activeColor
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
          ..color = (isFocusMode ? RpgColors.warmGold : activeColor).withValues(
            alpha: 0.40,
          )
          ..style = PaintingStyle.fill;
        canvas.drawCircle(headOffset, strokeWidth * 0.75, haloPaint);

        // Bright white/golden inner pip
        final headPipPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(headOffset, strokeWidth * 0.35, headPipPaint);
      }
    }

    // 4. 12 Warm Gold Progress & Rune Markers
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
          ? (isDark ? RpgColors.rpgGoldBright : RpgColors.warmGold)
          : (isDark
                ? RpgColors.warmGold.withValues(alpha: 0.30)
                : Colors.grey.shade400);

      final markerPaint = Paint()
        ..color = markerColor
        ..style = PaintingStyle.fill;

      if (i == 0) {
        // 12 o'clock Crown / Golden Fleur Motif
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
        oldDelegate.activeColor != activeColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.isFocusMode != isFocusMode;
  }
}
