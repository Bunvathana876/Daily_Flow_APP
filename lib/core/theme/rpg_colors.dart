import 'package:flutter/material.dart';

/// Cozy Adventure RPG color tokens for DailyFlow 3.0 design system.
/// Theme: Cozy Adventure RPG (Approved Reference Specification)
///
/// Midnight navy & soft indigo backgrounds, muted violet & warm lantern accents,
/// warm gold for XP/rewards/buttons, cozy amber, emerald for quest completion,
/// and gentle, non-aggressive atmospheric lighting.
class RpgColors {
  // =========================================================================
  // Cozy Adventure RPG 3.0 Core Palette (Approved Design Specification)
  // =========================================================================
  /// Midnight Navy scaffold & deepest canvas (#0B1224)
  static const Color midnightNavy = Color(0xFF0B1224);

  /// Soft Indigo primary card surface (#1A2447)
  static const Color softIndigo = Color(0xFF1A2447);

  /// Elevated / modal surface in Dark Mode (#232E58)
  static const Color softIndigoElevated = Color(0xFF232E58);

  /// Muted Violet arcane energy & secondary highlights (#8B48A7)
  static const Color mutedViolet = Color(0xFF8B48A7);

  /// Muted Violet alternate soft tone (#5B48A7)
  static const Color mutedVioletMuted = Color(0xFF5B48A7);

  /// Warm Gold XP, level badges, primary buttons & accents (#F3B74A)
  static const Color warmGold = Color(0xFFF3B74A);

  /// Cozy Amber streak and warm secondary accent (#F99A5A)
  static const Color cozyAmber = Color(0xFFF99A5A);

  /// Cozy Amber alternate muted tone (#E99A5A)
  static const Color cozyAmberMuted = Color(0xFFE99A5A);

  /// Emerald quest completion & vitality (#2EBF7E)
  static const Color emeraldComplete = Color(0xFF2EBF7E);

  /// Subtle dark card border (#263359)
  static const Color cozyBorderDark = Color(0xFF263359);

  /// Highlight card border (#3A4978)
  static const Color cozyBorderHighlight = Color(0xFF3A4978);

  /// Warm lantern glow color (#F3B74A)
  static const Color cozyLanternGlow = Color(0xFFF3B74A);

  // --- Backgrounds & Canvases ---
  /// Deepest dark scaffold background (#0B1224 - Midnight Navy)
  static const Color rpgAbyss = midnightNavy;

  /// Deep celestial midnight canvas (#0B1224)
  static const Color rpgMidnight = midnightNavy;

  /// Secondary dark canvas (#141E38 - Dungeon Slate)
  static const Color rpgDungeonSlate = Color(0xFF141E38);

  /// Primary card surface in Dark Mode (#1A2447 - Soft Indigo)
  static const Color rpgSurfaceDark = softIndigo;

  /// Elevated / modal surface in Dark Mode (#232E58)
  static const Color rpgSurfaceElevated = softIndigoElevated;

  /// Frosted glass overlay for twilight dark mode
  static const Color rpgSurfaceGlass = Color(0xCC1A2447);

  // --- Light Mode Surfaces (Morning Mist & Ancient Parchment) ---
  /// Clean, crisp background for Light Mode (#F8F9FE - Morning Mist)
  static const Color rpgMist = Color(0xFFF8F9FE);

  /// Primary card background in Light Mode (#FFFFFF)
  static const Color rpgSurfaceLight = Color(0xFFFFFFFF);

  /// Warm parchment background tint (#ECEFFC)
  static const Color rpgParchment = Color(0xFFECEFFC);

  /// Secondary light surface (#F1F5F9)
  static const Color rpgSurfaceLightAlt = Color(0xFFF1F5F9);

  // --- Borders & Glowing Edges ---
  /// Subtle border stroke for Dark Mode cards (#263359)
  static const Color rpgBorderDark = cozyBorderDark;

  /// Subtle border stroke for Light Mode cards (#E2E8F0)
  static const Color rpgBorderLight = Color(0xFFE2E8F0);

  /// Highlight border stroke for interactive / elevated cards (#3A4978)
  static const Color rpgBorderHighlight = cozyBorderHighlight;

  /// Magical glowing edge border (#8B48A7)
  static const Color rpgBorderArcane = mutedViolet;

  /// Gold crest border (#F3B74A)
  static const Color rpgBorderGold = warmGold;

  /// Emerald completed border (#2EBF7E)
  static const Color rpgBorderEmerald = emeraldComplete;

  // --- Arcana: Indigo & Violet Lighting ---
  /// Primary brand accent / rune indicator (#6366F1 - Indigo Rune)
  static const Color rpgIndigo = Color(0xFF6366F1);

  /// Deep indigo (#4F46E5)
  static const Color rpgIndigoDeep = Color(0xFF4F46E5);

  /// Arcane energy / magical highlight (#8B48A7 - Muted Violet)
  static const Color rpgViolet = mutedViolet;

  /// Deep violet (#7C3AED)
  static const Color rpgVioletDeep = Color(0xFF7C3AED);

  /// Soft shimmering violet (#A866C5)
  static const Color rpgVioletLight = Color(0xFFA866C5);

  /// Delicate violet glow (#D3A4E6)
  static const Color rpgVioletGlow = Color(0xFFD3A4E6);

  // --- Radiant Gold: XP, Rankings & Rewards ---
  /// Warm Gold for XP and rankings (#F3B74A)
  static const Color rpgGold = warmGold;

  /// Crown Gold for streaks and trophies (#FCD57A)
  static const Color rpgGoldBright = Color(0xFFFCD57A);

  /// Warm bronze gold (#D4972B)
  static const Color rpgGoldMuted = Color(0xFFD4972B);

  /// Pale golden shimmer (#FEF3C7)
  static const Color rpgGoldGlint = Color(0xFFFEF3C7);

  // --- Emerald: Quests, Vitality & Success ---
  /// Quest completion & health habits (#2EBF7E - Emerald Complete)
  static const Color rpgEmerald = emeraldComplete;

  /// Forest Jade (#229964)
  static const Color rpgForestJade = Color(0xFF229964);

  /// Vibrant emerald highlight (#4EE39E)
  static const Color rpgEmeraldLight = Color(0xFF4EE39E);

  /// Soft emerald background tint (#D4F7E6)
  static const Color rpgEmeraldTint = Color(0xFFD4F7E6);

  // --- Celestial Cyan: Mana, Focus Chamber & Crystals ---
  /// Focus chamber & mana crystal (#06B6D4 - Mana Blue)
  static const Color rpgCyan = Color(0xFF06B6D4);

  /// Sky crystal accent (#38BDF8)
  static const Color rpgSkyCrystal = Color(0xFF38BDF8);

  /// Mana glow (#67E8F9)
  static const Color rpgManaGlow = Color(0xFF67E8F9);

  // --- Flame Ruby & Amber: Urgency, Streak Fire & Danger ---
  /// Streak flame & urgent quests (#F43F5E - Dragon Rose)
  static const Color rpgCrimson = Color(0xFFF43F5E);
  static const Color rpgDragonRose = Color(0xFFF43F5E);

  /// Crimson spark (#EF4444)
  static const Color rpgCrimsonSpark = Color(0xFFEF4444);

  /// Flame tint (#FECDD3)
  static const Color rpgFlameTint = Color(0xFFFECDD3);

  // --- Typography Text Colors ---
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // --- Thematic Aliases (Backwards Compatibility) ---
  static const Color arcaneViolet = rpgViolet;
  static const Color arcaneVioletLight = rpgVioletLight;
  static const Color questEmerald = rpgEmerald;
  static const Color abyssNavySurface = rpgSurfaceDark;

  // --- Gradients ---
  /// Warm Gold to Cozy Amber gradient for primary CTA buttons
  static const LinearGradient cozyGoldGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [warmGold, cozyAmber],
  );

  /// Cozy Daily Bounty card gradient
  static const LinearGradient cozyBountyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38235C), Color(0xFF1B2349)],
  );

  /// Soft card gradient with gentle depth
  static const LinearGradient cozyCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E284E), Color(0xFF161F3D)],
  );

  /// Atmospheric twilight landscape background gradient
  static const LinearGradient cozyAtmosphereGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF281F48), Color(0xFF161E3D), Color(0xFF0B1224)],
  );

  static const LinearGradient violetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [rpgIndigo, mutedViolet],
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF261E47), Color(0xFF161E3F)],
  );

  static const LinearGradient heroSanctuaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF281F48), Color(0xFF141C38), Color(0xFF0B1224)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warmGold, cozyAmber],
  );

  static const LinearGradient goldBevelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [rpgGoldGlint, rpgGoldBright, warmGold, rpgGoldMuted],
  );

  static const LinearGradient xpProgressGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [mutedViolet, rpgIndigo, emeraldComplete],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emeraldComplete, rpgForestJade],
  );

  static const LinearGradient manaCrystalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [rpgSkyCrystal, rpgCyan, rpgIndigo],
  );

  static const LinearGradient streakFlameGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [cozyAmber, warmGold, rpgGoldBright],
  );

  static const LinearGradient darkCardSurfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E284E), Color(0xFF161F3D)],
  );

  static const LinearGradient darkGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x22FFFFFF), Color(0x05FFFFFF)],
  );

  // --- Gentle Shadows & Warm Glows (Avoid Excessive Neon) ---
  static List<BoxShadow> ambientGlow(
    Color color, {
    double blurRadius = 10,
    double spreadRadius = 0,
    double opacity = 0.18,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: const Offset(0, 3),
      ),
    ];
  }

  static List<BoxShadow> get arcaneGlow =>
      ambientGlow(mutedViolet, opacity: 0.18);
  static List<BoxShadow> get goldGlow => ambientGlow(warmGold, opacity: 0.20);
  static List<BoxShadow> get emeraldGlow =>
      ambientGlow(emeraldComplete, opacity: 0.18);
  static List<BoxShadow> get cyanGlow => ambientGlow(rpgCyan, opacity: 0.16);
  static List<BoxShadow> get lanternGlow =>
      ambientGlow(cozyLanternGlow, blurRadius: 14, opacity: 0.22);
}
