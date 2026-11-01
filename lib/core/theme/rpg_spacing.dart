import 'package:flutter/material.dart';

/// Spacing, corner radii, elevation, and layout tokens for DailyFlow RPG design system.
class RpgSpacing {
  // Spacing Scale
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Corner Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusCard = 18.0;
  static const double radiusLarge = 24.0;
  static const double radiusPill = 999.0;
  static const double radiusSm = radiusSmall;
  static const double radiusMd = radiusMedium;
  static const double radiusLg = radiusLarge;

  // Border Widths
  static const double borderSubtle = 0.8;
  static const double borderRegular = 1.2;
  static const double borderThick = 2.0;

  // Accessibility: Touch Targets (WCAG 2.1 AA)
  static const double minTouchTarget = 48.0;

  // Pre-configured BorderRadius
  static final BorderRadius roundedSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius roundedMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius roundedCard = BorderRadius.circular(radiusCard);
  static final BorderRadius roundedLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius roundedPill = BorderRadius.circular(radiusPill);

  // Common Layout Padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets dialogPadding = EdgeInsets.all(xxl);
}
