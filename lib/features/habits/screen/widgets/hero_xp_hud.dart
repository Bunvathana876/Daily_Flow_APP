import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/rpg_colors.dart';
import '../../../../core/theme/rpg_spacing.dart';
import '../../../../core/utils/gamification_math.dart';
import '../../../../core/widgets/level_badge.dart';
import '../../../../core/widgets/xp_progress_bar.dart';
import '../../../gamification/controllers/gamification_controller.dart';
import '../../../gamification/widgets/hero_avatar_badge.dart';
import '../../models/habit.dart';

/// Immersive Hero Dashboard HUD displaying player level, rank, XP progression,
/// active streak, and achievement indicators.
///
/// Features a sculpted hero avatar crest, atmospheric fantasy mountain & constellation
/// scene, metallic gold level badge, and responsive layouts that adapt to 320px screens.
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
                  Color(0xFF1B1F4A), // Rich Twilight Indigo
                  Color(0xFF131832), // Midnight Slate
                  Color(0xFF0B0E1B), // Abyss Navy
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF7F9FF),
                  Color(0xFFEEF2FF),
                ],
              ),
        borderRadius: BorderRadius.circular(RpgSpacing.radiusCard),
        border: Border.all(
          color: isDark
              ? RpgColors.rpgGold.withValues(alpha: 0.38)
              : RpgColors.rpgIndigo.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? RpgColors.rpgViolet.withValues(alpha: 0.22)
                : RpgColors.rpgIndigo.withValues(alpha: 0.08),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RpgSpacing.radiusCard),
        child: Stack(
          children: [
            // Atmospheric fantasy background artwork (starfield, aurora, mountain ridges)
            Positioned.fill(
              child: CustomPaint(
                painter: _HeroAtmosphereScenePainter(
                  isDark: isDark,
                  primaryColor: isDark
                      ? RpgColors.rpgViolet
                      : RpgColors.rpgIndigo,
                  accentColor: RpgColors.rpgGold,
                ),
              ),
            ),

            // Decorative gold corner filigrees
            Positioned(
              top: 0,
              left: 0,
              child: CustomPaint(
                size: const Size(18, 18),
                painter: _HeroCornerPainter(
                  color: isDark ? RpgColors.rpgGold : RpgColors.rpgIndigo,
                  isTop: true,
                  isLeft: true,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(18, 18),
                painter: _HeroCornerPainter(
                  color: isDark ? RpgColors.rpgGold : RpgColors.rpgIndigo,
                  isTop: true,
                  isLeft: false,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: CustomPaint(
                size: const Size(18, 18),
                painter: _HeroCornerPainter(
                  color: isDark ? RpgColors.rpgGold : RpgColors.rpgIndigo,
                  isTop: false,
                  isLeft: true,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(18, 18),
                painter: _HeroCornerPainter(
                  color: isDark ? RpgColors.rpgGold : RpgColors.rpgIndigo,
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
                  // Row 1: Illustrated Avatar Crest + Player Name & Rank + Golden Level Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Sculpted Hero Avatar Crest with Rank Tier Bezel
                      HeroAvatarBadge(
                        avatarId: profile.avatarId,
                        size: 46.0,
                        playerLevel: currentLevel,
                      ),
                      const SizedBox(width: 10),

                      // Player Name & Title Rank
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              profile.heroName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? RpgColors.arcaneViolet.withValues(
                                        alpha: 0.18,
                                      )
                                    : RpgColors.arcaneViolet.withValues(
                                        alpha: 0.10,
                                      ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? RpgColors.arcaneViolet.withValues(
                                          alpha: 0.35,
                                        )
                                      : RpgColors.arcaneViolet.withValues(
                                          alpha: 0.20,
                                        ),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shield_rounded,
                                    size: 10,
                                    color: isDark
                                        ? RpgColors.arcaneVioletLight
                                        : RpgColors.arcaneViolet,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      rankTitle,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? RpgColors.arcaneVioletLight
                                            : RpgColors.arcaneViolet,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: RpgSpacing.xs),

                      // Golden Level Badge
                      LevelBadge(level: currentLevel, compact: true),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 2: Rich XP Progress Bar
                  XpProgressBar(
                    currentXp: xpInLevel,
                    requiredXp: xpNeeded,
                    progressRatio: progressRatio,
                    height: 6.5,
                    leadingLabel: 'LVL $currentLevel XP',
                  ),
                  const SizedBox(height: 6),

                  // Row 3: Statistics Ribbon (Total XP, Streak, Achievements) - Wrap for 320px responsiveness
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Total XP Counter
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: RpgColors.rpgGold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalXp Total XP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      // Current Streak Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bestStreak > 0
                              ? Colors.deepOrange.withValues(
                                  alpha: isDark ? 0.18 : 0.12,
                                )
                              : (isDark
                                    ? Colors.white10
                                    : Colors.grey.shade100),
                          borderRadius: RpgSpacing.roundedPill,
                          border: Border.all(
                            color: bestStreak > 0
                                ? Colors.deepOrange.withValues(
                                    alpha: isDark ? 0.40 : 0.25,
                                  )
                                : (isDark
                                      ? Colors.white12
                                      : Colors.grey.shade300),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 13,
                              color: bestStreak > 0
                                  ? Colors.deepOrange
                                  : (isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              bestStreak > 0
                                  ? '$bestStreak-day Streak'
                                  : '0 Streak',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: bestStreak > 0
                                    ? Colors.deepOrange
                                    : (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Achievement Trophy Count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? RpgColors.arcaneViolet.withValues(alpha: 0.16)
                              : RpgColors.arcaneViolet.withValues(alpha: 0.10),
                          borderRadius: RpgSpacing.roundedPill,
                          border: Border.all(
                            color: RpgColors.arcaneViolet.withValues(
                              alpha: isDark ? 0.35 : 0.20,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.military_tech_rounded,
                              size: 13,
                              color: isDark
                                  ? RpgColors.arcaneVioletLight
                                  : RpgColors.arcaneViolet,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$unlockedAchievementsCount Badges',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? RpgColors.arcaneVioletLight
                                    : RpgColors.arcaneViolet,
                              ),
                            ),
                          ],
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

    // 1. Soft Arcane Celestial Aura behind the Avatar crest (approx x: 40, y: 36)
    final auraCenter = const Offset(40, 36);
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: isDark ? 0.24 : 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: auraCenter, radius: 76));
    canvas.drawCircle(auraCenter, 76, auraPaint);

    // 2. Starfield & Arcane Dust in dark mode
    if (isDark) {
      final starPaint = Paint()..style = PaintingStyle.fill;
      final stars = [
        Offset(w * 0.26, h * 0.15),
        Offset(w * 0.46, h * 0.20),
        Offset(w * 0.62, h * 0.12),
        Offset(w * 0.74, h * 0.26),
        Offset(w * 0.86, h * 0.16),
        Offset(w * 0.93, h * 0.32),
        Offset(w * 0.36, h * 0.38),
        Offset(w * 0.80, h * 0.44),
      ];

      for (int i = 0; i < stars.length; i++) {
        final pos = stars[i];
        final radius = (i % 3 == 0) ? 1.3 : 0.85;
        final alpha = (i % 2 == 0) ? 0.70 : 0.45;
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
          .withValues(alpha: isDark ? 0.32 : 0.40);

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
          .withValues(alpha: isDark ? 0.52 : 0.60);

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
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path();

    final cornerX = isLeft ? 3.0 : w - 3.0;
    final cornerY = isTop ? 3.0 : h - 3.0;
    final lineEndX = isLeft ? 10.0 : w - 10.0;
    final lineEndY = isTop ? 10.0 : h - 10.0;

    path.moveTo(cornerX, lineEndY);
    path.lineTo(cornerX, cornerY);
    path.lineTo(lineEndX, cornerY);

    canvas.drawPath(path, paint);

    // Miniature diamond point
    final pipPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cornerX, cornerY), 1.0, pipPaint);
  }

  @override
  bool shouldRepaint(covariant _HeroCornerPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isTop != isTop ||
      oldDelegate.isLeft != isLeft;
}
