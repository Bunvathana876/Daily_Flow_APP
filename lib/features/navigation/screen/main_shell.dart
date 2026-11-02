import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/theme/rpg_colors.dart';
import '../../analytics/screen/stats_screen.dart';
import '../../focus/screen/focus_screen.dart';
import '../../habits/controllers/habit_controller.dart';
import '../../habits/screen/home_screen.dart';
import '../../habits/screen/widgets/quest_form_sheet.dart';
import '../../profile/screen/profile_screen.dart';

/// Navigation item model describing tab destination metadata.
class _NavDestinationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String tooltip;

  const _NavDestinationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.tooltip,
  });
}

/// Notifier controlling the active bottom navigation tab in MainShell.
class MainShellTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) {
    if (index >= 0 && index < 4) {
      state = index;
    }
  }
}

final mainShellTabProvider = NotifierProvider<MainShellTabNotifier, int>(
  MainShellTabNotifier.new,
);

/// Main application shell with an iOS-inspired Floating Liquid Glass Navigation Dock.
///
/// Features:
/// - Floating capsule/pill dock above bottom safe area with frosted glass effect.
/// - Midnight navy and soft violet translucent palette with subtle borders.
/// - Smooth 180-200ms selection transitions and warm gold active accents.
/// - Optional separate circular frosted-glass Action Button for quick quest creation.
/// - Preserves IndexedStack state retention across tabs (timer, scroll positions).
/// - Resilient 320px responsive layout, 2.0x text scaling, and reduced motion.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final List<Widget> _screens = const [
    HomeScreen(),
    StatsScreen(),
    FocusScreen(),
    ProfileScreen(),
  ];

  static const List<_NavDestinationItem> _destinations = [
    _NavDestinationItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Today',
      tooltip: "Today's Quests",
    ),
    _NavDestinationItem(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      label: 'Insights',
      tooltip: 'Hall of Records',
    ),
    _NavDestinationItem(
      icon: Icons.hourglass_top_rounded,
      selectedIcon: Icons.hourglass_full_rounded,
      label: 'Focus',
      tooltip: 'Focus Chamber',
    ),
    _NavDestinationItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
      tooltip: "Hero's Armory",
    ),
  ];

  void _onTabSelected(int index) {
    final current = ref.read(mainShellTabProvider);
    if (current != index) {
      ref.read(hapticsServiceProvider).selectionClick();
      ref.read(mainShellTabProvider.notifier).selectTab(index);
    }
  }

  void _openNewQuestForm() {
    ref.read(hapticsServiceProvider).mediumImpact();
    QuestFormSheet.show(
      context,
      onSave: (title, category, colorValue) {
        ref
            .read(habitControllerProvider.notifier)
            .addHabit(title, category: category, colorValue: colorValue);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final keyboardVisible = mediaQuery.viewInsets.bottom > 0;
    final reduceMotion = mediaQuery.disableAnimations;
    final selectedIndex = ref.watch(mainShellTabProvider);

    // Show optional separate FAB only when layout width supports it safely (>= 370px),
    // and only on secondary tabs (Insights & Profile).
    // On HomeScreen, HomeScreen already has its own prominent "New Quest" button.
    // On FocusScreen, we avoid obstructing focus session timer controls.
    final showQuickAddFab =
        !keyboardVisible &&
        screenWidth >= 370.0 &&
        (selectedIndex == 1 || selectedIndex == 3);

    return Scaffold(
      backgroundColor: isDark
          ? RpgColors.midnightNavy
          : theme.scaffoldBackgroundColor,
      body: IndexedStack(index: selectedIndex, children: _screens),
      bottomNavigationBar: keyboardVisible
          ? const SizedBox.shrink()
          : SafeArea(
              top: false,
              maintainBottomViewPadding: true,
              child: Padding(
                padding: EdgeInsets.only(
                  left: screenWidth < 360 ? 8.0 : 16.0,
                  right: screenWidth < 360 ? 8.0 : 16.0,
                  bottom: 8.0,
                  top: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Floating Liquid Glass Navigation Dock
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: _LiquidGlassDock(
                          selectedIndex: selectedIndex,
                          destinations: _destinations,
                          onDestinationSelected: _onTabSelected,
                          isDark: isDark,
                          reduceMotion: reduceMotion,
                        ),
                      ),
                    ),

                    // Optional Separate Circular Action Button
                    if (showQuickAddFab) ...[
                      const SizedBox(width: 10),
                      _LiquidGlassFab(onTap: _openNewQuestForm, isDark: isDark),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

/// Floating capsule-shaped Liquid Glass Navigation Dock.
class _LiquidGlassDock extends StatelessWidget {
  final int selectedIndex;
  final List<_NavDestinationItem> destinations;
  final ValueChanged<int> onDestinationSelected;
  final bool isDark;
  final bool reduceMotion;

  const _LiquidGlassDock({
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.isDark,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    const pillRadius = BorderRadius.all(Radius.circular(30));

    return Container(
      decoration: BoxDecoration(
        borderRadius: pillRadius,
        boxShadow: [
          // Deep ambient drop shadow for floating elevation
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.22),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
          // Subtle soft violet ambient glow
          BoxShadow(
            color: const Color(
              0xFF8B5CF6,
            ).withValues(alpha: isDark ? 0.08 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: pillRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58, maxHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              // Dark translucent liquid glass surface
              color: isDark
                  ? const Color(0xFF0D1427).withValues(alpha: 0.82)
                  : const Color(0xFF141C38).withValues(alpha: 0.86),
              borderRadius: pillRadius,
              // Thin soft translucent border
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.16),
                width: 1.0,
              ),
              // Gentle inner highlight gradient
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.09 : 0.12),
                  Colors.white.withValues(alpha: 0.01),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(destinations.length, (index) {
                final item = destinations[index];
                final isSelected = selectedIndex == index;

                return Expanded(
                  child: _LiquidGlassNavItem(
                    item: item,
                    isSelected: isSelected,
                    onTap: () => onDestinationSelected(index),
                    isDark: isDark,
                    reduceMotion: reduceMotion,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual item inside the liquid glass dock with minimum 48x48 tap target
/// and smooth animated selection pill.
class _LiquidGlassNavItem extends StatelessWidget {
  final _NavDestinationItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final bool reduceMotion;

  const _LiquidGlassNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final animDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 190);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${item.label} tab',
      tooltip: item.tooltip,
      child: Tooltip(
        message: item.tooltip,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color(0xFF8B5CF6).withValues(alpha: 0.20),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: AnimatedContainer(
                duration: animDuration,
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  // Subtle translucent rounded active background pill
                  color: isSelected
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? RpgColors.warmGold.withValues(alpha: 0.35)
                        : Colors.transparent,
                    width: 0.9,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    AnimatedSwitcher(
                      duration: animDuration,
                      child: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        key: ValueKey<bool>(isSelected),
                        size: 21,
                        color: isSelected
                            ? RpgColors.warmGold
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Small readable label
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          letterSpacing: 0.2,
                          color: isSelected
                              ? const Color(0xFFFBF8EE)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Separate circular floating action button in matching dark frosted glass style.
class _LiquidGlassFab extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _LiquidGlassFab({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New Quest',
      tooltip: 'Create New Quest',
      child: Tooltip(
        message: 'New Quest',
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.22),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: RpgColors.warmGold.withValues(
                  alpha: isDark ? 0.16 : 0.10,
                ),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  splashColor: RpgColors.warmGold.withValues(alpha: 0.25),
                  highlightColor: Colors.white.withValues(alpha: 0.08),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF0D1427).withValues(alpha: 0.82)
                          : const Color(0xFF141C38).withValues(alpha: 0.86),
                      border: Border.all(
                        color: RpgColors.warmGold.withValues(
                          alpha: isDark ? 0.35 : 0.45,
                        ),
                        width: 1.0,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: isDark ? 0.12 : 0.16),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: RpgColors.warmGold,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
