import 'package:flutter/material.dart';
import '../../../../core/theme/rpg_colors.dart';
import '../../../../core/theme/rpg_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../models/habit.dart';

/// Premium Daily Quest Board / Bounty Journal Docket.
///
/// Features "Today's Quests" headline, quest completion ratio, animated progress bar,
/// daily completion milestone, 7-day consistency metric, and clean responsive layout.
class DailyBountyCard extends StatelessWidget {
  final List<Habit> habits;

  const DailyBountyCard({super.key, required this.habits});

  double _calculateWeeklyCompletionRate() {
    if (habits.isEmpty) return 0.0;
    final last7Days = AppDateUtils.getLast7DaysStrings();
    int completedCount = 0;
    final int totalPossible = habits.length * 7;

    for (final dateStr in last7Days) {
      for (final habit in habits) {
        if (habit.completedDates.contains(dateStr)) {
          completedCount++;
        }
      }
    }
    return completedCount / totalPossible;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final totalQuests = habits.length;
    final completedToday = habits.where((h) => h.isCompletedToday).length;
    final isCleanSheet = totalQuests > 0 && completedToday == totalQuests;
    final remainingQuests = totalQuests - completedToday;
    final todayProgress = totalQuests > 0
        ? (completedToday / totalQuests).clamp(0.0, 1.0)
        : 0.0;

    final weeklyRate = _calculateWeeklyCompletionRate();
    final weeklyPercentage = (weeklyRate * 100).round();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? (isCleanSheet
                    ? const [
                        Color(0xFF1B2A4A),
                        Color(0xFF13362B),
                        Color(0xFF0F261E),
                      ]
                    : const [
                        Color(0xFF1B2042),
                        Color(0xFF161B36),
                        Color(0xFF101428),
                      ])
              : (isCleanSheet
                    ? const [
                        Color(0xFF3730A3),
                        Color(0xFF065F46),
                        Color(0xFF047857),
                      ]
                    : const [
                        Color(0xFF4338CA),
                        Color(0xFF4F46E5),
                        Color(0xFF6366F1),
                      ]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(RpgSpacing.radiusCard),
        border: Border.all(
          color: isCleanSheet
              ? RpgColors.rpgGold.withValues(alpha: 0.80)
              : (isDark
                    ? RpgColors.arcaneViolet.withValues(alpha: 0.38)
                    : Colors.white.withValues(alpha: 0.28)),
          width: isCleanSheet ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCleanSheet
                ? RpgColors.rpgGold.withValues(alpha: isDark ? 0.28 : 0.20)
                : const Color(0xFF4F46E5).withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RpgSpacing.radiusCard),
        child: Stack(
          children: [
            // Subtle parchment / docket corner accents
            Positioned(
              top: 0,
              left: 0,
              child: CustomPaint(
                size: const Size(14, 14),
                painter: _BountyCornerPainter(
                  color: isCleanSheet
                      ? RpgColors.rpgGold
                      : (isDark ? RpgColors.arcaneVioletLight : Colors.white70),
                  isTop: true,
                  isLeft: true,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(14, 14),
                painter: _BountyCornerPainter(
                  color: isCleanSheet
                      ? RpgColors.rpgGold
                      : (isDark ? RpgColors.arcaneVioletLight : Colors.white70),
                  isTop: true,
                  isLeft: false,
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Wrap: "Today's Quests" Title + DAILY BOUNTY Status Pill (Responsive on 320px)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Title Row with open grimoire icon
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCleanSheet
                                ? Icons.military_tech_rounded
                                : Icons.auto_stories_rounded,
                            color: isCleanSheet
                                ? RpgColors.rpgGold
                                : Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Today's Quests",
                            style: TextStyle(
                              color: isCleanSheet
                                  ? RpgColors.rpgGold
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),

                      // DAILY BOUNTY Milestone & Completed / Total Quests
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isCleanSheet
                                  ? RpgColors.rpgGold.withValues(alpha: 0.22)
                                  : Colors.white.withValues(alpha: 0.14),
                              borderRadius: RpgSpacing.roundedPill,
                              border: Border.all(
                                color: isCleanSheet
                                    ? RpgColors.rpgGold.withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'DAILY BOUNTY',
                              style: TextStyle(
                                color: isCleanSheet
                                    ? RpgColors.rpgGoldBright
                                    : Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isCleanSheet
                                  ? RpgColors.rpgEmerald.withValues(alpha: 0.30)
                                  : Colors.white.withValues(alpha: 0.16),
                              borderRadius: RpgSpacing.roundedPill,
                              border: Border.all(
                                color: isCleanSheet
                                    ? RpgColors.rpgEmerald.withValues(
                                        alpha: 0.6,
                                      )
                                    : Colors.white.withValues(alpha: 0.2),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              totalQuests == 0
                                  ? 'No Quests'
                                  : '$completedToday / $totalQuests Done',
                              style: TextStyle(
                                color: isCleanSheet
                                    ? RpgColors.rpgGoldBright
                                    : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  // Daily Quest Progress Bar with channeled trough
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.35 : 0.18,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 0.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: todayProgress),
                        duration: disableAnimations
                            ? Duration.zero
                            : const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: isCleanSheet
                                    ? RpgColors.emeraldGradient
                                    : RpgColors.xpProgressGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: isCleanSheet
                                        ? RpgColors.rpgEmerald
                                        : RpgColors.rpgCyan,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),

                  // Milestone & 7-Day Rate Wrap for 320px Responsiveness
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Milestone / Status
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            totalQuests == 0
                                ? Icons.shield_outlined
                                : (isCleanSheet
                                      ? Icons.auto_awesome_rounded
                                      : Icons.flag_circle_rounded),
                            size: 13,
                            color: isCleanSheet
                                ? RpgColors.rpgGoldBright
                                : Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            totalQuests == 0
                                ? 'No quests'
                                : (isCleanSheet
                                      ? 'Clean Sheet (+50 XP)'
                                      : '$remainingQuests left for bounty'),
                            style: TextStyle(
                              color: isCleanSheet
                                  ? RpgColors.rpgGoldBright
                                  : Colors.white.withValues(alpha: 0.88),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // 7-Day Completion Rate (Preserves analytics & tests)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '7-Day Completion Rate',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.80),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$weeklyPercentage%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle corner accent painter for daily bounty card
class _BountyCornerPainter extends CustomPainter {
  final Color color;
  final bool isTop;
  final bool isLeft;

  _BountyCornerPainter({
    required this.color,
    required this.isTop,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path();

    final cornerX = isLeft ? 2.5 : w - 2.5;
    final cornerY = isTop ? 2.5 : h - 2.5;
    final lineEndX = isLeft ? 8.0 : w - 8.0;
    final lineEndY = isTop ? 8.0 : h - 8.0;

    path.moveTo(cornerX, lineEndY);
    path.lineTo(cornerX, cornerY);
    path.lineTo(lineEndX, cornerY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BountyCornerPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isTop != isTop ||
      oldDelegate.isLeft != isLeft;
}
