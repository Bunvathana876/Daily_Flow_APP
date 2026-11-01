import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../gamification/controllers/gamification_controller.dart';
import '../../habits/controllers/habit_controller.dart';

enum FocusMode { focus, shortBreak, longBreak }

enum FocusTimerStatus { initial, running, paused, completed }

class FocusTimerState {
  final FocusMode mode;
  final int selectedPresetMinutes;
  final Duration totalDuration;
  final Duration remainingDuration;
  final DateTime? targetEndTime;
  final FocusTimerStatus status;
  final int? selectedHabitId;
  final int? lastAwardedXp;
  final String? lastCompletedHabitTitle;
  final bool isVictoryModalPending;

  const FocusTimerState({
    this.mode = FocusMode.focus,
    this.selectedPresetMinutes = 25,
    this.totalDuration = const Duration(minutes: 25),
    this.remainingDuration = const Duration(minutes: 25),
    this.targetEndTime,
    this.status = FocusTimerStatus.initial,
    this.selectedHabitId,
    this.lastAwardedXp,
    this.lastCompletedHabitTitle,
    this.isVictoryModalPending = false,
  });

  bool get isRunning => status == FocusTimerStatus.running;
  bool get isPaused => status == FocusTimerStatus.paused;
  bool get isInitial => status == FocusTimerStatus.initial;
  bool get isCompleted => status == FocusTimerStatus.completed;

  double get progressRatio {
    if (totalDuration.inSeconds <= 0) return 0.0;
    final ratio = remainingDuration.inSeconds / totalDuration.inSeconds;
    return ratio.clamp(0.0, 1.0);
  }

  FocusTimerState copyWith({
    FocusMode? mode,
    int? selectedPresetMinutes,
    Duration? totalDuration,
    Duration? remainingDuration,
    DateTime? targetEndTime,
    bool clearTargetEndTime = false,
    FocusTimerStatus? status,
    int? selectedHabitId,
    bool clearSelectedHabit = false,
    int? lastAwardedXp,
    String? lastCompletedHabitTitle,
    bool? isVictoryModalPending,
  }) {
    return FocusTimerState(
      mode: mode ?? this.mode,
      selectedPresetMinutes:
          selectedPresetMinutes ?? this.selectedPresetMinutes,
      totalDuration: totalDuration ?? this.totalDuration,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      targetEndTime: clearTargetEndTime
          ? null
          : (targetEndTime ?? this.targetEndTime),
      status: status ?? this.status,
      selectedHabitId: clearSelectedHabit
          ? null
          : (selectedHabitId ?? this.selectedHabitId),
      lastAwardedXp: lastAwardedXp ?? this.lastAwardedXp,
      lastCompletedHabitTitle:
          lastCompletedHabitTitle ?? this.lastCompletedHabitTitle,
      isVictoryModalPending:
          isVictoryModalPending ?? this.isVictoryModalPending,
    );
  }
}

final focusClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class FocusTimerController extends Notifier<FocusTimerState> {
  Timer? _ticker;

  @override
  FocusTimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const FocusTimerState();
  }

  DateTime Function() get _now => ref.read(focusClockProvider);

  void setMode(FocusMode mode) {
    if (state.isRunning) return;
    int minutes;
    switch (mode) {
      case FocusMode.focus:
        minutes = 25;
        break;
      case FocusMode.shortBreak:
        minutes = 5;
        break;
      case FocusMode.longBreak:
        minutes = 15;
        break;
    }
    final duration = Duration(minutes: minutes);
    state = state.copyWith(
      mode: mode,
      selectedPresetMinutes: minutes,
      totalDuration: duration,
      remainingDuration: duration,
      status: FocusTimerStatus.initial,
      clearTargetEndTime: true,
      isVictoryModalPending: false,
    );
  }

  void setPresetMinutes(int minutes) {
    if (state.isRunning) return;
    final duration = Duration(minutes: minutes);
    state = state.copyWith(
      selectedPresetMinutes: minutes,
      totalDuration: duration,
      remainingDuration: duration,
      status: FocusTimerStatus.initial,
      clearTargetEndTime: true,
      isVictoryModalPending: false,
    );
  }

  void selectHabit(int? habitId) {
    state = state.copyWith(
      selectedHabitId: habitId,
      clearSelectedHabit: habitId == null,
    );
  }

  void startTimer() {
    if (state.isRunning) return;

    final Duration startRemaining;
    if (state.isCompleted || state.isInitial) {
      startRemaining = state.totalDuration;
    } else {
      startRemaining = state.remainingDuration;
    }

    final targetEnd = _now().add(startRemaining);

    state = state.copyWith(
      status: FocusTimerStatus.running,
      remainingDuration: startRemaining,
      targetEndTime: targetEnd,
      isVictoryModalPending: false,
    );

    _startTicker();
  }

  void pauseTimer() {
    if (!state.isRunning) return;
    _ticker?.cancel();

    final remaining = _calculateRemaining();

    state = state.copyWith(
      status: FocusTimerStatus.paused,
      remainingDuration: remaining,
      clearTargetEndTime: true,
    );
  }

  void resumeTimer() {
    startTimer();
  }

  void resetTimer() {
    _ticker?.cancel();
    state = state.copyWith(
      status: FocusTimerStatus.initial,
      remainingDuration: state.totalDuration,
      clearTargetEndTime: true,
      isVictoryModalPending: false,
    );
  }

  Future<void> handleAppLifecycleResumed() async {
    if (!state.isRunning) return;
    await _syncClockTick();
  }

  void acknowledgeVictoryModal() {
    state = state.copyWith(isVictoryModalPending: false);
  }

  Duration _calculateRemaining() {
    if (state.targetEndTime == null) return state.remainingDuration;
    final diff = state.targetEndTime!.difference(_now());
    if (diff <= Duration.zero) return Duration.zero;
    if (diff > state.totalDuration) return state.totalDuration;
    return diff;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 300), (_) {
      _syncClockTick();
    });
  }

  Future<void> _syncClockTick() async {
    if (!state.isRunning) return;

    final remaining = _calculateRemaining();

    if (remaining <= Duration.zero) {
      _ticker?.cancel();
      await _completeSession();
    } else {
      if (ref.mounted) {
        state = state.copyWith(remainingDuration: remaining);
      }
    }
  }

  Future<void> _completeSession() async {
    if (state.isCompleted) return;

    final completedMode = state.mode;
    final durationMinutes = state.selectedPresetMinutes;
    final habitId = state.selectedHabitId;

    int awardedXp = 0;
    String? habitTitle;

    if (completedMode == FocusMode.focus) {
      // 1. Award focus session XP through GamificationController
      try {
        awardedXp = await ref
            .read(gamificationControllerProvider.notifier)
            .awardFocusSession(
              durationMinutes: durationMinutes,
              habitId: habitId,
              dateStr: AppDateUtils.todayString,
            );
      } catch (_) {}

      // 2. Auto-check off linked habit if selected and not yet completed
      if (habitId != null) {
        final habits = ref.read(habitControllerProvider);
        final matchIndex = habits.indexWhere((h) => h.id == habitId);
        if (matchIndex != -1) {
          final habit = habits[matchIndex];
          habitTitle = habit.title;
          if (!habit.isCompletedToday) {
            await ref
                .read(habitControllerProvider.notifier)
                .toggleHabitForToday(habit);
          }
        }
      }
    }

    if (!ref.mounted) return;
    state = state.copyWith(
      status: FocusTimerStatus.completed,
      remainingDuration: Duration.zero,
      clearTargetEndTime: true,
      lastAwardedXp: awardedXp,
      lastCompletedHabitTitle: habitTitle,
      isVictoryModalPending: true,
    );
  }
}

final focusTimerControllerProvider =
    NotifierProvider<FocusTimerController, FocusTimerState>(
      FocusTimerController.new,
    );
