import 'package:flutter/material.dart';
import '../theme/rpg_spacing.dart';
import 'rpg_card.dart';

/// Convenient wrapper for the Cozy Adventure RPG card surface.
/// Encapsulates Soft Indigo (#1A2447), subtle 1px border (#263359),
/// and gentle non-aggressive shadows.
class CozyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final RpgCardVariant variant;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Color? color;
  final bool hasGlow;

  const CozyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(RpgSpacing.lg),
    this.margin,
    this.onTap,
    this.variant = RpgCardVariant.cozy,
    this.borderRadius,
    this.borderColor,
    this.color,
    this.hasGlow = false,
  });

  /// Card with the rich purple-indigo gradient for Daily Bounties
  factory CozyCard.bounty({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    BorderRadius? borderRadius,
  }) => CozyCard(
    key: key,
    variant: RpgCardVariant.cozyBounty,
    padding: padding ?? const EdgeInsets.all(RpgSpacing.lg),
    margin: margin,
    onTap: onTap,
    borderRadius: borderRadius,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return RpgCard(
      variant: variant,
      padding: padding,
      margin: margin,
      onTap: onTap,
      borderRadius: borderRadius ?? BorderRadius.circular(18.0),
      borderColor: borderColor,
      color: color,
      hasGlow: hasGlow,
      child: child,
    );
  }
}
