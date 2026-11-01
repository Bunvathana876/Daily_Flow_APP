import 'package:flutter/material.dart';
import '../../../../core/theme/rpg_colors.dart';
import '../../../../core/theme/rpg_spacing.dart';
import '../../../../core/utils/gamification_math.dart';
import '../../../../core/widgets/level_badge.dart';
import '../../../../core/widgets/rpg_filled_button.dart';

/// Celebratory RPG modal presented when the player advances in level.
class LevelUpDialog extends StatelessWidget {
  final int newLevel;
  final VoidCallback? onDismiss;

  const LevelUpDialog({super.key, required this.newLevel, this.onDismiss});

  static Future<void> show(BuildContext context, int newLevel) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => LevelUpDialog(newLevel: newLevel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final rankTitle = GamificationMath.rankTitleForLevel(newLevel);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: disableAnimations ? 1.0 : 0.82, end: 1.0),
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(RpgSpacing.xl),
          decoration: BoxDecoration(
            color: isDark ? RpgColors.abyssNavySurface : Colors.white,
            borderRadius: BorderRadius.circular(RpgSpacing.radiusLg),
            border: Border.all(
              color: RpgColors.rpgGold.withValues(alpha: 0.75),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: RpgColors.rpgGold.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Radiant Crown / Trophy Icon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RpgColors.goldGradient,
                  border: Border.all(
                    color: RpgColors.rpgGoldBright,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: RpgColors.rpgGold.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: RpgSpacing.md),

              // "LEVEL UP!" Banner
              Text(
                'LEVEL UP!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  color: isDark ? RpgColors.rpgGold : const Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: RpgSpacing.sm),

              // Level Badge
              LevelBadge(level: newLevel, compact: false),
              const SizedBox(height: RpgSpacing.md),

              // Rank Title
              Text(
                'Rank Unlocked: $rankTitle',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: RpgSpacing.sm),
              Text(
                'Your discipline strengthens your character. Keep conquering quests to ascend further!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: RpgSpacing.xl),

              // Continue Button
              RpgFilledButton(
                label: 'Continue Journey',
                icon: Icons.bolt_rounded,
                width: double.infinity,
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
