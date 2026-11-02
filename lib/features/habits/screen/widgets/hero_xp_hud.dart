import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/rpg_colors.dart';
import '../../../../core/utils/gamification_math.dart';
import '../../../../core/widgets/compact_xp_indicator.dart';
import '../../../../core/widgets/hero_avatar_frame.dart';
import '../../../../core/widgets/level_badge.dart';
import '../../../gamification/controllers/gamification_controller.dart';
import '../../models/habit.dart';

/// Immersive Cozy Adventure RPG Hero Dashboard HUD displaying player avatar portrait,
/// level, rank, XP progression bar, active streak, and achievement indicators.
///
/// Features the canonical hero portrait artwork in an ornate golden laurel frame,
/// atmospheric twilight village scenery, metallic level badge, and responsive 320px layout.
class HeroXpHud extends ConsumerWidget {
  final List<Habit> habits;

  const HeroXpHud({super.key, required this.habits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationState = ref.watch(gamificationControllerProvider);
    final profile = gamificationState.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentLevel = profile.currentLevel;
    final totalXp = profile.totalXp;
    final xpInLevel = GamificationMath.xpInCurrentLevel(totalXp);
    final xpNeeded = GamificationMath.xpNeededForNextLevel(totalXp);
    final progressRatio = GamificationMath.progressRatioInCurrentLevel(totalXp);
    final rankTitle = GamificationMath.rankTitleForLevel(currentLevel);

    // Unlocked achievements count
    final unlockedAchievementsCount = gamificationState.achievements
        .where((a) => a.isUnlocked)
        .length;

    // Compute best active streak among habits
    final bestStreak = habits.fold<int>(
      0,
      (maxStreak, habit) =>
          habit.currentStreak > maxStreak ? habit.currentStreak : maxStreak,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1B2245), // Softer Twilight Slate
                  Color(0xFF141A35),
                  Color(0xFF0F1428),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF8FAFC),
                  Color(0xFFF1F5F9),
                ],
              ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2E3967)
              : RpgColors.rpgIndigo.withValues(alpha: 0.16),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Stack(
          children: [
            // Atmospheric fantasy background artwork (starfield, aurora, mountain ridges)
            Positioned.fill(
              child: CustomPaint(
                painter: _HeroAtmosphereScenePainter(
                  isDark: isDark,
                  primaryColor: isDark
                      ? RpgColors.mutedViolet
                      : RpgColors.rpgIndigo,
                  accentColor: RpgColors.warmGold,
                ),
              ),
            ),

            // Decorative gold corner filigrees
            Positioned(
              top: 0,
              left: 0,
              child: CustomPaint(
                size: const Size(16, 16),
                painter: _HeroCornerPainter(
                  color: isDark ? RpgColors.warmGold : RpgColors.rpgIndigo,
                  isTop: true,
                  isLeft: true,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(16, 16),
                painter: _HeroCornerPainter(
                  color: isDark ? RpgColors.warmGold : RpgColors.rpgIndigo,
                  isTop: true,
                  isLeft: false,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: CustomPaint(
                size: const Size(16, 16),
                painter: _HeroCornerPainter(
                  color: isDark ? RpgColors.warmGold : RpgColors.rpgIndigo,
                  isTop: false,
                  isLeft: true,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(16, 16),
                painter: _HeroCornerPainter(
                  color: isDark ? RpgColors.warmGold : RpgColors.rpgIndigo,
                  isTop: false,
                  isLeft: false,
                ),
              ),
            ),

            // Inner HUD Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Hero Avatar Frame with laurel flourish + Player Name & Rank + Level Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Golden Laurel Hero Avatar Frame (compact & prominent)
                      const HeroAvatarFrame.heroDefault(
                        size: 56.0,
                        showFlourish: true,
                      ),
                      const SizedBox(width: 12),

                      // Player Information Column:
                      // 1. Avatar + Name + Level
                      // 2. Rank Title
                      // 3. Compact XP Bar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Name & Level Badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    profile.heroName,
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                LevelBadge(level: currentLevel, compact: true),
                              ],
                            ),
                            const SizedBox(height: 3),

                            // 2. Rank Title
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_rounded,
                                  size: 11.5,
                                  color: isDark
                                      ? RpgColors.arcaneVioletLight
                                      : RpgColors.arcaneViolet,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    rankTitle,
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF475569),
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),

                            // 3. Compact XP Bar
                            CompactXpBar(
                              currentXp: xpInLevel,
                              requiredXp: xpNeeded,
                              progressRatio: progressRatio,
                              height: 5.0,
                              showLabel: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 4. Compact stats row (Day Streak, Badges, Total XP)
                  Row(
                    children: [
                      // Card 1: Day Streak
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 5.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF13182E)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? (bestStreak > 0
                                        ? Colors.deepOrange.withValues(
                                            alpha: 0.35,
                                          )
                                        : const Color(0xFF222B48))
                                  : (bestStreak > 0
                                        ? Colors.deepOrange.withValues(
                                            alpha: 0.25,
                                          )
                                        : const Color(0xFFE2E8F0)),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 14,
                                color: bestStreak > 0
                                    ? Colors.deepOrange
                                    : (isDark
                                          ? Colors.grey.shade500
                                          : Colors.grey),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  bestStreak > 0
                                      ? '$bestStreak-day Streak'
                                      : '0 Streak',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: bestStreak > 0
                                        ? Colors.deepOrange
                                        : (isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Card 2: Badges
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 5.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF13182E)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF222B48)
                                  : const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.military_tech_rounded,
                                size: 14,
                                color: RpgColors.warmGold,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  '$unlockedAchievementsCount Badges',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? RpgColors.warmGold
                                        : const Color(0xFFB45309),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Card 3: Total XP
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 5.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF13182E)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF222B48)
                                  : const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 14,
                                color: RpgColors.rpgGold,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  '$totalXp Total XP',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? RpgColors.rpgGold
                                        : const Color(0xFFB45309),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
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

/// Atmospheric fantasy scene custom painter: Starry night sky, celestial aura, and mountain silhouettes.
class _HeroAtmosphereScenePainter extends CustomPainter {
  final bool isDark;
  final Color primaryColor;
  final Color accentColor;

  _HeroAtmosphereScenePainter({
    required this.isDark,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Arcane Celestial Aura behind the Avatar frame (subtle portrait halo)
    final auraCenter = const Offset(38, 38);
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: isDark ? 0.16 : 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: auraCenter, radius: 64));
    canvas.drawCircle(auraCenter, 64, auraPaint);

    // 2. Starfield & Arcane Dust in dark mode
    if (isDark) {
      final starPaint = Paint()..style = PaintingStyle.fill;
      final stars = [
        Offset(w * 0.32, h * 0.14),
        Offset(w * 0.50, h * 0.18),
        Offset(w * 0.65, h * 0.12),
        Offset(w * 0.78, h * 0.22),
        Offset(w * 0.88, h * 0.15),
        Offset(w * 0.94, h * 0.30),
        Offset(w * 0.40, h * 0.35),
        Offset(w * 0.82, h * 0.40),
      ];

      for (int i = 0; i < stars.length; i++) {
        final pos = stars[i];
        final radius = (i % 3 == 0) ? 1.1 : 0.75;
        final alpha = (i % 2 == 0) ? 0.42 : 0.24;
        starPaint.color = (i % 4 == 0 ? accentColor : Colors.white).withValues(
          alpha: alpha,
        );
        canvas.drawCircle(pos, radius, starPaint);
      }
    }

    // 3. Atmospheric Mountain / Spire Silhouettes in lower right
    final mountainPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = (isDark ? const Color(0xFF1B2348) : const Color(0xFFDCE4F7))
          .withValues(alpha: isDark ? 0.18 : 0.22);

    final path1 = Path();
    path1.moveTo(w * 0.42, h);
    path1.lineTo(w * 0.58, h * 0.74);
    path1.lineTo(w * 0.72, h * 0.86);
    path1.lineTo(w * 0.86, h * 0.68);
    path1.lineTo(w, h * 0.78);
    path1.lineTo(w, h);
    path1.close();
    canvas.drawPath(path1, mountainPaint);

    final ridgePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = (isDark ? const Color(0xFF131830) : const Color(0xFFEDF2FD))
          .withValues(alpha: isDark ? 0.28 : 0.32);

    final path2 = Path();
    path2.moveTo(w * 0.52, h);
    path2.lineTo(w * 0.68, h * 0.84);
    path2.lineTo(w * 0.80, h * 0.75);
    path2.lineTo(w * 0.92, h * 0.88);
    path2.lineTo(w, h * 0.83);
    path2.lineTo(w, h);
    path2.close();
    canvas.drawPath(path2, ridgePaint);
  }

  @override
  bool shouldRepaint(covariant _HeroAtmosphereScenePainter oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.accentColor != accentColor;
}

/// Delicate corner bracket painter for fantasy HUD
class _HeroCornerPainter extends CustomPainter {
  final Color color;
  final bool isTop;
  final bool isLeft;

  _HeroCornerPainter({
    required this.color,
    required this.isTop,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path();

    final cornerX = isLeft ? 3.0 : w - 3.0;
    final cornerY = isTop ? 3.0 : h - 3.0;
    final lineEndX = isLeft ? 9.0 : w - 9.0;
    final lineEndY = isTop ? 9.0 : h - 9.0;

    path.moveTo(cornerX, lineEndY);
    path.lineTo(cornerX, cornerY);
    path.lineTo(lineEndX, cornerY);

    canvas.drawPath(path, paint);

    // Miniature diamond point
    final pipPaint = Paint()
      ..color = color.withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cornerX, cornerY), 0.9, pipPaint);
  }

  @override
  bool shouldRepaint(covariant _HeroCornerPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isTop != isTop ||
      oldDelegate.isLeft != isLeft;
}
