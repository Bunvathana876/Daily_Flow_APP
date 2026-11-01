import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/rpg_colors.dart';
import '../../../../core/theme/rpg_spacing.dart';
import '../controllers/focus_timer_controller.dart';

/// Glowing Arcane Countdown Ring displaying double-ring circular progress,
/// decorative rune markers, glowing progress stroke, countdown timer,
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

    final glowColor = mode == FocusMode.focus
        ? activeColor
        : (mode == FocusMode.shortBreak
              ? RpgColors.questEmerald
              : RpgColors.rpgCyan);

    return Center(
      child: SizedBox(
        width: 250,
        height: 250,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Ambient Arcane Glow when running
            if (isRunning && !disableAnimations)
              Container(
                width: 246,
                height: 246,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: isDark ? 0.30 : 0.18),
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

            // Custom Painted Arcane Double-Ring with Rune / Gemstone Markers
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: clampedRatio, end: clampedRatio),
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, animatedRatio, _) {
                return CustomPaint(
                  size: const Size(250, 250),
                  painter: _ArcaneRingPainter(
                    progressRatio: animatedRatio,
                    activeColor: glowColor,
                    isDark: isDark,
                    isRunning: isRunning,
                  ),
                );
              },
            ),

            // Inner Ring Concentric Accent Frame
            Container(
              width: 196,
              height: 196,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1.2,
                ),
              ),
            ),

            // Center Display Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Digital Countdown
                  Text(
                    _formatTime(remainingDuration),
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Mode / Channeling Status Pill
                  if (mode == FocusMode.focus) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: glowColor.withValues(
                          alpha: isDark ? 0.18 : 0.12,
                        ),
                        borderRadius: RpgSpacing.roundedPill,
                        border: Border.all(
                          color: glowColor.withValues(
                            alpha: isDark ? 0.40 : 0.25,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 11,
                            color: glowColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+$presetMinutes XP Channel',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: glowColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
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
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: glowColor.withValues(
                          alpha: isDark ? 0.18 : 0.12,
                        ),
                        borderRadius: RpgSpacing.roundedPill,
                        border: Border.all(
                          color: glowColor.withValues(
                            alpha: isDark ? 0.40 : 0.25,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.spa_rounded, size: 11, color: glowColor),
                          const SizedBox(width: 4),
                          Text(
                            mode == FocusMode.shortBreak
                                ? 'Short Rest'
                                : 'Deep Rest',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: glowColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
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

/// Custom painter for the double-ring arcane progress ring and celestial rune ticks
class _ArcaneRingPainter extends CustomPainter {
  final double progressRatio;
  final Color activeColor;
  final bool isDark;
  final bool isRunning;

  _ArcaneRingPainter({
    required this.progressRatio,
    required this.activeColor,
    required this.isDark,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 12;
    const strokeWidth = 10.0;

    // 1. Background Track Ring
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF192033) : Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, outerRadius, trackPaint);

    // 2. Active Progress Arc
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

      // Glowing head marker
      if (isRunning) {
        final headAngle = startAngle + sweepAngle;
        final headOffset = Offset(
          center.dx + outerRadius * math.cos(headAngle),
          center.dy + outerRadius * math.sin(headAngle),
        );
        final glowHeadPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(headOffset, strokeWidth / 2.8, glowHeadPaint);
      }
    }

    // 3. 12 Cardinal and Celestial Rune / Gemstone Markers
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

      final markerPaint = Paint()
        ..color = isActivated
            ? Colors.white.withValues(alpha: 0.9)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.20)
                  : Colors.grey.shade400)
        ..style = PaintingStyle.fill;

      if (isCardinal) {
        // Diamond rune pip
        final pipPath = Path()
          ..moveTo(markerOffset.dx, markerOffset.dy - 3.5)
          ..lineTo(markerOffset.dx + 3.5, markerOffset.dy)
          ..lineTo(markerOffset.dx, markerOffset.dy + 3.5)
          ..lineTo(markerOffset.dx - 3.5, markerOffset.dy)
          ..close();
        canvas.drawPath(pipPath, markerPaint);
      } else {
        // Small circle tick
        canvas.drawCircle(markerOffset, 1.8, markerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArcaneRingPainter oldDelegate) {
    return oldDelegate.progressRatio != progressRatio ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isRunning != isRunning;
  }
}
