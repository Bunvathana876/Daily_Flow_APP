import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/controllers/settings_controller.dart';

typedef HapticCallback = Future<void> Function();

/// Centralized haptics service that respects global user settings.
class HapticsService {
  final Ref? _ref;
  final bool Function()? _isEnabledOverride;
  final HapticCallback? _onLightImpact;
  final HapticCallback? _onMediumImpact;
  final HapticCallback? _onHeavyImpact;
  final HapticCallback? _onSelectionClick;

  const HapticsService({
    Ref? ref,
    bool Function()? isEnabledOverride,
    HapticCallback? onLightImpact,
    HapticCallback? onMediumImpact,
    HapticCallback? onHeavyImpact,
    HapticCallback? onSelectionClick,
  }) : _ref = ref,
       _isEnabledOverride = isEnabledOverride,
       _onLightImpact = onLightImpact,
       _onMediumImpact = onMediumImpact,
       _onHeavyImpact = onHeavyImpact,
       _onSelectionClick = onSelectionClick;

  bool get isEnabled {
    if (_isEnabledOverride != null) return _isEnabledOverride();
    if (_ref != null) {
      return _ref.read(settingsControllerProvider).hapticsEnabled;
    }
    return true;
  }

  Future<void> lightImpact() async {
    if (!isEnabled) return;
    if (_onLightImpact != null) {
      await _onLightImpact();
    } else {
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> mediumImpact() async {
    if (!isEnabled) return;
    if (_onMediumImpact != null) {
      await _onMediumImpact();
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> heavyImpact() async {
    if (!isEnabled) return;
    if (_onHeavyImpact != null) {
      await _onHeavyImpact();
    } else {
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> selectionClick() async {
    if (!isEnabled) return;
    if (_onSelectionClick != null) {
      await _onSelectionClick();
    } else {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> questCompleted() => mediumImpact();

  Future<void> levelUp() => heavyImpact();

  Future<void> achievementUnlocked() async {
    if (!isEnabled) return;
    await mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await selectionClick();
  }

  Future<void> milestoneReached() async {
    if (!isEnabled) return;
    await lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await mediumImpact();
  }

  Future<void> focusVictory() => heavyImpact();
}

final hapticsServiceProvider = Provider<HapticsService>((ref) {
  return HapticsService(ref: ref);
});
