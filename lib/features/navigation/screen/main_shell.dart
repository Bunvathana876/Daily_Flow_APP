import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/theme/rpg_colors.dart';
import '../../../core/theme/rpg_spacing.dart';
import '../../analytics/screen/stats_screen.dart';
import '../../focus/screen/focus_screen.dart';
import '../../habits/screen/home_screen.dart';
import '../../profile/screen/profile_screen.dart';

/// Main application shell with an Enchanted Navigation Dock.
/// Preserves IndexedStack state retention across tabs without resetting timers or scroll positions.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    StatsScreen(),
    FocusScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? RpgColors.softIndigo : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? RpgColors.cozyBorderDark
                  : RpgColors.rpgBorderLight,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: RpgColors.mutedViolet.withValues(
                alpha: isDark ? 0.30 : 0.16,
              ),
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RpgSpacing.radiusPill),
                side: BorderSide(
                  color: isDark
                      ? RpgColors.mutedViolet.withValues(alpha: 0.5)
                      : RpgColors.mutedViolet.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final isSelected = states.contains(WidgetState.selected);
                return TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.2,
                  color: isSelected
                      ? (isDark ? Colors.white : RpgColors.mutedViolet)
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final isSelected = states.contains(WidgetState.selected);
                return IconThemeData(
                  size: 22,
                  color: isSelected
                      ? (isDark ? RpgColors.warmGold : RpgColors.mutedViolet)
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                if (_selectedIndex != index) {
                  ref.read(hapticsServiceProvider).selectionClick();
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Today',
                  tooltip: "Today's Quests",
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Insights',
                  tooltip: 'Hall of Records',
                ),
                NavigationDestination(
                  icon: Icon(Icons.hourglass_top_rounded),
                  selectedIcon: Icon(Icons.hourglass_full_rounded),
                  label: 'Focus',
                  tooltip: 'Focus Chamber',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                  tooltip: "Hero's Armory",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
