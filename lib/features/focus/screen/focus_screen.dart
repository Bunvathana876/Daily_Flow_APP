import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../habits/controllers/habit_controller.dart';
import '../../habits/models/habit.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  int _selectedPresetMinutes = 25;
  late int _totalSeconds;
  late int _remainingSeconds;
  bool _isRunning = false;
  Timer? _timer;
  int? _selectedHabitId;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _selectedPresetMinutes * 60;
    _remainingSeconds = _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    HapticFeedback.lightImpact();
    setState(() => _isRunning = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _onSessionComplete();
      }
    });
  }

  void _pauseTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _onSessionComplete() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalSeconds;
    });

    final habits = ref.read(habitControllerProvider);
    Habit? targetHabit;
    if (_selectedHabitId != null) {
      final index = habits.indexWhere((h) => h.id == _selectedHabitId);
      if (index != -1) targetHabit = habits[index];
    }

    if (targetHabit != null && !targetHabit.isCompletedToday) {
      ref
          .read(habitControllerProvider.notifier)
          .toggleHabitForToday(targetHabit);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Focus session complete! "${targetHabit.title}" checked off for today.',
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Focus session complete! Great job maintaining focus.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_selectedHabitId == null && habits.isNotEmpty) {
      final uncompleted = habits.where((h) => !h.isCompletedToday).toList();
      _selectedHabitId = uncompleted.isNotEmpty ? uncompleted.first.id : habits.first.id;
    }

    Habit? selectedHabit;
    if (_selectedHabitId != null) {
      final idx = habits.indexWhere((h) => h.id == _selectedHabitId);
      if (idx != -1) {
        selectedHabit = habits[idx];
      }
    }

    final activeColor = selectedHabit != null
        ? Color(selectedHabit.colorValue)
        : primaryColor;

    final progress = _totalSeconds > 0
        ? _remainingSeconds / _totalSeconds
        : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Focus Session',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            // Habit Selector Dropdown
            if (habits.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedHabit?.id,
                    isExpanded: true,
                    hint: const Text('Select Habit to Focus On'),
                    items: habits.map((h) {
                      return DropdownMenuItem<int>(
                        value: h.id,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(h.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                h.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (h.isCompletedToday)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: Color(0xFF10B981),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _isRunning
                        ? null
                        : (id) {
                            setState(() {
                              _selectedHabitId = id;
                            });
                          },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Duration Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: AppConstants.focusPresetsMinutes.map((mins) {
                  final isSelected = _selectedPresetMinutes == mins;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: ChoiceChip(
                      label: Text('$mins min'),
                      selected: isSelected,
                      onSelected: _isRunning
                          ? null
                          : (val) {
                              if (val) {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _selectedPresetMinutes = mins;
                                  _totalSeconds = mins * 60;
                                  _remainingSeconds = _totalSeconds;
                                });
                              }
                            },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Circular Countdown Display
            Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(_remainingSeconds),
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            selectedHabit != null
                                ? (_isRunning
                                    ? 'Focusing on ${selectedHabit.title}'
                                    : 'Ready to focus')
                                : 'General Focus',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Action Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh_rounded),
                  iconSize: 24,
                  tooltip: 'Reset Timer',
                ),
                const SizedBox(width: 20),
                FilledButton.icon(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  style: FilledButton.styleFrom(
                    backgroundColor: activeColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: Icon(
                    _isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isRunning ? 'Pause' : 'Start Focus',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

