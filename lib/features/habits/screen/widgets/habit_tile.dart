import 'package:flutter/material.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/theme/cozy_artwork.dart';
import '../../../../core/theme/rpg_colors.dart';
import '../../../../core/theme/rpg_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/gamification_math.dart';
import '../../../../core/widgets/compact_xp_indicator.dart';
import '../../../../core/widgets/cozy_card.dart';
import '../../../../core/widgets/rpg_crest_checkbox.dart';
import '../../../../core/widgets/rpg_gemstone_badge.dart';
import '../../models/habit.dart';

/// Cozy Adventure RPG Quest Card representing a habit as an adventurous quest.
/// Built with CozyCard, QuestJournalIcon, XpRewardBadge, RpgCrestCheckbox,
/// category-specific fantasy icons, real streak status, and 48x48px accessible touch targets.
class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final void Function(String dateStr) onToggleDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onDetailTap;
  final HapticsService? hapticsService;

  const HabitTile({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onToggleDate,
    required this.onEdit,
    required this.onDelete,
    this.onDetailTap,
    this.hapticsService,
  });

  void _triggerCheckinHaptic(bool willComplete) {
    if (hapticsService != null) {
      if (willComplete) {
        hapticsService!.questCompleted();
      } else {
        hapticsService!.lightImpact();
      }
    }
  }

  void _triggerRunicHaptic() {
    if (hapticsService != null) {
      hapticsService!.selectionClick();
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
    final isDone = habit.isCompletedToday;
    final streak = habit.currentStreak;
    final accentColor = Color(habit.colorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final todayStr = AppDateUtils.todayString;
    final last7Days = AppDateUtils.getLast7DaysWithLabels();

    // Calculate real domain XP based on streak bonus
    final checkinXp = GamificationMath.calculateCheckinXp(streak);

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: RpgColors.rpgCrimson,
          borderRadius: BorderRadius.circular(18.0),
        ),
        child: const Icon(
          Icons.delete_forever_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: AnimatedContainer(
        duration: disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 250),
        child: CozyCard(
          borderRadius: BorderRadius.circular(18.0),
          padding: EdgeInsets.zero,
          hasGlow: isDone,
          color: isDone
              ? (isDark ? const Color(0xFF112520) : const Color(0xFFECFDF5))
              : (isDark ? const Color(0xFF161C33) : Colors.white),
          borderColor: isDone
              ? RpgColors.questEmerald.withValues(alpha: isDark ? 0.70 : 0.50)
              : (isDark
                    ? accentColor.withValues(alpha: 0.28)
                    : RpgColors.rpgBorderLight),
          child: Stack(
            children: [
              // Left decorative binding ribbon in category accent color
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: Container(
                  width: 3.5,
                  decoration: BoxDecoration(
                    color: isDone ? RpgColors.questEmerald : accentColor,
                    boxShadow: [
                      BoxShadow(
                        color: (isDone ? RpgColors.questEmerald : accentColor)
                            .withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

              // Subtle Quest Journal watermark for study/coding quests
              if (habit.category.toLowerCase() == 'study' ||
                  habit.category.toLowerCase() == 'coding')
                Positioned(
                  right: 48,
                  top: 8,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: isDark ? 0.22 : 0.15,
                      child: const QuestJournalIcon(size: 32),
                    ),
                  ),
                ),

              // Card Interior Content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main Interactive Area
                  InkWell(
                    borderRadius: BorderRadius.circular(18.0),
                    onTap: onDetailTap,
                    onLongPress: onEdit,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 12, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. One-Tap Completion Crest Checkmark (48x48 touch target)
                          Semantics(
                            button: true,
                            label: isDone
                                ? 'Uncomplete quest ${habit.title}'
                                : 'Complete quest ${habit.title}',
                            child: RpgCrestCheckbox(
                              key: const Key('habit_tile_checkmark_btn'),
                              isCompleted: isDone,
                              gemColor: accentColor,
                              size: 30.0,
                              minTouchTarget: RpgSpacing.minTouchTarget,
                              tooltip: isDone
                                  ? 'Mark Incomplete'
                                  : 'Complete Quest (+$checkinXp XP)',
                              onChanged: (_) {
                                _triggerCheckinHaptic(!isDone);
                                onToggle();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 2. Quest Metadata & Title
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Category Gemstone Badge + XP Reward Badge
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 3,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    // Category Gemstone Badge
                                    RpgGemstoneBadge(
                                      label: habit.category.toUpperCase(),
                                      icon: _getCategoryIcon(habit.category),
                                      color: accentColor,
                                      compact: true,
                                    ),

                                    // XP Reward Badge
                                    XpRewardBadge(
                                      xp: checkinXp,
                                      isGlowing: isDone,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),

                                // Quest Title
                                Text(
                                  habit.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade600,
                                    color: isDone
                                        ? (isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600)
                                        : (isDark
                                              ? Colors.white
                                              : Colors.black87),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 3. Streak Indicator Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: streak > 0
                                  ? Colors.deepOrange.withValues(
                                      alpha: isDark ? 0.20 : 0.12,
                                    )
                                  : (isDark
                                        ? Colors.white10
                                        : Colors.grey.shade100),
                              borderRadius: RpgSpacing.roundedPill,
                              border: Border.all(
                                color: streak > 0
                                    ? Colors.deepOrange.withValues(
                                        alpha: isDark ? 0.38 : 0.25,
                                      )
                                    : (isDark
                                          ? Colors.white12
                                          : Colors.grey.shade300),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 14,
                                  color: streak > 0
                                      ? Colors.deepOrange
                                      : (isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey),
                                ),
                                const SizedBox(width: 2.5),
                                Text(
                                  '$streak',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: streak > 0
                                        ? Colors.deepOrange
                                        : (isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 7-Day Runic Completion Strip with 48x48px Touch Targets
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: last7Days.map((day) {
                        final isCompleted = habit.completedDates.contains(
                          day.dateStr,
                        );
                        final isToday = day.dateStr == todayStr;

                        return Expanded(
                          child: Semantics(
                            button: true,
                            label:
                                '${day.label}: ${isCompleted ? "Completed" : "Not completed"}',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _triggerRunicHaptic();
                                onToggleDate(day.dateStr);
                              },
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: RpgSpacing.minTouchTarget,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      day.label,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: isToday
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isToday
                                            ? (isDark
                                                  ? RpgColors.rpgGold
                                                  : accentColor)
                                            : (isDark
                                                  ? Colors.grey.shade400
                                                  : Colors.grey.shade600),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    AnimatedContainer(
                                      duration: disableAnimations
                                          ? Duration.zero
                                          : const Duration(milliseconds: 200),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: isCompleted
                                            ? RpgColors.emeraldGradient
                                            : null,
                                        color: isCompleted
                                            ? null
                                            : (isDark
                                                  ? Colors.white10
                                                  : Colors.grey.shade100),
                                        border: Border.all(
                                          color: isToday && !isCompleted
                                              ? (isDark
                                                    ? RpgColors.rpgGold
                                                    : accentColor)
                                              : (isCompleted
                                                    ? RpgColors.questEmerald
                                                    : (isDark
                                                          ? Colors.white24
                                                          : Colors
                                                                .grey
                                                                .shade300)),
                                          width: isToday ? 1.5 : 1.0,
                                        ),
                                        boxShadow: isCompleted
                                            ? [
                                                BoxShadow(
                                                  color: RpgColors.questEmerald
                                                      .withValues(
                                                        alpha: isDark
                                                            ? 0.35
                                                            : 0.2,
                                                      ),
                                                  blurRadius: 4,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: isCompleted
                                            ? const Icon(
                                                Icons.check_rounded,
                                                size: 14,
                                                color: Colors.white,
                                              )
                                            : (isToday
                                                  ? Container(
                                                      width: 5,
                                                      height: 5,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: isDark
                                                            ? RpgColors.rpgGold
                                                            : accentColor,
                                                      ),
                                                    )
                                                  : null),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
