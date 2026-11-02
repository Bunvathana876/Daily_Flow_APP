import 'package:flutter/material.dart';
import '../../../core/theme/rpg_colors.dart';
import '../models/hero_rank_tier.dart';

class AvatarCrestInfo {
  final String id;
  final String title;
  final String role;
  final IconData icon;
  final LinearGradient gradient;
  final String assetPath;

  const AvatarCrestInfo({
    required this.id,
    required this.title,
    required this.role,
    required this.icon,
    required this.gradient,
    this.assetPath = '',
  });
}

class HeroAvatarRegistry {
  static const List<AvatarCrestInfo> crests = [
    AvatarCrestInfo(
      id: 'knight_helm',
      title: 'Knight of Valor',
      role: 'Guardian',
      icon: Icons.shield_rounded,
      gradient: RpgColors.violetGradient,
      assetPath: 'assets/images/hero/knight_of_valor.png',
    ),
    AvatarCrestInfo(
      id: 'arcane_mage',
      title: 'Arcane Sorcerer',
      role: 'Scholar',
      icon: Icons.auto_awesome_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      assetPath: 'assets/images/hero/arcane_sorcerer.png',
    ),
    AvatarCrestInfo(
      id: 'ranger_hood',
      title: 'Woodland Ranger',
      role: 'Scout',
      icon: Icons.nature_people_rounded,
      gradient: RpgColors.emeraldGradient,
      assetPath: 'assets/images/hero/woodland_ranger.png',
    ),
    AvatarCrestInfo(
      id: 'paladin_crest',
      title: 'Radiant Paladin',
      role: 'Champion',
      icon: Icons.workspace_premium_rounded,
      gradient: RpgColors.goldGradient,
      assetPath: 'assets/images/hero/radiant_paladin.png',
    ),
    AvatarCrestInfo(
      id: 'valkyrie_wings',
      title: 'Sky Valkyrie',
      role: 'Vanguard',
      icon: Icons.military_tech_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      assetPath: 'assets/images/hero/sky_valkyrie.png',
    ),
    AvatarCrestInfo(
      id: 'shadow_blade',
      title: 'Shadow Rogue',
      role: 'Infiltrator',
      icon: Icons.bolt_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      assetPath: 'assets/images/hero/shadow_rogue.png',
    ),
  ];

  static AvatarCrestInfo getCrest(String? id) {
    return crests.firstWhere((c) => c.id == id, orElse: () => crests.first);
  }
}

/// Circular crest badge displaying the player's chosen RPG avatar symbol,
/// enhanced with rank-based visual tier frames (Bronze, Silver, Gold, Platinum, Diamond).
class HeroAvatarBadge extends StatelessWidget {
  final String avatarId;
  final double size;
  final VoidCallback? onTap;
  final bool showEditOverlay;
  final int? playerLevel;
  final HeroRankTier? rankTier;

  const HeroAvatarBadge({
    super.key,
    required this.avatarId,
    this.size = 64.0,
    this.onTap,
    this.showEditOverlay = false,
    this.playerLevel,
    this.rankTier,
  });

  @override
  Widget build(BuildContext context) {
    final crest = HeroAvatarRegistry.getCrest(avatarId);
    final tier =
        rankTier ??
        (playerLevel != null ? HeroRankTier.fromLevel(playerLevel!) : null);

    final innerSize = tier != null ? size * 0.78 : size;

    Widget badgeContent = Container(
      width: innerSize,
      height: innerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: crest.gradient,
        boxShadow: [
          BoxShadow(
            color: crest.gradient.colors.first.withValues(alpha: 0.35),
            blurRadius: innerSize * 0.22,
            offset: Offset(0, innerSize * 0.06),
          ),
        ],
      ),
      child: crest.assetPath.isNotEmpty
          ? Padding(
              padding: EdgeInsets.all(innerSize * 0.08),
              child: Image.asset(
                crest.assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(
                    crest.icon,
                    color: Colors.white,
                    size: innerSize * 0.52,
                  ),
                ),
              ),
            )
          : Center(
              child: Icon(
                crest.icon,
                color: Colors.white,
                size: innerSize * 0.52,
              ),
            ),
    );

    Widget badge;
    if (tier != null) {
      badge = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: tier.frameGradient,
          boxShadow: [
            BoxShadow(
              color: tier.glowColor.withValues(alpha: 0.40),
              blurRadius: size * 0.25,
              offset: Offset(0, size * 0.05),
            ),
          ],
        ),
        padding: EdgeInsets.all(size * 0.055),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: RpgColors.abyssNavySurface,
          ),
          padding: EdgeInsets.all(size * 0.035),
          child: badgeContent,
        ),
      );
    } else {
      badge = badgeContent;
    }

    if (showEditOverlay) {
      badge = SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            badge,
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: RpgColors.rpgGold,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: RpgColors.abyssNavySurface,
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.black87,
                  size: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (onTap != null) {
      badge = Semantics(
        button: true,
        label: 'Hero Avatar Crest: ${crest.title}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: badge,
        ),
      );
    }

    return badge;
  }
}
