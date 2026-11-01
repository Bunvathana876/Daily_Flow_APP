import 'package:flutter/material.dart';

/// Centralized iconography for Cozy Adventure RPG 3.0.
/// Guarantees visual consistency across navigation, quest boards, and character sheets.
class CozyIcons {
  // Navigation
  static const IconData navToday = Icons.home_rounded;
  static const IconData navInsights = Icons.bar_chart_rounded;
  static const IconData navFocus = Icons.hourglass_top_rounded;
  static const IconData navProfile = Icons.person_rounded;

  // Header & Brand
  static const IconData notifications = Icons.notifications_none_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData edit = Icons.edit_rounded;

  // Hero Stats
  static const IconData streak = Icons.local_fire_department_rounded;
  static const IconData badges = Icons.emoji_events_rounded;
  static const IconData totalXp = Icons.auto_awesome_rounded;
  static const IconData crown = Icons.workspace_premium_rounded;

  // Quests & Categories
  static const IconData categoryAll = Icons.grid_view_rounded;
  static const IconData categoryGeneral = Icons.shield_rounded;
  static const IconData categoryHealth = Icons.spa_rounded;
  static const IconData categoryStudy = Icons.auto_stories_rounded;
  static const IconData categoryCoding = Icons.code_rounded;
  static const IconData categoryFitness = Icons.fitness_center_rounded;

  // Actions & Controls
  static const IconData addQuest = Icons.add_rounded;
  static const IconData startFocus = Icons.play_arrow_rounded;
  static const IconData pauseFocus = Icons.pause_rounded;
  static const IconData reset = Icons.refresh_rounded;

  // Bounty & Milestones
  static const IconData bountyScroll = Icons.description_rounded;
  static const IconData bountyChest = Icons.inventory_2_rounded;
  static const IconData milestoneFlag = Icons.flag_rounded;

  // Three Design Pillars
  static const IconData pillarCozy = Icons.eco_rounded;
  static const IconData pillarAdventurous = Icons.auto_awesome_rounded;
  static const IconData pillarProductive = Icons.favorite_rounded;
}

/// The official DailyFlow Shield Logo widget with leaf crest.
/// Matches the brand emblem shown in the top-left of the reference image.
class DailyFlowBrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showSubtitle;

  const DailyFlowBrandLogo({
    super.key,
    this.size = 32.0,
    this.showText = false,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget emblem = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _DailyFlowLogoPainter(),
      ),
    );

    if (!showText) return emblem;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblem,
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DailyFlow',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: Colors.white,
                fontFamilyFallback: ['Cinzel', 'Georgia', 'serif'],
              ),
            ),
            if (showSubtitle) ...[
              const SizedBox(height: 1),
              Text(
                'Level Up Your Daily Life ✨',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DailyFlowLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shield path
    final shieldPath = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.9, h * 0.12)
      ..lineTo(w * 0.9, h * 0.52)
      ..cubicTo(w * 0.9, h * 0.82, w * 0.6, h * 0.96, w * 0.5, h)
      ..cubicTo(w * 0.4, h * 0.96, w * 0.1, h * 0.82, w * 0.1, h * 0.52)
      ..lineTo(w * 0.1, h * 0.12)
      ..close();

    // Shield background gradient (Muted Violet)
    final shieldGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8B48A7), Color(0xFF5B3478)],
    ).createShader(Offset.zero & size);

    final fillPaint = Paint()
      ..shader = shieldGradient
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, fillPaint);

    // Subtle border stroke
    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(shieldPath, strokePaint);

    // Leaf emblem in the center (White / soft lavender)
    final leafPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Elegant curved sprouting leaf
    final leafPath = Path()
      ..moveTo(w * 0.5, h * 0.72)
      ..cubicTo(w * 0.45, h * 0.50, w * 0.32, h * 0.42, w * 0.35, h * 0.30)
      ..cubicTo(w * 0.48, h * 0.32, w * 0.52, h * 0.45, w * 0.5, h * 0.72)
      ..close();

    final rightLeaf = Path()
      ..moveTo(w * 0.5, h * 0.72)
      ..cubicTo(w * 0.55, h * 0.48, w * 0.68, h * 0.38, w * 0.65, h * 0.25)
      ..cubicTo(w * 0.52, h * 0.28, w * 0.48, h * 0.42, w * 0.5, h * 0.72)
      ..close();

    canvas.drawPath(leafPath, leafPaint);
    canvas.drawPath(rightLeaf, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
