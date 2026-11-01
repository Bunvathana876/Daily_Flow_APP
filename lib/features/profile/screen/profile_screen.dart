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
                padding: const EdgeInsets.all(RpgSpacing.lg),
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
                          size: isNarrow ? 62 : 72,
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
                    const SizedBox(height: RpgSpacing.md),

                    // XP Progress to Next Level
                    XpProgressBar(
                      currentXp: profile.xpInLevel,
                      requiredXp: profile.xpForNextLevel,
                      progressRatio: profile.levelProgress,
                      height: 8.0,
                      leadingLabel: 'LEVEL ${profile.currentLevel} PROGRESS',
                    ),
                    const SizedBox(height: 10),

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
              const SizedBox(height: 14),

              // 2. Verified KPI Stats Row (Responsive for 320px screens)
              Row(
                children: [
                  Expanded(
                    child: KpiStatCard(
                      title: 'Active Habits',
                      value: '${habits.length}',
                      icon: Icons.checklist_rounded,
                      iconColor: RpgColors.rpgIndigo,
                      isCompact: isNarrow,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KpiStatCard(
                      title: 'Total Check-ins',
                      value: '$totalCompletions',
                      icon: Icons.check_circle_rounded,
                      iconColor: RpgColors.questEmerald,
                      isCompact: isNarrow,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KpiStatCard(
                      title: 'Best Streak',
                      value: '$bestStreak d',
                      icon: Icons.local_fire_department_rounded,
                      iconColor: Colors.deepOrange,
                      isCompact: isNarrow,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: RpgColors.arcaneViolet.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: RpgColors.arcaneViolet.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: RpgColors.arcaneViolet,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Settings',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Dark mode, themes, haptics & preferences',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
              const SizedBox(height: 20),

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
                          size: 20,
                          color: RpgColors.rpgGold,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Achievements',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
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
                      vertical: 3,
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
              const SizedBox(height: 10),

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
              const SizedBox(height: 10),

              // Achievement Badges List
              if (filteredAchievements.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
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
                ...filteredAchievements.map((achievement) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AchievementBadgeTile(achievement: achievement),
                  );
                }),
              const SizedBox(height: 20),

              // 5. Category Breakdown Section (Preserved for analytics and tests)
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
                padding: const EdgeInsets.all(14),
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
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppConstants.habitCategories.map((category) {
                          final count = categoryCounts[category] ?? 0;
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundColor: RpgColors.arcaneViolet,
                              radius: 10,
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            label: Text(category),
                            backgroundColor: count > 0
                                ? RpgColors.arcaneViolet.withValues(alpha: 0.12)
                                : (isDark
                                      ? const Color(0xFF0F172A)
                                      : Colors.grey.shade100),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 36),
            ],
          );
        },
      ),
    );
  }
}
