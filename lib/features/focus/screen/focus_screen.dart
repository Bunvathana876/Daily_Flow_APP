import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/theme/cozy_artwork.dart';
import '../../../../core/theme/rpg_colors.dart';
import '../../../../core/theme/rpg_spacing.dart';
import '../../../../core/widgets/cozy_background.dart';
import '../../../../core/widgets/rpg_gemstone_badge.dart';
import '../../gamification/controllers/gamification_controller.dart';
import '../../habits/controllers/habit_controller.dart';
import '../../habits/models/habit.dart';
import '../controllers/focus_timer_controller.dart';
import '../widgets/arcane_timer_ring.dart';
import '../widgets/focus_victory_dialog.dart';

/// Cozy Adventure RPG Focus Chamber Screen.
/// Features the peaceful illustrated focus room background,
/// atmospheric arched window view, soft twilight lighting,
/// large magical countdown timer, linked quest card, and tactile action controls.
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

    return CozyBackgroundScaffold.focusChamber(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark
                    ? RpgColors.mutedViolet.withValues(alpha: 0.28)
                    : RpgColors.rpgIndigo.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 18,
                color: RpgColors.arcaneViolet,
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Focus Session',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          children: [
            // 1. Mode Selector Tabs: Focus Trial | Short Rest | Deep Rest
            Container(
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: isDark
                    ? RpgColors.softIndigo.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(RpgSpacing.radiusPill),
                border: Border.all(
                  color: isDark
                      ? RpgColors.cozyBorderDark
                      : RpgColors.rpgBorderLight,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
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
                    activeColor: RpgColors.arcaneViolet,
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
            const SizedBox(height: 8),

            // 2. Duration Presets (15 min, 25 min, 45 min, 60 min) - Focus Mode Only
            if (timerState.mode == FocusMode.focus) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: AppConstants.focusPresetsMinutes.map((mins) {
                    final isSelected = timerState.selectedPresetMinutes == mins;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text('$mins min'),
                        selected: isSelected,
                        selectedColor: isDark
                            ? RpgColors.arcaneViolet.withValues(alpha: 0.35)
                            : RpgColors.arcaneViolet.withValues(alpha: 0.16),
                        checkmarkColor: isDark
                            ? RpgColors.warmGold
                            : RpgColors.arcaneViolet,
                        labelStyle: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 12.0,
                          color: isSelected
                              ? (isDark ? Colors.white : RpgColors.arcaneViolet)
                              : (isDark
                                    ? Colors.grey.shade300
                                    : Colors.black87),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected
                                ? (isDark
                                      ? RpgColors.warmGold.withValues(
                                          alpha: 0.6,
                                        )
                                      : RpgColors.arcaneViolet)
                                : (isDark
                                      ? RpgColors.cozyBorderDark
                                      : Colors.grey.shade300),
                            width: isSelected ? 1.2 : 0.8,
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
              const SizedBox(height: 10),
            ] else ...[
              const SizedBox(height: 6),
            ],

            // 3. Magical Arcane Timer Ring
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
            const SizedBox(height: 14),

            // 4. Linked Quest Card (Focus Mode) / Sanctuary Rest Card (Rest Mode)
            if (timerState.mode == FocusMode.focus && habits.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141A33) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? RpgColors.warmGold.withValues(alpha: 0.35)
                        : RpgColors.warmGold.withValues(alpha: 0.45),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.35 : 0.06,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Quest Journal Icon
                    CozyArtwork.questJournal(size: 38),
                    const SizedBox(width: 12),

                    // Middle Information & Habit Selector
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'LINKED QUEST',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? RpgColors.warmGold
                                  : const Color(0xFFB45309),
                            ),
                          ),
                          const SizedBox(height: 1),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedHabit?.id,
                              isExpanded: true,
                              isDense: true,
                              hint: const Text(
                                'Select Quest to Empower',
                                style: TextStyle(fontSize: 13),
                              ),
                              icon: Icon(
                                timerState.isRunning
                                    ? Icons.lock_outline_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: isDark
                                    ? RpgColors.warmGold
                                    : const Color(0xFFB45309),
                              ),
                              selectedItemBuilder: (context) {
                                return habits.map((h) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      h.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14.0,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E2447),
                                      ),
                                    ),
                                  );
                                }).toList();
                              },
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
                                            fontSize: 13,
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
                          const SizedBox(height: 1),
                          Text(
                            selectedHabit != null
                                ? 'Complete 1 focus session • ${selectedHabit.category}'
                                : 'Select a quest to empower today',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Status indicator pill (0 / 1 or Check)
                    if (selectedHabit != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: selectedHabit.isCompletedToday
                              ? RpgColors.questEmerald.withValues(
                                  alpha: isDark ? 0.25 : 0.15,
                                )
                              : (isDark
                                    ? const Color(0xFF1E2648)
                                    : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedHabit.isCompletedToday
                                ? RpgColors.questEmerald.withValues(alpha: 0.6)
                                : (isDark
                                      ? RpgColors.warmGold.withValues(
                                          alpha: 0.35,
                                        )
                                      : Colors.grey.shade400),
                            width: 0.8,
                          ),
                        ),
                        child: selectedHabit.isCompletedToday
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: RpgColors.questEmerald,
                              )
                            : Text(
                                '0/1',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? RpgColors.warmGold
                                      : const Color(0xFF1E2447),
                                ),
                              ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (timerState.mode != FocusMode.focus) ...[
              // Sanctuary Rest Information Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF141A33).withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? (timerState.mode == FocusMode.shortBreak
                              ? RpgColors.questEmerald.withValues(alpha: 0.35)
                              : RpgColors.rpgCyan.withValues(alpha: 0.35))
                        : (timerState.mode == FocusMode.shortBreak
                              ? RpgColors.questEmerald.withValues(alpha: 0.45)
                              : RpgColors.rpgCyan.withValues(alpha: 0.45)),
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
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            (timerState.mode == FocusMode.shortBreak
                                    ? RpgColors.questEmerald
                                    : RpgColors.rpgCyan)
                                .withValues(alpha: isDark ? 0.20 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        timerState.mode == FocusMode.shortBreak
                            ? Icons.coffee_rounded
                            : Icons.spa_rounded,
                        size: 18,
                        color: timerState.mode == FocusMode.shortBreak
                            ? RpgColors.questEmerald
                            : RpgColors.rpgCyan,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timerState.mode == FocusMode.shortBreak
                                ? 'Short Rest Sanctuary'
                                : 'Deep Rest Sanctuary',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E2447),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Breathe, sip water, and gaze out the window. Recharging for your next trial.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const SizedBox(height: 12),
            ],

            // 5. Action Controls: Reset Button + Cozy Gold Primary Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset Button with tooltip 'Reset Timer' (48x48 touch target)
                Semantics(
                  button: true,
                  label: 'Reset Timer',
                  child: Tooltip(
                    message: 'Reset Timer',
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          haptics.lightImpact();
                          timerController.resetTimer();
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? RpgColors.softIndigo.withValues(alpha: 0.90)
                                : Colors.white.withValues(alpha: 0.92),
                            border: Border.all(
                              color: isDark
                                  ? RpgColors.cozyBorderDark
                                  : RpgColors.rpgBorderLight,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.30 : 0.06,
                                ),
                                blurRadius: 8,
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
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Primary Action Button: Start Focus / Start Rest vs. Pause
                Expanded(
                  child: Semantics(
                    button: true,
                    label: timerState.isRunning
                        ? (timerState.mode == FocusMode.focus
                              ? 'Pause Focus Timer'
                              : 'Pause Rest Timer')
                        : (timerState.mode == FocusMode.focus
                              ? 'Start Focus Timer'
                              : 'Start Rest Timer'),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: RpgColors.cozyGoldGradient,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? RpgColors.rpgGoldGlint.withValues(alpha: 0.35)
                              : RpgColors.warmGold.withValues(alpha: 0.45),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: RpgColors.warmGold.withValues(
                              alpha: isDark ? 0.22 : 0.15,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.25 : 0.06,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            if (timerState.isRunning) {
                              haptics.lightImpact();
                              timerController.pauseTimer();
                            } else {
                              haptics.mediumImpact();
                              timerController.startTimer();
                            }
                          },
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  timerState.isRunning
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 22,
                                  color: const Color(0xFF2B1602),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  timerState.isRunning
                                      ? 'Pause'
                                      : (timerState.mode == FocusMode.focus
                                            ? 'Start Focus'
                                            : 'Start Rest'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2B1602),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
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
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: isDark ? 0.28 : 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(RpgSpacing.radiusPill),
              border: Border.all(
                color: isSelected
                    ? (isDark ? RpgColors.warmGold : activeColor)
                    : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(
                          alpha: isDark ? 0.25 : 0.12,
                        ),
                        blurRadius: 6,
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
                      ? (isDark ? RpgColors.warmGold : activeColor)
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
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
