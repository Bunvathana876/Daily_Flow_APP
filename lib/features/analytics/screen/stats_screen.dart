import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/rpg_colors.dart';
import '../../../../core/theme/rpg_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/kpi_stat_card.dart';
import '../../../../core/widgets/level_badge.dart';
import '../../../../core/widgets/rpg_card.dart';
import '../../../../core/widgets/xp_progress_bar.dart';
import '../../gamification/controllers/gamification_controller.dart';
import '../../gamification/data/gamification_repository.dart';
import '../../gamification/models/hero_rank_tier.dart';
import '../../gamification/models/xp_entry.dart';
import '../../gamification/widgets/hero_avatar_badge.dart';
import '../../habits/controllers/habit_controller.dart';

/// Hall of Records & Insights Analytics Screen.
/// Displays hero progress summary, 12-week consistency rune heatmap,
/// weekday battle rhythm performance, and XP source breakdown.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _focusMinutes = 0;
  int _focusSessions = 0;
  Map<String, int> _xpBreakdown = const {};

  @override
  void initState() {
    super.initState();
    _loadAdditionalStats();
  }

  Future<void> _loadAdditionalStats() async {
    try {
      final repo = ref.read(gamificationRepositoryProvider);
      final minutes = await repo.getTotalFocusMinutes();
      final sessions = await repo.getTotalFocusSessions();
      final breakdown = await repo.getXpBreakdown();

      if (mounted) {
        setState(() {
          _focusMinutes = minutes;
          _focusSessions = sessions;
          _xpBreakdown = breakdown;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitControllerProvider);
    final gamificationState = ref.watch(gamificationControllerProvider);
    final profile = gamificationState.profile;
    final achievements = gamificationState.achievements;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rankTier = HeroRankTier.fromLevel(profile.currentLevel);

    final totalCompletions = habits.fold<int>(
      0,
      (sum, h) => sum + h.completedDates.length,
    );

    final bestEverStreak = habits.isEmpty
        ? 0
        : habits
              .map((h) => AppDateUtils.calculateBestStreak(h.completedDates))
              .fold<int>(0, (a, b) => a > b ? a : b);

    final currentStreaks = habits.isEmpty
        ? 0
        : habits
              .map((h) => AppDateUtils.calculateStreak(h.completedDates))
              .fold<int>(0, (a, b) => a > b ? a : b);

    final heatmapData = AppDateUtils.getHeatmapData(habits, days: 84);
    final weekdayRates = AppDateUtils.getWeekdayCompletionRates(habits);

    final unlockedAchievements = achievements
        .where((a) => a.isUnlocked)
        .toList();

    final breakdown = _xpBreakdown.isNotEmpty
        ? _xpBreakdown
        : gamificationState.xpBreakdown;

    final habitXp = breakdown[XpSourceType.habitCheckin] ?? 0;
    final focusXp = breakdown[XpSourceType.focusSession] ?? 0;
    final achievementXp = breakdown[XpSourceType.achievement] ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hall of Records',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              'Insights & Analytics',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? RpgColors.arcaneVioletLight
                    : RpgColors.arcaneViolet,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: LevelBadge(level: profile.currentLevel, compact: true),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Productivity Overview Card
                RpgCard(
                  padding: const EdgeInsets.all(RpgSpacing.lg),
                  variant: RpgCardVariant.elevated,
                  showCornerAccents: true,
                  borderColor: isDark
                      ? rankTier.primaryColor.withValues(alpha: 0.45)
                      : RpgColors.arcaneViolet.withValues(alpha: 0.20),
                  child: Row(
                    children: [
                      HeroAvatarBadge(
                        avatarId: profile.avatarId,
                        size: isNarrow ? 50 : 58,
                        playerLevel: profile.currentLevel,
                        showEditOverlay: false,
                      ),
                      const SizedBox(width: RpgSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.heroName,
                              style: TextStyle(
                                fontSize: isNarrow ? 15 : 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.rankTitle,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? RpgColors.arcaneVioletLight
                                    : RpgColors.arcaneViolet,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 14,
                                      color: RpgColors.rpgGold,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${profile.totalXp} Total XP',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: RpgColors.rpgGold,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.military_tech_rounded,
                                      size: 14,
                                      color: RpgColors.questEmerald,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${unlockedAchievements.length} / ${achievements.length} Badges',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: RpgColors.questEmerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: RpgSpacing.md),

                // 2. 4 Quick KPI Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: KpiStatCard(
                        title: 'Total Check-ins',
                        value: '$totalCompletions',
                        icon: Icons.check_circle_rounded,
                        iconColor: RpgColors.questEmerald,
                        isCompact: isNarrow,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KpiStatCard(
                        title: 'Best Streak',
                        value: '$bestEverStreak d',
                        subtitle: 'Current: $currentStreaks d',
                        icon: Icons.local_fire_department_rounded,
                        iconColor: RpgColors.rpgGold,
                        isCompact: isNarrow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: KpiStatCard(
                        title: 'Active Habits',
                        value: '${habits.length}',
                        icon: Icons.bolt_rounded,
                        iconColor: RpgColors.arcaneViolet,
                        isCompact: isNarrow,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KpiStatCard(
                        title: 'Focus Trials',
                        value: '$_focusMinutes m',
                        subtitle: '$_focusSessions sessions',
                        icon: Icons.hourglass_bottom_rounded,
                        iconColor: const Color(0xFF38BDF8),
                        isCompact: isNarrow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RpgSpacing.lg),

                // 3. 12-Week Consistency Chronicle (Heatmap)
                RpgCard(
                  padding: const EdgeInsets.all(RpgSpacing.lg),
                  variant: RpgCardVariant.standard,
                  showCornerAccents: true,
                  borderColor: isDark
                      ? RpgColors.arcaneViolet.withValues(alpha: 0.3)
                      : RpgColors.arcaneViolet.withValues(alpha: 0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: RpgColors.arcaneViolet,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '12-Week Consistency',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Last 84 Days',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: RpgSpacing.md),
                      _HeatmapGrid(heatmapData: heatmapData, isDark: isDark),
                      const SizedBox(height: RpgSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Less',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          for (final ratio in [0.0, 0.25, 0.5, 0.75, 1.0]) ...[
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: ratio == 0.0
                                    ? (isDark
                                          ? Colors.white10
                                          : Colors.grey.shade200)
                                    : (ratio == 1.0
                                          ? RpgColors.rpgGold
                                          : RpgColors.arcaneViolet.withValues(
                                              alpha: 0.25 + 0.65 * ratio,
                                            )),
                                borderRadius: BorderRadius.circular(3),
                                border: ratio >= 1.0
                                    ? Border.all(
                                        color: RpgColors.rpgGold,
                                        width: 0.8,
                                      )
                                    : null,
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Text(
                            'More',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: RpgSpacing.lg),

                // 4. Weekday Performance / Battle Rhythm
                RpgCard(
                  padding: const EdgeInsets.all(RpgSpacing.lg),
                  variant: RpgCardVariant.standard,
                  borderColor: isDark
                      ? RpgColors.arcaneViolet.withValues(alpha: 0.3)
                      : RpgColors.arcaneViolet.withValues(alpha: 0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.bar_chart_rounded,
                            size: 18,
                            color: RpgColors.rpgGold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Weekday Performance',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Average Rate',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _WeekdayBarChart(rates: weekdayRates, isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: RpgSpacing.lg),

                // 5. XP Progression & Source Breakdown Card
                RpgCard(
                  padding: const EdgeInsets.all(RpgSpacing.lg),
                  variant: RpgCardVariant.standard,
                  borderColor: isDark
                      ? RpgColors.arcaneViolet.withValues(alpha: 0.3)
                      : RpgColors.arcaneViolet.withValues(alpha: 0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: RpgColors.rpgGold,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'XP Progression',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      XpProgressBar(
                        currentXp: profile.xpInLevel,
                        requiredXp: profile.xpForNextLevel,
                        progressRatio: profile.levelProgress,
                        height: 8.0,
                        leadingLabel: 'LEVEL ${profile.currentLevel} PROGRESS',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'REWARD SOURCES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark
                              ? RpgColors.rpgGold
                              : const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _XpBreakdownRow(
                        label: 'Habit Quests',
                        xp: habitXp,
                        icon: Icons.check_circle_rounded,
                        color: RpgColors.questEmerald,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _XpBreakdownRow(
                        label: 'Focus Chamber',
                        xp: focusXp,
                        icon: Icons.timer_rounded,
                        color: const Color(0xFF38BDF8),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _XpBreakdownRow(
                        label: 'Achievements',
                        xp: achievementXp,
                        icon: Icons.military_tech_rounded,
                        color: RpgColors.rpgGold,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: RpgSpacing.lg),

                // 6. Achievement Milestones Overview
                RpgCard(
                  padding: const EdgeInsets.all(RpgSpacing.lg),
                  variant: RpgCardVariant.standard,
                  borderColor: isDark
                      ? RpgColors.arcaneViolet.withValues(alpha: 0.3)
                      : RpgColors.arcaneViolet.withValues(alpha: 0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            size: 18,
                            color: RpgColors.rpgGold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Achievement Milestones',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${unlockedAchievements.length} / ${achievements.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: RpgColors.rpgGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: achievements.isEmpty
                              ? 0.0
                              : unlockedAchievements.length /
                                    achievements.length,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            RpgColors.rpgGold,
                          ),
                        ),
                      ),
                      if (unlockedAchievements.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: unlockedAchievements.map((ach) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: RpgColors.rpgGold.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: RpgColors.rpgGold.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 14,
                                    color: RpgColors.rpgGold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ach.title,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _XpBreakdownRow extends StatelessWidget {
  final String label;
  final int xp;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _XpBreakdownRow({
    required this.label,
    required this.xp,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        Text(
          '+$xp XP',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final Map<String, double> heatmapData;
  final bool isDark;

  const _HeatmapGrid({required this.heatmapData, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final entries = heatmapData.entries.toList();
    final columns = <List<MapEntry<String, double>>>[];
    for (int i = 0; i < entries.length; i += 7) {
      columns.add(entries.sublist(i, min(i + 7, entries.length)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final boxSize = max(8.0, (availableWidth - (12 * 4)) / 12);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: columns.map((col) {
            return Column(
              children: col.map((entry) {
                final ratio = entry.value;
                final color = ratio == 0.0
                    ? (isDark ? Colors.white10 : Colors.grey.shade200)
                    : (ratio >= 1.0
                          ? RpgColors.rpgGold
                          : RpgColors.arcaneViolet.withValues(
                              alpha: 0.25 + 0.65 * ratio,
                            ));

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Semantics(
                    label: '${entry.key}: ${(ratio * 100).round()}% completed',
                    child: Tooltip(
                      message:
                          '${entry.key}: ${(ratio * 100).round()}% completed',
                      child: Container(
                        width: boxSize,
                        height: boxSize,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                          border: ratio >= 1.0
                              ? Border.all(
                                  color: RpgColors.rpgGold.withValues(
                                    alpha: 0.8,
                                  ),
                                  width: 0.6,
                                )
                              : (ratio > 0.0
                                    ? Border.all(
                                        color: RpgColors.arcaneViolet
                                            .withValues(alpha: 0.4),
                                        width: 0.4,
                                      )
                                    : null),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        );
      },
    );
  }
}

class _WeekdayBarChart extends StatelessWidget {
  final Map<int, double> rates;
  final bool isDark;

  const _WeekdayBarChart({required this.rates, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const maxBarHeight = 90.0;
    final maxRate = rates.values.fold<double>(0.0, max);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final weekday = index + 1;
        final rate = rates[weekday] ?? 0.0;
        final barHeight = max(8.0, rate * maxBarHeight);
        final isTop = maxRate > 0 && (rate - maxRate).abs() < 0.001;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTop && rate > 0)
              const Icon(
                Icons.workspace_premium_rounded,
                size: 14,
                color: RpgColors.rpgGold,
              )
            else
              const SizedBox(height: 14),
            const SizedBox(height: 2),
            Text(
              '${(rate * 100).round()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isTop ? FontWeight.w800 : FontWeight.w600,
                color: isTop
                    ? RpgColors.rpgGold
                    : (isDark ? Colors.white60 : Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: 24,
              height: barHeight,
              decoration: BoxDecoration(
                color: rate > 0
                    ? (isTop
                          ? RpgColors.rpgGold
                          : RpgColors.arcaneViolet.withValues(alpha: 0.7))
                    : (isDark ? Colors.white10 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(6),
                boxShadow: isTop && rate > 0
                    ? [
                        BoxShadow(
                          color: RpgColors.rpgGold.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              weekdayLabels[index],
              style: TextStyle(
                fontSize: 12,
                fontWeight: isTop ? FontWeight.w800 : FontWeight.w600,
                color: isTop
                    ? RpgColors.rpgGold
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        );
      }),
    );
  }
}
