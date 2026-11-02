import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/rpg_colors.dart';
import '../../gamification/controllers/gamification_controller.dart';
import '../../habits/controllers/habit_controller.dart';
import '../../navigation/screen/main_shell.dart';

/// Cozy Adventure Animated Startup Splash Screen for DailyFlow 3.0.
///
/// Seamlessly transitions from the native OS launch screen (#0B1224) into a
/// warm, magical welcome experience featuring the DailyFlow adventurer icon,
/// soft violet ambient radiance, and golden progress indicator while
/// loading essential application state.
class SplashScreen extends ConsumerStatefulWidget {
  final Duration? minDuration;

  const SplashScreen({super.key, this.minDuration});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _navigationTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    // Remove the native splash screen immediately when Flutter draws this frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    _animController.forward();
    _startInitialization();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect system reduced motion preferences
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion && _animController.value < 1.0) {
      _animController.value = 1.0;
    }
  }

  Future<void> _startInitialization() async {
    final stopwatch = Stopwatch()..start();

    // Load initial habit and gamification data concurrently
    try {
      await Future.wait([
        ref.read(habitControllerProvider.notifier).loadHabits(),
        ref
            .read(gamificationControllerProvider.notifier)
            .loadGamificationData(),
      ]);
    } catch (_) {
      // Gracefully continue even if database initial load takes time or fails
    }

    final elapsed = stopwatch.elapsed;
    final reduceMotion =
        mounted && (MediaQuery.maybeOf(context)?.disableAnimations ?? false);

    // Default transition duration allows gentle entrance animation without artificial lag
    final targetDuration =
        widget.minDuration ??
        (reduceMotion ? Duration.zero : const Duration(milliseconds: 650));
    final remaining = targetDuration - elapsed;

    if (remaining > Duration.zero) {
      _navigationTimer = Timer(remaining, _navigateToMain);
    } else {
      _navigateToMain();
    }
  }

  void _navigateToMain() {
    if (!mounted || _navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: RpgColors.midnightNavy,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: RpgColors.midnightNavy,
          gradient: RadialGradient(
            center: Alignment(0.0, -0.15),
            radius: 1.1,
            colors: [
              Color(0xFF141A38), // Soft indigo core
              RpgColors.midnightNavy, // #0B1224 deep midnight canvas
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // Centered DailyFlow Adventurer Icon with Ambient Lighting
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  final animVal = reduceMotion ? 1.0 : _fadeAnimation.value;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft Violet Ambient Lighting Halo (separate layer avoids Impeller opacity issues)
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: 0.22 * animVal),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: RpgColors.warmGold.withValues(
                                alpha: 0.12 * animVal,
                              ),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                      // Main Hero App Icon
                      Transform.scale(
                        scale: reduceMotion ? 1.0 : _scaleAnimation.value,
                        child: Opacity(
                          opacity: animVal,
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: RpgColors.warmGold.withValues(
                                  alpha: 0.35,
                                ),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: 0.45 * animVal,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/icons/dailyflow_app_icon.png',
                                width: 112,
                                height: 112,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback shield crest if asset is not loaded in unit tests
                                  return Container(
                                    color: const Color(0xFF19246E),
                                    child: const Center(
                                      child: Icon(
                                        Icons.shield_rounded,
                                        color: RpgColors.warmGold,
                                        size: 54,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // Title & Tagline
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  final animVal = reduceMotion ? 1.0 : _fadeAnimation.value;
                  return Opacity(opacity: animVal, child: child);
                },
                child: Column(
                  children: [
                    const Text(
                      'DailyFlow',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Color(0xFFFBF8EE), // Warm ivory text
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Level Up Your Daily Life ✨',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: RpgColors.warmGold.withValues(alpha: 0.90),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Small Gold Loading Progress Indicator & Adventure Message
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  final animVal = reduceMotion ? 1.0 : _fadeAnimation.value;
                  return Opacity(opacity: animVal, child: child);
                },
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          RpgColors.warmGold,
                        ),
                        backgroundColor: RpgColors.warmGold.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Preparing your adventure...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
