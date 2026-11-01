import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/haptics_service.dart';
import '../../../core/theme/rpg_colors.dart';
import '../../../core/theme/rpg_spacing.dart';
import '../../../core/widgets/rpg_filled_button.dart';
import '../../gamification/controllers/gamification_controller.dart';
import '../../gamification/widgets/hero_avatar_badge.dart';

/// Modal dialog allowing players to customize their Hero Name and Avatar Crest.
class HeroCustomizationDialog extends ConsumerStatefulWidget {
  final String initialName;
  final String initialAvatarId;

  const HeroCustomizationDialog({
    super.key,
    required this.initialName,
    required this.initialAvatarId,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentName,
    required String currentAvatarId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => HeroCustomizationDialog(
        initialName: currentName,
        initialAvatarId: currentAvatarId,
      ),
    );
  }

  @override
  ConsumerState<HeroCustomizationDialog> createState() =>
      _HeroCustomizationDialogState();
}

class _HeroCustomizationDialogState
    extends ConsumerState<HeroCustomizationDialog> {
  late final TextEditingController _nameController;
  late String _selectedAvatarId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedAvatarId = widget.initialAvatarId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _errorMessage = 'Hero name cannot be empty.';
      });
      return;
    }

    if (trimmed.length > 24) {
      setState(() {
        _errorMessage = 'Hero name must be 24 characters or less.';
      });
      return;
    }

    ref.read(hapticsServiceProvider).mediumImpact();
    ref
        .read(gamificationControllerProvider.notifier)
        .updateProfile(heroName: trimmed, avatarId: _selectedAvatarId);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final crests = HeroAvatarRegistry.crests;
    final selectedCrest = HeroAvatarRegistry.getCrest(_selectedAvatarId);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(RpgSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? RpgColors.abyssNavySurface : Colors.white,
          borderRadius: BorderRadius.circular(RpgSpacing.radiusLg),
          border: Border.all(
            color: RpgColors.arcaneViolet.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: RpgColors.arcaneViolet.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: RpgColors.arcaneViolet.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: RpgColors.arcaneViolet,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Customize Hero',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active Avatar Live Preview Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(RpgSpacing.radiusMd),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    HeroAvatarBadge(avatarId: selectedCrest.id, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCrest.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedCrest.gradient.colors.first
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  selectedCrest.role.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: selectedCrest.gradient.colors.first,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• Live Preview',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Hero Name Input
              Text(
                'HERO NAME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? RpgColors.rpgGold : const Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                maxLength: 24,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter hero name',
                  errorText: _errorMessage,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RpgSpacing.radiusSm),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(RpgSpacing.radiusSm),
                    borderSide: const BorderSide(
                      color: RpgColors.arcaneViolet,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
              const SizedBox(height: 10),

              // Avatar Crest Selection
              Text(
                'SELECT AVATAR CREST',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? RpgColors.rpgGold : const Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 8),

              // 3-Column Medallion Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: crests.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final crest = crests[index];
                  final isSelected = _selectedAvatarId == crest.id;

                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: '${crest.title}, Role: ${crest.role}',
                    child: InkWell(
                      onTap: () {
                        ref.read(hapticsServiceProvider).selectionClick();
                        setState(() {
                          _selectedAvatarId = crest.id;
                        });
                      },
                      borderRadius: BorderRadius.circular(RpgSpacing.radiusMd),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? RpgColors.arcaneViolet.withValues(
                                  alpha: isDark ? 0.22 : 0.12,
                                )
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(
                            RpgSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? (isDark
                                      ? RpgColors.rpgGold
                                      : RpgColors.arcaneViolet)
                                : (isDark
                                      ? Colors.white12
                                      : Colors.grey.shade200),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color:
                                        (isDark
                                                ? RpgColors.rpgGold
                                                : RpgColors.arcaneViolet)
                                            .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HeroAvatarBadge(avatarId: crest.id, size: 38),
                            const SizedBox(height: 4),
                            Text(
                              crest.title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? (isDark
                                          ? Colors.white
                                          : RpgColors.arcaneViolet)
                                    : (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade700),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              crest.role,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? (isDark
                                          ? RpgColors.rpgGold
                                          : const Color(0xFFD97706))
                                    : (isDark
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RpgFilledButton(
                    label: 'Save Hero',
                    icon: Icons.check_rounded,
                    onPressed: _handleSave,
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
