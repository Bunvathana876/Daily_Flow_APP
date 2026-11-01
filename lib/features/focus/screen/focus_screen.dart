import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/theme/rpg_colors.dart';
import '../../../../core/theme/rpg_spacing.dart';
import '../../../../core/widgets/rpg_card.dart';
import '../../../../core/widgets/rpg_filled_button.dart';
import '../../../../core/widgets/rpg_gemstone_badge.dart';
import '../../gamification/controllers/gamification_controller.dart';
import '../../habits/controllers/habit_controller.dart';
import '../../habits/models/habit.dart';
import '../controllers/focus_timer_controller.dart';
import '../widgets/arcane_timer_ring.dart';
import '../widgets/focus_victory_dialog.dart';

/// Immersive fantasy RPG Arcane Focus Chamber.
/// Features celestial lighting, double-ring countdown, segmented fantasy mode tabs,
/// quest empowerment card, duration presets, and victory celebration triggers.
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref
          .read(focusTimerControllerProvider.notifier)
          .handleAppLifecycleResumed();
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return Icons.spa_rounded;
      case 'study':
        return Icons.auto_stories_rounded;
      case 'coding':
        return Icons.code_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'general':
      default:
        return Icons.shield_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(focusTimerControllerProvider);
    final timerController = ref.read(focusTimerControllerProvider.notifier);
    final habits = ref.watch(habitControllerProvider);
    final gamificationState = ref.watch(gamificationControllerProvider);
    final haptics = ref.read(hapticsServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    // Listen for session completion to present victory celebration modal exactly once
    ref.listen<FocusTimerState>(focusTimerControllerProvider, (prev, next) {
      if (next.isVictoryModalPending && mounted) {
        timerController.acknowledgeVictoryModal();
        haptics.questCompleted();
        FocusVictoryDialog.show(
          context,
          awardedXp: next.lastAwardedXp ?? 0,
          completedHabitTitle: next.lastCompletedHabitTitle,
          profile: gamificationState.profile,
        );
      }
    });

    // Auto-select first uncompleted habit if none selected
    if (timerState.selectedHabitId == null && habits.isNotEmpty) {
      final uncompleted = habits.where((h) => !h.isCompletedToday).toList();
      final defaultId = uncompleted.isNotEmpty
          ? uncompleted.first.id
          : habits.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) timerController.selectHabit(defaultId);
      });
    }

    Habit? selectedHabit;
    if (timerState.selectedHabitId != null) {
      final idx = habits.indexWhere((h) => h.id == timerState.selectedHabitId);
      if (idx != -1) {
        selectedHabit = habits[idx];
      }
    }

    final activeColor = selectedHabit != null
        ? Color(selectedHabit.colorValue)
        : primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 20,
              color: RpgColors.arcaneViolet,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Focus Session',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Ambient Celestial Violet Lighting
          if (isDark)
            AnimatedContainer(
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.1,
                  colors: [
                    activeColor.withValues(
                      alpha: timerState.isRunning ? 0.22 : 0.10,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

          // Scrollable Focus Chamber Content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 6.0,
            ),
            child: Column(
              children: [
                // 1. Segmented Fantasy Mode Selector Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? RpgColors.rpgSurfaceDark
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(RpgSpacing.radiusPill),
                    border: Border.all(
                      color: isDark
                          ? RpgColors.rpgBorderDark
                          : RpgColors.rpgBorderLight,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.25 : 0.04,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildModeTab(
                        context: context,
                        label: 'Focus Trial',
                        icon: Icons.bolt_rounded,
                        mode: FocusMode.focus,
                        currentMode: timerState.mode,
                        activeColor: activeColor,
                        onTap: () {
                          haptics.selectionClick();
                          timerController.setMode(FocusMode.focus);
                        },
                      ),
                      _buildModeTab(
                        context: context,
                        label: 'Short Rest',
                        icon: Icons.coffee_rounded,
                        mode: FocusMode.shortBreak,
                        currentMode: timerState.mode,
                        activeColor: RpgColors.questEmerald,
                        onTap: () {
                          haptics.selectionClick();
                          timerController.setMode(FocusMode.shortBreak);
                        },
                      ),
                      _buildModeTab(
                        context: context,
                        label: 'Deep Rest',
                        icon: Icons.spa_rounded,
                        mode: FocusMode.longBreak,
                        currentMode: timerState.mode,
                        activeColor: RpgColors.rpgCyan,
                        onTap: () {
                          haptics.selectionClick();
                          timerController.setMode(FocusMode.longBreak);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Quest Empowerment Panel (Focus Mode Only)
                if (timerState.mode == FocusMode.focus &&
                    habits.isNotEmpty) ...[
                  RpgCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    variant: RpgCardVariant.standard,
                    showCornerAccents: true,
                    borderColor: isDark
                        ? activeColor.withValues(alpha: 0.4)
                        : RpgColors.rpgBorderLight,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedHabit?.id,
                        isExpanded: true,
                        hint: const Text(
                          'Select Quest to Empower',
                          style: TextStyle(fontSize: 13),
                        ),
                        icon: Icon(
                          timerState.isRunning
                              ? Icons.lock_outline_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: isDark
                              ? RpgColors.arcaneVioletLight
                              : RpgColors.arcaneViolet,
                        ),
                        items: habits.map((h) {
                          final hColor = Color(h.colorValue);
                          final isCompleted = h.isCompletedToday;
                          return DropdownMenuItem<int>(
                            value: h.id,
                            child: Row(
                              children: [
                                RpgGemstoneBadge(
                                  label: h.category.toUpperCase(),
                                  icon: _getCategoryIcon(h.category),
                                  color: hColor,
                                  compact: true,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    h.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: isCompleted
                                          ? (isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600)
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black87),
                                    ),
                                  ),
                                ),
                                if (isCompleted)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: RpgColors.questEmerald,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: timerState.isRunning
                            ? null
                            : (id) {
                                haptics.selectionClick();
                                timerController.selectHabit(id);
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 3. Duration Presets (15 min, 25 min, 45 min, 60 min)
                if (timerState.mode == FocusMode.focus) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: AppConstants.focusPresetsMinutes.map((mins) {
                        final isSelected =
                            timerState.selectedPresetMinutes == mins;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text('$mins min'),
                            selected: isSelected,
                            selectedColor: isDark
                                ? RpgColors.arcaneViolet.withValues(alpha: 0.35)
                                : RpgColors.arcaneViolet.withValues(
                                    alpha: 0.16,
                                  ),
                            checkmarkColor: isDark
                                ? RpgColors.rpgGold
                                : RpgColors.arcaneViolet,
                            labelStyle: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 12.5,
                              color: isSelected
                                  ? (isDark
                                        ? Colors.white
                                        : RpgColors.arcaneViolet)
                                  : (isDark
                                        ? Colors.grey.shade300
                                        : Colors.black87),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected
                                    ? (isDark
                                          ? RpgColors.rpgGold.withValues(
                                              alpha: 0.6,
                                            )
                                          : RpgColors.arcaneViolet)
                                    : (isDark
                                          ? Colors.white12
                                          : Colors.grey.shade300),
                                width: isSelected ? 1.4 : 1.0,
                              ),
                            ),
                            onSelected: timerState.isRunning
                                ? null
                                : (val) {
                                    if (val) {
                                      haptics.lightImpact();
                                      timerController.setPresetMinutes(mins);
                                    }
                                  },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  const SizedBox(height: 10),
                ],

                // 4. Arcane Countdown Ring Display
                ArcaneTimerRing(
                  remainingDuration: timerState.remainingDuration,
                  totalDuration: timerState.totalDuration,
                  progressRatio: timerState.progressRatio,
                  isRunning: timerState.isRunning,
                  isPaused: timerState.isPaused,
                  mode: timerState.mode,
                  activeColor: activeColor,
                  habitTitle: selectedHabit?.title,
                  presetMinutes: timerState.selectedPresetMinutes,
                ),
                const SizedBox(height: 24),

                // 5. Action Controls: Reset Button + Primary Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Reset Button with tooltip 'Reset Timer'
                    IconButton(
                      tooltip: 'Reset Timer',
                      onPressed: () {
                        haptics.lightImpact();
                        timerController.resetTimer();
                      },
                      icon: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? RpgColors.rpgSurfaceDark
                              : Colors.grey.shade100,
                          border: Border.all(
                            color: isDark
                                ? RpgColors.rpgBorderDark
                                : RpgColors.rpgBorderLight,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.3 : 0.05,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 22,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Primary Action Button: Start Focus vs. Pause
                    Flexible(
                      child: RpgFilledButton(
                        label: timerState.isRunning ? 'Pause' : 'Start Focus',
                        icon: timerState.isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        backgroundColor: activeColor,
                        height: 50,
                        onPressed: () {
                          if (timerState.isRunning) {
                            haptics.lightImpact();
                            timerController.pauseTimer();
                          } else {
                            haptics.mediumImpact();
                            timerController.startTimer();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required BuildContext context,
    required String label,
    required IconData icon,
    required FocusMode mode,
    required FocusMode currentMode,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == currentMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '$label mode',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: isDark ? 0.28 : 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(RpgSpacing.radiusPill),
              border: Border.all(
                color: isSelected ? activeColor : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(
                          alpha: isDark ? 0.3 : 0.15,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? activeColor
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : activeColor)
                          : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
