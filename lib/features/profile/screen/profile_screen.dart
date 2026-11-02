import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/theme/rpg_colors.dart';
import '../../../core/theme/rpg_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/kpi_stat_card.dart';
import '../../../core/widgets/level_badge.dart';
import '../../../core/widgets/rpg_card.dart';
import '../../../core/widgets/xp_progress_bar.dart';
import '../../gamification/controllers/gamification_controller.dart';
import '../../gamification/models/hero_rank_tier.dart';
import '../../gamification/widgets/hero_avatar_badge.dart';
import '../../habits/controllers/habit_controller.dart';
import '../../settings/screen/settings_screen.dart';
import '../widgets/achievement_badge_tile.dart';
import '../widgets/hero_customization_dialog.dart';

/// Epic Hero's Armory & Profile Screen.
/// Displays dynamic hero progression, rank-based decorative frames,
/// verified KPI achievements, and illuminated trophy collection.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _selectedPathFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final habits = ref.read(habitControllerProvider);
        ref
            .read(gamificationControllerProvider.notifier)
            .evaluateAchievements(habits: habits);
      }
    });
  }

  void _openCustomizationDialog(String name, String avatarId) {
    ref.read(hapticsServiceProvider).selectionClick();
    HeroCustomizationDialog.show(
      context,
      currentName: name,
      currentAvatarId: avatarId,
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return Icons.bookmark_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'study':
        return Icons.auto_stories_rounded;
      case 'coding':
        return Icons.code_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return RpgColors.arcaneViolet;
      case 'health':
        return RpgColors.questEmerald;
      case 'study':
        return const Color(0xFF38BDF8);
      case 'coding':
        return RpgColors.rpgIndigo;
      case 'fitness':
        return Colors.deepOrange;
      default:
        return RpgColors.rpgGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habits = ref.watch(habitControllerProvider);
    final gamificationState = ref.watch(gamificationControllerProvider);
    final profile = gamificationState.profile;
    final achievements = gamificationState.achievements;
    final rankTier = HeroRankTier.fromLevel(profile.currentLevel);

    final totalCompletions = habits.fold<int>(
      0,
      (sum, h) => sum + h.completedDates.length,
    );

    final bestStreak = habits.isEmpty
        ? 0
        : habits
              .map((h) => AppDateUtils.calculateBestStreak(h.completedDates))
              .fold<int>(0, max);

    // Calculate category distribution
    final categoryCounts = <String, int>{};
    for (final habit in habits) {
      categoryCounts[habit.category] =
          (categoryCounts[habit.category] ?? 0) + 1;
    }

    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    // Filter achievements
    final filteredAchievements = achievements.where((a) {
      if (_selectedPathFilter == 'All') return true;
      if (_selectedPathFilter == "Warrior's Path") {
        return a.category.toLowerCase() == 'streaks';
      }
      if (_selectedPathFilter == "Scholar's Path") {
        return a.category.toLowerCase() == 'focus';
      }
      if (_selectedPathFilter == "Architect's Path") {
        return a.category.toLowerCase() == 'habits' ||
            a.category.toLowerCase() == 'mastery';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_rounded, size: 20, color: RpgColors.arcaneViolet),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Profile',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              ref.read(hapticsServiceProvider).selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // 1. Epic Hero Character Card (Hero's Armory)
              RpgCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                variant: RpgCardVariant.elevated,
                showCornerAccents: true,
                borderColor: isDark
                    ? rankTier.primaryColor.withValues(alpha: 0.45)
                    : RpgColors.arcaneViolet.withValues(alpha: 0.25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Large Hero Crest with Rank-Based Visual Frame
                        HeroAvatarBadge(
                          avatarId: profile.avatarId,
                          size: isNarrow ? 56 : 64,
                          playerLevel: profile.currentLevel,
                          showEditOverlay: true,
                          onTap: () => _openCustomizationDialog(
                            profile.heroName,
                            profile.avatarId,
                          ),
                        ),
                        const SizedBox(width: RpgSpacing.md),

                        // Name, Rank Title, Level Badge & Tier
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      profile.heroName,
                                      style: TextStyle(
                                        fontSize: isNarrow ? 16 : 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.3,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 16,
                                    ),
                                    tooltip: 'Edit Hero Name',
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                    color: isDark
                                        ? RpgColors.rpgGold
                                        : const Color(0xFFD97706),
                                    onPressed: () => _openCustomizationDialog(
                                      profile.heroName,
                                      profile.avatarId,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),

                              // Rank Title
                              Text(
                                profile.rankTitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? RpgColors.arcaneVioletLight
                                      : RpgColors.arcaneViolet,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),

                              // Level Badge + Rank Tier Chip
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  LevelBadge(
                                    level: profile.currentLevel,
                                    compact: true,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: rankTier.primaryColor.withValues(
                                        alpha: isDark ? 0.20 : 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: rankTier.primaryColor.withValues(
                                          alpha: isDark ? 0.5 : 0.3,
                                        ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      rankTier.displayName.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: rankTier.primaryColor,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // XP Progress to Next Level
                    XpProgressBar(
                      currentXp: profile.xpInLevel,
                      requiredXp: profile.xpForNextLevel,
                      progressRatio: profile.levelProgress,
                      height: 7.0,
                      leadingLabel: 'LEVEL ${profile.currentLevel} PROGRESS',
                    ),
                    const SizedBox(height: 8),

                    // Total XP & Badges Ribbon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 14,
                                color: RpgColors.rpgGold,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${profile.totalXp} Total XP',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '$unlockedCount / ${achievements.length} Badges Unlocked',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? RpgColors.questEmerald
                                  : const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 2. Three Compact Primary Metric Cards (Matching dimensions, rounded surfaces)
              Row(
                children: [
                  Expanded(
                    child: KpiStatCard(
                      title: 'Total Check-ins',
                      value: '$totalCompletions',
                      icon: Icons.check_circle_rounded,
                      iconColor: RpgColors.questEmerald,
                      isCompact: true,
                      prominentValue: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KpiStatCard(
                      title: 'Best Streak',
                      value: '$bestStreak d',
                      icon: Icons.local_fire_department_rounded,
                      iconColor: Colors.deepOrange,
                      isCompact: true,
                      prominentValue: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KpiStatCard(
                      title: 'Achievements',
                      value: '$unlockedCount',
                      icon: Icons.military_tech_rounded,
                      iconColor: RpgColors.rpgGold,
                      isCompact: true,
                      prominentValue: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Secondary Metrics Strip: Active Habits Overview
              RpgCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                variant: RpgCardVariant.standard,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: RpgColors.rpgIndigo.withValues(
                          alpha: isDark ? 0.20 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.checklist_rounded,
                        color: RpgColors.rpgIndigo,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Active Habits',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${habits.length}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: RpgColors.rpgIndigo,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 3. Settings Card Link
              RpgCard(
                padding: EdgeInsets.zero,
                variant: RpgCardVariant.standard,
                onTap: () {
                  ref.read(hapticsServiceProvider).selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: RpgColors.arcaneViolet.withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: RpgColors.arcaneViolet.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: RpgColors.arcaneViolet,
                      size: 18,
                    ),
                  ),
                  title: const Text(
                    'Settings',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Preferences, reminders & haptics',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Illuminated Achievement Trophy Room
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.military_tech_rounded,
                          size: 18,
                          color: RpgColors.rpgGold,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Trophy Collection',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? RpgColors.rpgGold.withValues(alpha: 0.14)
                          : RpgColors.rpgGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: RpgColors.rpgGold.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '$unlockedCount of ${achievements.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: RpgColors.rpgGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Path Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      [
                        'All',
                        "Warrior's Path",
                        "Scholar's Path",
                        "Architect's Path",
                      ].map((filter) {
                        final isSelected = _selectedPathFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            selectedColor: isDark
                                ? RpgColors.rpgGold.withValues(alpha: 0.25)
                                : RpgColors.rpgGold.withValues(alpha: 0.15),
                            checkmarkColor: isDark
                                ? RpgColors.rpgGold
                                : const Color(0xFFD97706),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? (isDark
                                        ? RpgColors.rpgGold
                                        : const Color(0xFFD97706))
                                  : (isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade800),
                            ),
                            onSelected: (_) {
                              ref.read(hapticsServiceProvider).selectionClick();
                              setState(() {
                                _selectedPathFilter = filter;
                              });
                            },
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // Achievement Badges Grid (Responsive: 3 cols standard, 2 cols on small screens)
              if (filteredAchievements.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'No badges in this path yet.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredAchievements.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isNarrow ? 2 : 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: isNarrow ? 0.86 : 0.74,
                  ),
                  itemBuilder: (context, index) {
                    return AchievementBadgeTile(
                      achievement: filteredAchievements[index],
                    );
                  },
                ),
              const SizedBox(height: 14),

              // 5. Category Breakdown Section (Compact Analytics with real counts and bars)
              const Row(
                children: [
                  Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 18,
                    color: RpgColors.arcaneViolet,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Category Breakdown',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              RpgCard(
                padding: const EdgeInsets.all(12),
                variant: RpgCardVariant.standard,
                child: habits.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No habits created yet',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: AppConstants.habitCategories.map((category) {
                          final count = categoryCounts[category] ?? 0;
                          final ratio = habits.isEmpty
                              ? 0.0
                              : count / habits.length;
                          final color = _getCategoryColor(category);
                          final icon = _getCategoryIcon(category);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(
                                      alpha: isDark ? 0.20 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(icon, size: 14, color: color),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 5,
                                      backgroundColor: isDark
                                          ? Colors.white10
                                          : Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        count > 0 ? color : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '$count',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: count > 0
                                          ? (isDark
                                                ? Colors.white
                                                : Colors.black87)
                                          : (isDark
                                                ? Colors.grey.shade600
                                                : Colors.grey.shade400),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 84), // Clearance above floating bottom nav
            ],
          );
        },
      ),
    );
  }
}
