import 'package:flutter/material.dart';
import 'rpg_colors.dart';

/// Centralized catalog of approved Cozy Adventure RPG artwork assets.
/// Provides canonical asset paths and widgets with safe, non-crashing procedural fallbacks.
class CozyArtwork {
  // Master Asset Paths
  static const String heroPortraitDefault =
      'assets/images/hero_portrait_default.png';
  static const String bgFantasyVillage = 'assets/images/bg_fantasy_village.png';
  static const String iconQuestJournal = 'assets/images/icon_quest_journal.png';
  static const String chestAdventure = 'assets/images/chest_adventure.png';
  static const String bgFocusChamber = 'assets/images/bg_focus_chamber.png';

  /// Renders the Quest Journal artwork or a graceful vector fallback.
  static Widget questJournal({double size = 36.0, Color? fallbackColor}) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        iconQuestJournal,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: RpgColors.warmGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(size * 0.25),
            border: Border.all(
              color: RpgColors.warmGold.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Icon(
            Icons.auto_stories_rounded,
            size: size * 0.55,
            color: fallbackColor ?? RpgColors.warmGold,
          ),
        ),
      ),
    );
  }

  /// Renders the Adventure Bounty Chest artwork or a graceful vector fallback.
  static Widget adventureChest({double size = 48.0, Color? fallbackColor}) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        chestAdventure,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF38235C), Color(0xFF1E2447)],
            ),
            borderRadius: BorderRadius.circular(size * 0.25),
            border: Border.all(
              color: RpgColors.warmGold.withValues(alpha: 0.5),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: RpgColors.warmGold.withValues(alpha: 0.20),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            Icons.inventory_2_rounded,
            size: size * 0.55,
            color: fallbackColor ?? RpgColors.warmGold,
          ),
        ),
      ),
    );
  }
}
