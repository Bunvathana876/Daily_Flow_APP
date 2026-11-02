import 'package:flutter/material.dart';
import '../theme/cozy_artwork.dart';
import '../theme/rpg_colors.dart';

/// Cozy Background Atmosphere Scaffold that supports fantasy landscape backdrops,
/// soft vignette gradient transitions into Midnight Navy, and warm lantern lighting.
///
/// Designed to gracefully handle missing or loading image assets via high-performance
/// procedural twilight gradients.
class CozyBackgroundScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final String? backgroundImageAsset;
  final ImageProvider? backgroundImageProvider;
  final double backgroundImageHeight;
  final bool isFullScreenImage;
  final double imageOpacity;
  final bool showLanternGlow;
  final Alignment lanternGlowAlignment;
  final Gradient? atmosphereGradient;

  const CozyBackgroundScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundImageAsset,
    this.backgroundImageProvider,
    this.backgroundImageHeight = 280.0,
    this.isFullScreenImage = false,
    this.imageOpacity = 1.0,
    this.showLanternGlow = true,
    this.lanternGlowAlignment = const Alignment(0.75, -0.75),
    this.atmosphereGradient,
  });

  /// Dedicated constructor configured for the Fantasy Village backdrop.
  const CozyBackgroundScaffold.village({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundImageHeight = 280.0,
    this.isFullScreenImage = false,
    this.imageOpacity = 1.0,
    this.showLanternGlow = true,
    this.lanternGlowAlignment = const Alignment(0.75, -0.75),
    this.atmosphereGradient,
  }) : backgroundImageAsset = CozyArtwork.bgFantasyVillage,
       backgroundImageProvider = null;

  /// Dedicated constructor configured for the Arcane Focus Chamber backdrop.
  const CozyBackgroundScaffold.focusChamber({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundImageHeight = 280.0,
    this.isFullScreenImage = true,
    this.imageOpacity = 0.85,
    this.showLanternGlow = true,
    this.lanternGlowAlignment = const Alignment(-0.6, -0.5),
    this.atmosphereGradient,
  }) : backgroundImageAsset = CozyArtwork.bgFocusChamber,
       backgroundImageProvider = null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget? buildBackgroundImage() {
      if (backgroundImageAsset != null && backgroundImageAsset!.isNotEmpty) {
        return Image.asset(
          backgroundImageAsset!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        );
      } else if (backgroundImageProvider != null) {
        return Image(
          image: backgroundImageProvider!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        );
      }
      return null;
    }

    final bgImageWidget = buildBackgroundImage();

    return Scaffold(
      backgroundColor: isDark ? RpgColors.midnightNavy : RpgColors.rpgMist,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Base Atmospheric Canvas
          if (isDark)
            Container(
              decoration: BoxDecoration(
                gradient:
                    atmosphereGradient ?? RpgColors.cozyAtmosphereGradient,
              ),
            ),

          // Optional Background Image (e.g. fantasy village or focus chamber)
          if (bgImageWidget != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: isFullScreenImage ? 0 : null,
              height: isFullScreenImage ? null : backgroundImageHeight,
              child: Opacity(
                opacity: (isDark ? imageOpacity : (imageOpacity * 0.38)).clamp(
                  0.0,
                  1.0,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    bgImageWidget,
                    // Soft gradient dissolve into background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: isFullScreenImage
                              ? const [0.0, 0.4, 0.85, 1.0]
                              : const [0.0, 0.5, 1.0],
                          colors: isFullScreenImage
                              ? (isDark
                                    ? [
                                        const Color(0x330B1224),
                                        const Color(0x660B1224),
                                        const Color(0xCC0B1224),
                                        RpgColors.midnightNavy,
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.12),
                                        Colors.white.withValues(alpha: 0.45),
                                        Colors.white.withValues(alpha: 0.85),
                                        RpgColors.rpgMist,
                                      ])
                              : (isDark
                                    ? const [
                                        Color(0x330B1224),
                                        Color(0x990B1224),
                                        RpgColors.midnightNavy,
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.12),
                                        Colors.white.withValues(alpha: 0.65),
                                        RpgColors.rpgMist,
                                      ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Warm Lantern Glow Overlay
          if (showLanternGlow)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: lanternGlowAlignment,
                      radius: 0.85,
                      colors: [
                        RpgColors.warmGold.withValues(
                          alpha: isDark ? 0.12 : 0.08,
                        ),
                        RpgColors.cozyAmber.withValues(
                          alpha: isDark ? 0.05 : 0.03,
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

          // Foreground Content
          SafeArea(bottom: bottomNavigationBar == null, child: body),
        ],
      ),
    );
  }
}
