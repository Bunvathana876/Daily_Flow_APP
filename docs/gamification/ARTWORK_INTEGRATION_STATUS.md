# DailyFlow 3.0 — Artwork Integration Status Report

**Status:** Readiness Prepared for Artwork Ingestion  
**Design Reference:** `design/references/dailyflow-cozy-rpg.png`  
**Specification:** `docs/gamification/COZY_RPG_ASSET_SPECIFICATION.md`  
**Target Asset Directory:** `assets/images/`

---

## 1. Executive Summary

The DailyFlow 3.0 Cozy Adventure RPG design foundation has been fully prepared to receive official artwork assets. 
- `pubspec.yaml` has the `assets/images/` directory registered.
- Key presentation widgets (`HeroAvatarFrame`, `CozyBackgroundScaffold`, `CozyArtwork`) are equipped with graceful, non-crashing procedural gradient and vector fallbacks.
- When valid artwork binaries are added to `assets/images/`, the components will immediately render them without requiring any architectural changes.

---

## 2. Existing vs. Missing Artwork Inventory

| Asset Identifier | Canonical File Path | Status | Existing Fallback |
| :--- | :--- | :--- | :--- |
| **Hero Portrait** | `assets/images/hero_portrait_default.png` | **Missing** (Empty directory) | Procedural dark indigo/violet gradient with class crest / shield icon (`HeroAvatarFrame`) |
| **Fantasy Village Background** | `assets/images/bg_fantasy_village.png` | **Missing** (Empty directory) | Procedural twilight landscape gradient (`#281F48` to `#0B1224`) + radial lantern glow (`CozyBackgroundScaffold`) |
| **Quest Journal Icon** | `assets/images/icon_quest_journal.png` | **Missing** (Empty directory) | Warm amber pill with `Icons.auto_stories_rounded` (`CozyArtwork.questJournal`) |
| **Adventure Chest** | `assets/images/chest_adventure.png` | **Missing** (Empty directory) | Sculpted bevel container with `Icons.inventory_2_rounded` (`CozyArtwork.adventureChest`) |
| **Focus Room Background** | `assets/images/bg_focus_chamber.png` | **Missing** (Empty directory) | Fullscreen twilight ambient canvas with golden lantern lighting (`CozyBackgroundScaffold`) |

*Note: In `assets/icons/`, `app_icon.png` (5.5 MB) and `icon_todo B.png` (5.5 MB) are legacy icons slated for compression in Phase 6, but no RPG game illustrations currently exist in `assets/images/`.*

---

## 3. Required File Specifications

### 3.1 Hero Portrait
- **Target Filename:** `hero_portrait_default.png`
- **Location:** `assets/images/hero_portrait_default.png`
- **Dimensions:** 512 × 512 px (@3x retina display)
- **Format:** 24-bit PNG with transparent alpha background.
- **Composition:** Centered bust portrait (head & shoulders) of an approachable adventurer with wind-swept dark hair and warm amber/gold lighting accents (matching *Bun Vathana* in the approved design).
- **Usage:**
  - Home Screen Hero XP HUD inside `HeroAvatarFrame` (76 × 76 px).
  - Profile Screen Header inside `HeroAvatarFrame` (88 × 88 px).
  - Insights Screen "Your Journey" summary card (48 × 48 px).

### 3.2 Fantasy Village Background
- **Target Filename:** `bg_fantasy_village.png`
- **Location:** `assets/images/bg_fantasy_village.png`
- **Dimensions:** 1080 × 720 px (landscape ratio)
- **Format:** Lossless PNG or WebP (< 250 KB recommended).
- **Composition:** Sunset fantasy riverside landscape with cobblestone bridges, distant fairy-tale castle spires, and warm glowing lanterns. The lower 40% must fade to deep Midnight Navy (`#0B1224`) to ensure foreground quest cards and HUD stats remain 100% legible.
- **Usage:**
  - Home Screen top backdrop (280 px height) in `CozyBackgroundScaffold`.
  - Profile Screen top character sanctuary backdrop.

### 3.3 Quest Journal Icon
- **Target Filename:** `icon_quest_journal.png`
- **Location:** `assets/images/icon_quest_journal.png`
- **Dimensions:** 256 × 256 px
- **Format:** 24-bit PNG with transparent alpha background.
- **Composition:** Leatherbound grimoire or adventurer's field diary with golden bookmarks and brass clasps, bathed in soft warm light.
- **Usage:**
  - Study Quest cards ("Study Code").
  - Linked Quest indicator card on the Focus screen.

### 3.4 Adventure Chest
- **Target Filename:** `chest_adventure.png`
- **Location:** `assets/images/chest_adventure.png`
- **Dimensions:** 256 × 256 px
- **Format:** 24-bit PNG with transparent alpha background.
- **Composition:** 3/4 isometric perspective wooden treasure chest with polished gold reinforcement bands and a radiant interior glow.
- **Usage:**
  - Daily Bounty card on the Home Screen (trailing objective reward).
  - Milestone claim modals.

### 3.5 Focus Room Background
- **Target Filename:** `bg_focus_chamber.png`
- **Location:** `assets/images/bg_focus_chamber.png`
- **Dimensions:** 1080 × 960 px (portrait/arched ratio)
- **Format:** Lossless PNG or WebP (< 300 KB recommended).
- **Composition:** Cozy attic study overlooking an arched stone window. Warm lantern on the windowsill, old spellbooks, and a steaming ceramic mug.
- **Usage:**
  - Fullscreen backdrop on the Focus Chamber screen behind the Arcane Timer Ring.

---

## 4. Recommended Mobile Image Optimization Pipeline

To prevent APK/IPA bloat and ensure 60fps rendering without jank on lower-end mobile devices:
1. **Format Selection:**
   - Use **WebP** (lossless or 90% quality) or compressed **PNG-24** with `pngquant`.
   - Avoid uncompressed 32-bit bitmaps or multi-megabyte raw exports.
2. **Resolution Guidelines:**
   - Avoid exceeding 1080px in width. Flutter will downsample for device pixel density, and exceeding this causes excessive GPU texture memory usage.
3. **Asset Registration in `pubspec.yaml`:**
   Already configured under the `assets:` section:
   ```yaml
   flutter:
     uses-material-design: true
     assets:
       - assets/icons/
       - assets/images/
   ```
4. **Pre-caching Recommendation (for Phase 2):**
   In `main.dart` or during the splash screen sequence, pre-cache the village backdrop and hero portrait:
   ```dart
   precacheImage(const AssetImage(CozyArtwork.bgFantasyVillage), context);
   precacheImage(const AssetImage(CozyArtwork.heroPortraitDefault), context);
   ```

---

## 5. Architectural Safety Verification

- Zero changes were made to SQLite database migrations or schema tables.
- Zero modifications were made to the XP engine, streak calculation, or Riverpod controllers.
- All widgets gracefully handle missing files using `Image.asset(..., errorBuilder: ...)` and procedural fallbacks.
- Test suite expanded to 151 tests with 100% pass rate.
