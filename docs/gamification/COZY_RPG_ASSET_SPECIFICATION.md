# DailyFlow 3.0: Cozy Adventure RPG Asset Specification

**Document Version:** 1.0.0  
**Target Design Reference:** `design/references/dailyflow-cozy-rpg.png`  
**Status:** Artwork Planning Specification (Awaiting Commission / Asset Ingestion)

---

## 1. Executive Summary & Aesthetic Direction

The DailyFlow 3.0 visual transformation targets a **Cozy Adventure RPG** aesthetic:
- **Atmosphere:** Warm fantasy village landscapes, sunset twilight, ambient golden lantern lighting, clean compact UI cards, and soft purple/gold accents.
- **Rendering Style:** High-quality anime/stylized fantasy illustration with soft lighting gradients, clean silhouette edges, gentle shadows, and zero harsh neon glows.
- **Asset Integrity Rules:** No placeholder scraping from unlicensed web sources; all assets must be explicitly commissioned, licensed, or generated under reproducible prompt and vector pipelines. In the interim, DailyFlow's procedural gradient and vector fallback engines render full layouts without throwing runtime asset exceptions.

---

## 2. Master Asset Inventory & Specifications

| Asset Name | Target File Path | Target Resolution | Format & Transparency | Screen Usage | Fallback Implementation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Hero Portrait** | `assets/images/hero_portrait_default.png` | 512 × 512 px (@3x) | PNG (24-bit with alpha channel) | Home HUD, Profile Screen, Hero Armory | `HeroAvatarFrame` with procedurally drawn golden metallic bezel & role icon |
| **Fantasy Village Background** | `assets/images/bg_fantasy_village.png` | 1080 × 720 px (landscape) | PNG or WebP (Lossless, < 250 KB) | Home HUD Backdrop, Profile Sanctuary | `CozyBackgroundScaffold` with `RpgColors.cozyAtmosphereGradient` & lantern glow |
| **Quest Journal Icon** | `assets/images/icon_quest_journal.png` | 256 × 256 px | PNG (transparent background) | Quest Cards (Study), Bounty Card | `CozyIcons.categoryStudy` (`Icons.auto_stories_rounded`) |
| **Adventure Chest** | `assets/images/chest_adventure.png` | 256 × 256 px | PNG (transparent background) | Daily Bounty Progress Card | `CozyIcons.bountyChest` / `CustomPaint` bounty chest |
| **Focus Room Background** | `assets/images/bg_focus_chamber.png` | 1080 × 960 px (portrait/arched) | PNG or WebP (Lossless, < 300 KB) | Focus Screen Backdrop | Arched twilight window gradient with glowing lantern overlay |

---

## 3. Detailed Specifications per Asset

### 3.1 Hero Portrait (`hero_portrait_default.png`)
- **Visual Description:** Cozy anime-style young adventurer with dark wind-tousled hair, navy traveling coat with gold buckles, warm amber eye highlights, and an approachable, determined expression (matching *Bun Vathana* in the approved reference image).
- **Art Style:** Soft cell shading with painterly lighting; warm rim lighting along the left shoulder and hair.
- **Framing:** Bust shot (head and shoulders), centered, with transparent outer background for circular cropping inside `HeroAvatarFrame`.
- **Dimensions:** 512 × 512 px (min 300 DPI equivalent for retina mobile displays).
- **Additional Avatars for Armory:**
  - `hero_avatar_mage.png` (Arcane Scholar in violet robes)
  - `hero_avatar_ranger.png` (Woodland Scout with green cowl)
  - `hero_avatar_paladin.png` (Radiant Guardian in golden cuirass)
  - `hero_avatar_rogue.png` (Shadow Wanderer with feather cap)

### 3.2 Fantasy Village Background (`bg_fantasy_village.png`)
- **Visual Description:** A peaceful fantasy riverside village at sunset. Features cobblestone bridges, stone castle spires in the distance, warm lanterns hanging from wooden eaves, lush purple/emerald foliage, and soft pink/golden twilight clouds in the sky.
- **Color Grading:** Deep twilight navy (`#0B1224`) at the lower thirds, blending smoothly upward into soft indigo (`#1A2447`), warm amber (`#F99A5A`), and lavender clouds.
- **Composition:** Upper two-thirds holds the castle and sky horizon; lower third fades to transparent or dark navy (`#0B1224`) so foreground cards remain 100% legible.
- **Dimensions:** 1080 × 720 px (responsive height via `BoxFit.cover`).

### 3.3 Quest Journal Icon (`icon_quest_journal.png`)
- **Visual Description:** A leatherbound adventurer's field journal or spellbook with glowing golden bookmark ribbons, ornate brass corner clasps, and a soft magical aura.
- **Color Grading:** Warm leather amber (`#F99A5A`), antique brass (`#F3B74A`), and parchment cream.
- **Dimensions:** 256 × 256 px, centered, 24px padding border inside the bounding box.

### 3.4 Adventure Chest (`chest_adventure.png`)
- **Visual Description:** A polished wooden adventurer's chest with golden steel bands, open slightly to reveal glowing magical gemstone light and golden coins spilling out.
- **Color Grading:** Deep mahogany wood, gleaming gold (`#F3B74A`), and radiant violet/cyan particle sparkles.
- **Dimensions:** 256 × 256 px, 3/4 isometric perspective matching the Daily Bounty card in the reference image.

### 3.5 Focus Room Background (`bg_focus_chamber.png`)
- **Visual Description:** A quiet, cozy wooden wizard's study / attic room. An arched stone window looks out into a twilight starry sky and tranquil fantasy village. In the foreground windowsill: a glowing brass lantern casting warm light, stacked old spellbooks, and a ceramic mug with gentle steam rising.
- **Lighting Atmosphere:** Warm lantern light source on the left windowsill (`#F3B74A` at 30% warmth), deep peaceful twilight outside the window (`#0B1224` to `#2A1E4D`).
- **Dimensions:** 1080 × 960 px.

---

## 4. Ingestion Workflow & Pubspec Integration

When assets are ready:
1. Export clean PNG-24 assets with crushed pngquant compression into `assets/images/`.
2. Ensure `pubspec.yaml` contains:
   ```yaml
   flutter:
     assets:
       - assets/icons/
       - assets/images/
   ```
3. DailyFlow's `CozyBackgroundScaffold`, `HeroAvatarFrame`, and `DailyBountyCard` automatically detect the presence of these files and bind them with smooth fade-in transitions.
