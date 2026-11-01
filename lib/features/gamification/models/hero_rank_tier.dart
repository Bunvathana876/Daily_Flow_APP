import 'package:flutter/material.dart';

/// Visual rank-based tier mapped deterministically to the existing player level.
/// Used exclusively for decorative borders, glow frames, and trophy aesthetic.
enum HeroRankTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond;

  static HeroRankTier fromLevel(int level) {
    if (level <= 2) return HeroRankTier.bronze;
    if (level <= 4) return HeroRankTier.silver;
    if (level <= 7) return HeroRankTier.gold;
    if (level <= 11) return HeroRankTier.platinum;
    return HeroRankTier.diamond;
  }

  String get displayName {
    switch (this) {
      case HeroRankTier.bronze:
        return 'Bronze Tier';
      case HeroRankTier.silver:
        return 'Silver Tier';
      case HeroRankTier.gold:
        return 'Gold Tier';
      case HeroRankTier.platinum:
        return 'Platinum Tier';
      case HeroRankTier.diamond:
        return 'Diamond Tier';
    }
  }

  Color get primaryColor {
    switch (this) {
      case HeroRankTier.bronze:
        return const Color(0xFFCD7F32);
      case HeroRankTier.silver:
        return const Color(0xFFCBD5E1);
      case HeroRankTier.gold:
        return const Color(0xFFEAB308);
      case HeroRankTier.platinum:
        return const Color(0xFF38BDF8);
      case HeroRankTier.diamond:
        return const Color(0xFFA855F7);
    }
  }

  Color get glowColor {
    switch (this) {
      case HeroRankTier.bronze:
        return const Color(0xFFD97706);
      case HeroRankTier.silver:
        return const Color(0xFF94A3B8);
      case HeroRankTier.gold:
        return const Color(0xFFFBBF24);
      case HeroRankTier.platinum:
        return const Color(0xFF06B6D4);
      case HeroRankTier.diamond:
        return const Color(0xFFEC4899);
    }
  }

  LinearGradient get frameGradient {
    switch (this) {
      case HeroRankTier.bronze:
        return const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFFF59E0B), Color(0xFF78350F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case HeroRankTier.silver:
        return const LinearGradient(
          colors: [Color(0xFF94A3B8), Color(0xFFF1F5F9), Color(0xFF64748B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case HeroRankTier.gold:
        return const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFFEF08A), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case HeroRankTier.platinum:
        return const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFFBAE6FD), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case HeroRankTier.diamond:
        return const LinearGradient(
          colors: [Color(0xFF9333EA), Color(0xFFF472B6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}
