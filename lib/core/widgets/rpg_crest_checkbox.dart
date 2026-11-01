import 'package:flutter/material.dart';
import '../theme/rpg_colors.dart';
import '../theme/rpg_spacing.dart';

/// Interactive fantasy crest / shield checkmark for one-tap habit completion.
/// Features a tactile micro-bounce animation, glowing completed state,
/// and guaranteed 48x48 logical pixel minimum touch target bounds.
class RpgCrestCheckbox extends StatefulWidget {
  final bool isCompleted;
  final ValueChanged<bool>? onChanged;
  final Color gemColor;
  final double size;
  final double minTouchTarget;
  final String? tooltip;

  const RpgCrestCheckbox({
    super.key,
    required this.isCompleted,
    this.onChanged,
    this.gemColor = RpgColors.rpgEmerald,
    this.size = 28.0,
    this.minTouchTarget = RpgSpacing.minTouchTarget,
    this.tooltip,
  });

  @override
  State<RpgCrestCheckbox> createState() => _RpgCrestCheckboxState();
}

class _RpgCrestCheckboxState extends State<RpgCrestCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    // Micro-bounce: 1.0 -> 1.22 -> 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.22,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.22,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticIn)),
        weight: 55,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(covariant RpgCrestCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted && widget.isCompleted) {
      final disableAnimations =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (!disableAnimations) {
        _bounceController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onChanged == null) return;
    final nextState = !widget.isCompleted;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (nextState && !disableAnimations) {
      _bounceController.forward(from: 0.0);
    }
    widget.onChanged!(nextState);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final targetSize = widget.size;
    final isDone = widget.isCompleted;

    // Outer shield color & fill
    final shieldBg = isDone
        ? widget.gemColor
        : (isDark ? RpgColors.rpgDungeonSlate : Colors.grey.shade100);
    final borderColor = isDone
        ? widget.gemColor
        : (isDark ? RpgColors.rpgBorderDark : RpgColors.rpgBorderLight);

    Widget crestVisual = AnimatedContainer(
      duration: disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: targetSize,
      height: targetSize,
      decoration: BoxDecoration(
        color: shieldBg,
        borderRadius: BorderRadius.circular(targetSize * 0.32),
        border: Border.all(color: borderColor, width: isDone ? 1.8 : 1.4),
        boxShadow: isDone
            ? [
                BoxShadow(
                  color: widget.gemColor.withValues(
                    alpha: isDark ? 0.45 : 0.25,
                  ),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: isDone
              ? Icon(
                  Icons.check_rounded,
                  key: const ValueKey('checked_icon'),
                  color: Colors.white,
                  size: targetSize * 0.65,
                )
              : Icon(
                  Icons.shield_outlined,
                  key: const ValueKey('unchecked_icon'),
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  size: targetSize * 0.52,
                ),
        ),
      ),
    );

    // Apply bounce animation when active
    if (!disableAnimations) {
      crestVisual = ScaleTransition(scale: _scaleAnimation, child: crestVisual);
    }

    Widget interactiveWidget = SizedBox(
      width: widget.minTouchTarget,
      height: widget.minTouchTarget,
      child: GestureDetector(
        onTap: widget.onChanged != null ? _handleTap : null,
        behavior: HitTestBehavior.opaque,
        child: Center(child: crestVisual),
      ),
    );

    if (widget.tooltip != null) {
      interactiveWidget = Tooltip(
        message: widget.tooltip!,
        child: interactiveWidget,
      );
    }

    return interactiveWidget;
  }
}
