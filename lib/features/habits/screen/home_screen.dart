import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/theme/rpg_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/cozy_background.dart';
import '../../../core/widgets/cozy_button.dart';
import '../../../core/widgets/rpg_celebration_banner.dart';
import '../../../core/widgets/rpg_crest.dart';
import '../../gamification/controllers/gamification_controller.dart';
import '../controllers/habit_controller.dart';
import '../models/habit.dart';
import 'habit_detail_screen.dart';
import 'widgets/daily_bounty_card.dart';
import 'widgets/habit_tile.dart';
import 'widgets/hero_xp_hud.dart';
import 'widgets/level_up_dialog.dart';
import 'widgets/quest_form_sheet.dart';

const availableCategories = AppConstants.allCategories;
const habitCategories = AppConstants.habitCategories;
const availableColors = AppConstants.availableColors;

class CategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void select(String category) => state = category;
}

final categoryFilterProvider = NotifierProvider<CategoryFilterNotifier, String>(
  CategoryFilterNotifier.new,
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _showHabitDialog(BuildContext context, WidgetRef ref, {Habit? habit}) {
    QuestFormSheet.show(
      context,
      habit: habit,
      onSave: (title, category, colorValue) {
        if (habit == null) {
          ref
              .read(habitControllerProvider.notifier)
              .addHabit(title, category: category, colorValue: colorValue);
        } else {
          ref
              .read(habitControllerProvider.notifier)
              .editHabit(
                habit.id!,
                title,
                category: category,
                colorValue: colorValue,
              );
        }
      },
    );
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
        return Icons.shield_rounded;
      case 'all':
      default:
        return Icons.explore_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for level-up & achievement unlock celebrations
    ref.listen<GamificationState>(gamificationControllerProvider, (
      previous,
      next,
    ) {
      if (previous != null && !previous.isLoading && !next.isLoading) {
        final oldLevel = previous.profile.currentLevel;
        final newLevel = next.profile.currentLevel;
        if (newLevel > oldLevel && mounted) {
          ref.read(hapticsServiceProvider).levelUp();
          LevelUpDialog.show(context, newLevel);
        }

        // Listen for newly unlocked achievements
        final newlyUnlocked = next.achievements.where((nextAch) {
          if (!nextAch.isUnlocked) return false;
          final prevAch = previous.achievements.firstWhere(
            (p) => p.badgeKey == nextAch.badgeKey,
            orElse: () => nextAch.copyWith(isUnlocked: false),
          );
          return !prevAch.isUnlocked;
        }).toList();

        if (newlyUnlocked.isNotEmpty && mounted) {
          ref.read(hapticsServiceProvider).achievementUnlocked();
          for (final ach in newlyUnlocked) {
            RpgCelebrationBanner.showAchievementUnlocked(context, ach);
          }
        }
      }
    });

    // Listen for clean sheet (all daily quests completed)
    ref.listen<List<Habit>>(habitControllerProvider, (previous, next) {
      if (previous != null && previous.isNotEmpty && next.isNotEmpty) {
        final wasCleanSheet = previous.every((h) => h.isCompletedToday);
        final isCleanSheet = next.every((h) => h.isCompletedToday);
        if (!wasCleanSheet && isCleanSheet && mounted) {
          ref.read(hapticsServiceProvider).milestoneReached();
          RpgCelebrationBanner.showMilestone(
            context,
            title: 'Flawless Victory!',
            subtitle: 'All daily quests completed for today!',
            icon: Icons.check_circle_rounded,
            iconColor: RpgColors.questEmerald,
          );
        }
      }
    });

    // Watch currentDateProvider so the UI automatically updates on midnight or date rollover
    ref.watch(currentDateProvider);
    final habits = ref.watch(habitControllerProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final haptics = ref.read(hapticsServiceProvider);

    final displayedHabits = selectedCategory == 'All'
        ? habits
        : habits.where((h) => h.category == selectedCategory).toList();

    return CozyBackgroundScaffold.village(
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
                Icons.shield_moon_rounded,
                size: 20,
                color: RpgColors.arcaneViolet,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'DailyFlow',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Level Up Your Daily Life ✨',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFB0B9D0)
                          : RpgColors.textSecondaryLight,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        children: [
          // 1. Cozy Hero Dashboard HUD
          HeroXpHud(habits: habits),
          const SizedBox(height: 10),

          // 2. Daily Quest Bounty Card
          DailyBountyCard(habits: habits),
          const SizedBox(height: 10),

          // 3. Category Filter Chips with fantasy icons
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: availableCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = availableCategories[index];
                final isSelected = selectedCategory == category;
                final catIcon = _getCategoryIcon(category);

                return FilterChip(
                  avatar: Icon(
                    catIcon,
                    size: 14,
                    color: isSelected
                        ? (isDark ? RpgColors.warmGold : RpgColors.arcaneViolet)
                        : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                  ),
                  label: Text(category),
                  selected: isSelected,
                  backgroundColor: isDark
                      ? const Color(0xFF14192E)
                      : const Color(0xFFF1F5F9),
                  selectedColor: isDark
                      ? RpgColors.arcaneViolet.withValues(alpha: 0.32)
                      : RpgColors.arcaneViolet.withValues(alpha: 0.16),
                  checkmarkColor: isDark
                      ? RpgColors.warmGold
                      : RpgColors.arcaneViolet,
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12.5,
                    color: isSelected
                        ? (isDark ? Colors.white : RpgColors.arcaneViolet)
                        : (isDark ? Colors.grey.shade300 : Colors.black87),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? (isDark
                                ? RpgColors.warmGold.withValues(alpha: 0.6)
                                : RpgColors.arcaneViolet)
                          : (isDark
                                ? const Color(0xFF26304E)
                                : Colors.grey.shade300),
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                  onSelected: (_) {
                    haptics.selectionClick();
                    ref.read(categoryFilterProvider.notifier).select(category);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // 4. Quests Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Today's Habits",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? RpgColors.mutedViolet.withValues(alpha: 0.25)
                          : RpgColors.rpgViolet.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${displayedHabits.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? RpgColors.arcaneVioletLight
                            : RpgColors.arcaneViolet,
                      ),
                    ),
                  ),
                ],
              ),
              if (selectedCategory != 'All')
                Text(
                  '${displayedHabits.length} quests',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 5. Quest List or Empty State
          if (displayedHabits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF13182C).withValues(alpha: 0.8)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? RpgColors.arcaneViolet.withValues(alpha: 0.25)
                        : RpgColors.rpgBorderLight,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RpgCrest(
                      size: 54,
                      shape: RpgCrestShape.shield,
                      tier: RpgGemTier.arcane,
                      hasGlow: false,
                      icon: Icons.shield_outlined,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      habits.isEmpty
                          ? 'No habits yet.'
                          : 'No habits found in "$selectedCategory".',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      habits.isEmpty
                          ? 'Forge a new quest below to embark on your adventure!'
                          : 'Try selecting a different quest category filter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ...displayedHabits.map((habit) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: HabitTile(
                  habit: habit,
                  hapticsService: haptics,
                  onDetailTap: () {
                    if (habit.id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HabitDetailScreen(habitId: habit.id!),
                        ),
                      );
                    }
                  },
                  onToggle: () => ref
                      .read(habitControllerProvider.notifier)
                      .toggleHabitForToday(habit),
                  onToggleDate: (dateStr) => ref
                      .read(habitControllerProvider.notifier)
                      .toggleHabitOnDate(habit, dateStr),
                  onEdit: () => _showHabitDialog(context, ref, habit: habit),
                  onDelete: () {
                    final deletedHabit = habit;
                    ref
                        .read(habitControllerProvider.notifier)
                        .deleteHabit(deletedHabit.id!);

                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Habit "${deletedHabit.title}" deleted'),
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            ref
                                .read(habitControllerProvider.notifier)
                                .restoreHabit(deletedHabit);
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

            // 6. Adventure Journal Codex Inscription (refined compact card)
            const SizedBox(height: 4),
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF13182E).withValues(alpha: 0.60)
                      : const Color(0xFFF1F5F9).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF222B48)
                        : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 16,
                      color: isDark
                          ? RpgColors.warmGold.withValues(alpha: 0.70)
                          : RpgColors.arcaneViolet.withValues(alpha: 0.70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      habits.every((h) => h.isCompletedToday)
                          ? 'All daily bounties claimed. Rest by the hearth, adventurer.'
                          : 'Small deeds inscribed daily become great legends.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        letterSpacing: 0.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '✦ DAILYFLOW ADVENTURE CODEX ✦',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: isDark
                            ? RpgColors.warmGold.withValues(alpha: 0.75)
                            : RpgColors.rpgIndigo.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Bottom clearance so floating CTA button does not obscure content
          const SizedBox(height: 68),
        ],
      ),
      floatingActionButton: CozyButton.primary(
        label: 'New Quest',
        leadingIcon: Icons.add_rounded,
        width: 142.0,
        height: 44.0,
        onPressed: () => _showHabitDialog(context, ref),
      ),
    );
  }
}
