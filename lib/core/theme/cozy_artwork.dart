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

  /// All registered Cozy Adventure RPG artwork assets.
  static const List<String> allAssets = [
    heroPortraitDefault,
    bgFantasyVillage,
    iconQuestJournal,
    chestAdventure,
    bgFocusChamber,
  ];

  /// Renders the Quest Journal artwork or a graceful vector fallback.
  static Widget questJournal({
    double size = 36.0,
    Color? fallbackColor,
    String? assetPath,
    bool forceFallback = false,
  }) {
    if (forceFallback) {
      return questJournalFallback(size: size, fallbackColor: fallbackColor);
    }
    final path = assetPath ?? iconQuestJournal;
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            questJournalFallback(size: size, fallbackColor: fallbackColor),
      ),
    );
  }

  /// Procedural vector fallback for the Quest Journal icon.
  static Widget questJournalFallback({
    double size = 36.0,
    Color? fallbackColor,
  }) {
    return Container(
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
      child: Center(
        child: Icon(
          Icons.auto_stories_rounded,
          size: size * 0.55,
          color: fallbackColor ?? RpgColors.warmGold,
        ),
      ),
    );
  }

  /// Renders the Adventure Bounty Chest artwork or a graceful vector fallback.
  static Widget adventureChest({
    double size = 48.0,
    Color? fallbackColor,
    String? assetPath,
    bool forceFallback = false,
  }) {
    if (forceFallback) {
      return adventureChestFallback(size: size, fallbackColor: fallbackColor);
    }
    final path = assetPath ?? chestAdventure;
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            adventureChestFallback(size: size, fallbackColor: fallbackColor),
      ),
    );
  }

  /// Procedural vector fallback for the Adventure Bounty Chest icon.
  static Widget adventureChestFallback({
    double size = 48.0,
    Color? fallbackColor,
  }) {
    return Container(
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
      child: Center(
        child: Icon(
          Icons.inventory_2_rounded,
          size: size * 0.55,
          color: fallbackColor ?? RpgColors.warmGold,
        ),
      ),
    );
  }
}

/// Reusable widget for rendering the Cozy Quest Journal artwork with graceful vector fallback.
class QuestJournalIcon extends StatelessWidget {
  final double size;
  final Color? fallbackColor;
  final String? assetPath;
  final bool forceFallback;

  const QuestJournalIcon({
    super.key,
    this.size = 36.0,
    this.fallbackColor,
    this.assetPath,
    this.forceFallback = false,
  });

  @override
  Widget build(BuildContext context) {
    return CozyArtwork.questJournal(
      size: size,
      fallbackColor: fallbackColor,
      assetPath: assetPath,
      forceFallback: forceFallback,
    );
  }
}

/// Reusable widget for rendering the Cozy Adventure Bounty Chest artwork with graceful vector fallback.
class AdventureChestIcon extends StatelessWidget {
  final double size;
  final Color? fallbackColor;
  final String? assetPath;
  final bool forceFallback;

  const AdventureChestIcon({
    super.key,
    this.size = 48.0,
    this.fallbackColor,
    this.assetPath,
    this.forceFallback = false,
  });

  @override
  Widget build(BuildContext context) {
    return CozyArtwork.adventureChest(
      size: size,
      fallbackColor: fallbackColor,
      assetPath: assetPath,
      forceFallback: forceFallback,
    );
  }
}
