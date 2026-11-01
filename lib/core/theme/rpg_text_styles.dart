import 'package:flutter/material.dart';
import 'rpg_colors.dart';

/// Thematic RPG typography hierarchy matching the Cozy Enchanted Fantasy design specification.
/// Features elegant fantasy-inspired headings paired with crisp, readable modern body copy.
class RpgTextStyles {
  // Font Fallback Stacks
  static const List<String> fantasyHeadingFallbacks = [
    'Cinzel',
    'Georgia',
    'Palatino',
    'Times New Roman',
    'serif',
  ];

  static const List<String> modernBodyFallbacks = [
    'Inter',
    'Plus Jakarta Sans',
    '-apple-system',
    'Roboto',
    'Helvetica Neue',
    'sans-serif',
  ];

  // --- Core Hierarchy ---

  /// Level-up modals, hero splash title (32px / Extra Bold)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    height: 1.2,
    fontFamilyFallback: fantasyHeadingFallbacks,
  );

  /// Hero Screen titles: "Quest Log", "Focus Chamber", "Hero's Armory" (24px / Bold 800)
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    height: 1.25,
    fontFamilyFallback: fantasyHeadingFallbacks,
  );

  /// Section headers, milestone banners, category titles (20px / Bold 700)
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
    fontFamilyFallback: fantasyHeadingFallbacks,
  );

  /// Card titles, sub-section headers (18px / Semi-bold 600)
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.3,
    fontFamilyFallback: fantasyHeadingFallbacks,
  );

  /// Habit / Quest titles in cards (16px / Semi-bold 600)
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
    height: 1.35,
    fontFamilyFallback: modernBodyFallbacks,
  );

  /// Small title, dialog subheaders (14px / Semi-bold 600)
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.35,
    fontFamilyFallback: modernBodyFallbacks,
  );

  /// Emphasized body text, important descriptions (16px / Regular 400)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.15,
    height: 1.45,
    fontFamilyFallback: modernBodyFallbacks,
  );

  /// Descriptions, subtitles, log dates (14px / Regular 400)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.1,
    height: 1.4,
    fontFamilyFallback: modernBodyFallbacks,
  );

  /// Small descriptions, timestamps, metadata (12px / Regular 400)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.2,
    height: 1.35,
    fontFamilyFallback: modernBodyFallbacks,
  );

  /// Badges, XP tags, streak counters (12px / Bold 700 with wide tracking)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    fontFamilyFallback: modernBodyFallbacks,
  );

  /// 7-day mini-strip day codes, time stamps, status chips (11px / Medium 500)
  static const TextStyle labelMedium = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    fontFamilyFallback: modernBodyFallbacks,
  );

  /// Compact tags, mini micro-badges (10px / Medium 500)
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    fontFamilyFallback: modernBodyFallbacks,
  );

  // --- Thematic Stylized Helpers ---

  /// Golden radiant heading for trophies, milestones, and level achievements
  static TextStyle goldHeading({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w800,
  }) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: 0.2,
    color: RpgColors.rpgGold,
    fontFamilyFallback: fantasyHeadingFallbacks,
  );

  /// Arcane violet title for focus sessions, magic scrolls, and sanctums
  static TextStyle arcaneTitle({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w700,
  }) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: -0.1,
    color: RpgColors.rpgVioletLight,
    fontFamilyFallback: fantasyHeadingFallbacks,
  );

  /// Emerald text for completed objectives and bounties
  static TextStyle emeraldSubtitle({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
  }) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: RpgColors.rpgEmerald,
    fontFamilyFallback: modernBodyFallbacks,
  );

  /// XP tag badge typography
  static const TextStyle xpBadgeText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: RpgColors.warmGold,
    fontFamilyFallback: modernBodyFallbacks,
  );

  // =========================================================================
  // Cozy Adventure RPG 3.0 Typography Helpers
  // =========================================================================

  /// Cozy Brand Title: "DailyFlow" (20-22px / Bold serif)
  static const TextStyle cozyBrandTitle = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
    fontFamilyFallback: fantasyHeadingFallbacks,
  );

  /// Cozy Brand Subtitle: "Level Up Your Daily Life ✨"
  static const TextStyle cozyBrandSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: RpgColors.textSecondaryDark,
    fontFamilyFallback: modernBodyFallbacks,
  );

  /// Hero Player Name in HUD & Profile
  static const TextStyle cozyHeroName = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    fontFamilyFallback: fantasyHeadingFallbacks,
  );

  /// Cozy Category Tag in Quest Cards ("STUDY", "HEALTH", "CODING")
  static const TextStyle cozyCategoryTag = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
    fontFamilyFallback: modernBodyFallbacks,
  );

  /// Primary button label ("+ New Quest", "▶ Start Focus")
  static const TextStyle cozyButtonLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
    color: Color(0xFF261502), // Deep warm brown for crisp contrast on gold
    fontFamilyFallback: modernBodyFallbacks,
  );

  /// Cozy stat chip value (e.g. "12", "8", "4,320")
  static const TextStyle cozyStatValue = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    fontFamilyFallback: modernBodyFallbacks,
  );

  /// Cozy stat chip label (e.g. "Day Streak", "Badges", "Total XP")
  static const TextStyle cozyStatLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: RpgColors.textSecondaryDark,
    fontFamilyFallback: modernBodyFallbacks,
  );
}
