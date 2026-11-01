import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/rpg_colors.dart';
import '../../../../core/theme/rpg_spacing.dart';
import '../../../../core/widgets/rpg_crest.dart';
import '../../../../core/widgets/rpg_filled_button.dart';
import '../../../../core/widgets/rpg_gemstone_badge.dart';
import '../../models/habit.dart';

/// Polished draggable modal bottom sheet for creating and editing fantasy quests.
/// Includes fantasy-styled inputs, category selection with RPG icons, gemstone color picker,
/// projected XP preview, inline field validation, and keyboard-safe responsive layout.
class QuestFormSheet extends StatefulWidget {
  final Habit? habit;
  final void Function(String title, String category, int colorValue) onSave;

  const QuestFormSheet({super.key, this.habit, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    Habit? habit,
    required void Function(String title, String category, int colorValue)
    onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuestFormSheet(habit: habit, onSave: onSave),
    );
  }

  @override
  State<QuestFormSheet> createState() => _QuestFormSheetState();
}

class _QuestFormSheetState extends State<QuestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late String _selectedCategory;
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title ?? '');
    _selectedCategory =
        widget.habit?.category ?? AppConstants.habitCategories.first;
    _selectedColor =
        widget.habit?.colorValue ?? AppConstants.availableColors.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final title = _titleController.text.trim();
      widget.onSave(title, _selectedCategory, _selectedColor);
      Navigator.of(context).pop();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.habit != null;
    final currentColor = Color(_selectedColor);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? RpgColors.rpgSurfaceElevated : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(RpgSpacing.radiusCard),
        ),
        border: Border(
          top: BorderSide(
            color: isDark
                ? RpgColors.arcaneViolet.withValues(alpha: 0.4)
                : RpgColors.rpgBorderLight,
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle Pill
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header Row: Emblem + Title + Close Button
                  Row(
                    children: [
                      RpgCrest(
                        size: 38,
                        shape: RpgCrestShape.shield,
                        tier: isEditing ? RpgGemTier.gold : RpgGemTier.arcane,
                        icon: isEditing
                            ? Icons.edit_note_rounded
                            : Icons.auto_awesome_rounded,
                        hasGlow: true,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Inscribe Quest' : 'Forge New Quest',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: 0.2,
                              ),
                            ),
                            Text(
                              isEditing
                                  ? 'Update quest objectives and properties'
                                  : 'Embark on a new daily challenge for XP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        tooltip: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Projected XP Preview Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: RpgColors.rpgGold.withValues(
                        alpha: isDark ? 0.12 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(RpgSpacing.radiusMd),
                      border: Border.all(
                        color: RpgColors.rpgGold.withValues(
                          alpha: isDark ? 0.35 : 0.25,
                        ),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: RpgColors.rpgGold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Grants +20 base XP per daily check-in (+streak bonus)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? RpgColors.rpgGoldBright
                                  : const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quest Title Input Field
                  const Text(
                    'Quest Title',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'e.g., Read 20 Pages, Morning Yoga, Solve 1 LeetCode',
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.edit_note_rounded,
                        color: isDark
                            ? RpgColors.arcaneVioletLight
                            : RpgColors.arcaneViolet,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? RpgColors.rpgDungeonSlate
                          : const Color(0xFFF8F9FE),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          RpgSpacing.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: isDark
                              ? RpgColors.rpgBorderDark
                              : RpgColors.rpgBorderLight,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          RpgSpacing.radiusMd,
                        ),
                        borderSide: const BorderSide(
                          color: RpgColors.arcaneViolet,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          RpgSpacing.radiusMd,
                        ),
                        borderSide: const BorderSide(
                          color: RpgColors.rpgCrimson,
                          width: 1.2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          RpgSpacing.radiusMd,
                        ),
                        borderSide: const BorderSide(
                          color: RpgColors.rpgCrimson,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Quest title cannot be empty';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),

                  // Quest Category Selection
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.habitCategories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return RpgGemstoneBadge(
                        label: cat,
                        icon: _getCategoryIcon(cat),
                        color: isSelected ? currentColor : RpgColors.rpgIndigo,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Accent Gemstone Color Picker
                  const Text(
                    'Gemstone Color',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: AppConstants.availableColors.map((colorVal) {
                      final isSelected = _selectedColor == colorVal;
                      final gemColor = Color(colorVal);

                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = colorVal),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: gemColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white24,
                              width: isSelected ? 3.0 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: gemColor.withValues(
                                  alpha: isSelected ? 0.6 : 0.2,
                                ),
                                blurRadius: isSelected ? 10 : 4,
                                spreadRadius: isSelected ? 2 : 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  RpgFilledButton(
                    label: isEditing ? 'Save Quest' : 'Forge Quest',
                    icon: Icons.check_circle_rounded,
                    backgroundColor: currentColor,
                    onPressed: _submit,
                    width: double.infinity,
                    height: 50.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
