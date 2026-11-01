# DailyFlow: Cozy RPG Design System

**Design Philosophy:** *Cozy RPG Adventure meets Modern Minimalist Mobile UI*  
**Tone & Mood:** Warm, rewarding, enchanting, clean, and distraction-free. Playful and celebratory without becoming childish, cartoonish, or cluttered.

---

## 1. Color Palette: The Twilight Realm

The palette balances deep midnight hues with vibrant magical gemstones and radiant gold.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        COZY RPG COLOR PALETTE                          │
├────────────────────────────────────────────────────────────────────────┤
│  Dark Backgrounds:    #0B0F19 (Abyss Navy)  |  #14192B (Dungeon Slate) │
│  Light Backgrounds:   #F8F9FE (Morning Mist) |  #ECEFFC (Parchment)     │
│  Primary Arcana:      #6366F1 (Indigo Rune) |  #8B5CF6 (Arcane Violet) │
│  Quest Emerald:       #10B981 (Ranger Green)|  #059669 (Forest Jade)   │
│  Flame Ruby:          #F43F5E (Dragon Rose) |  #EF4444 (Crimson Spark) │
│  Radiant Gold:        #F59E0B (Solar Amber) |  #FBBF24 (Crown Gold)    │
│  Celestial Cyan:      #06B6D4 (Mana Blue)   |  #38BDF8 (Sky Crystal)   │
└────────────────────────────────────────────────────────────────────────┘
```

### 1.1 Color Tokens & Semantics

| Token Name | Hex Value | Light / Dark Semantic Role |
| :--- | :--- | :--- |
| `rpgAbyss` | `#0B0F19` | Deepest dark background (Scaffold in Dark Mode) |
| `rpgSurfaceDark` | `#161C2E` | Primary card background in Dark Mode |
| `rpgSurfaceLight`| `#FFFFFF` | Primary card background in Light Mode |
| `rpgBorderDark` | `#26304E` | Subtle border stroke for Dark Mode cards |
| `rpgBorderLight`| `#E2E8F0` | Subtle border stroke for Light Mode cards |
| `rpgMist` | `#F8F9FE` | Clean crisp background for Light Mode |
| `rpgViolet` | `#8B5CF6` | Arcane energy / Magic / Focus timer active state |
| `rpgIndigo` | `#6366F1` | Primary brand accent / Main navigation indicator |
| `rpgGold` | `#F59E0B` | Experience points (XP), Player Rank, Level-up badges |
| `rpgGoldBright`| `#FBBF24` | Streak fire glow, Crown trophies, Golden quest stars |
| `rpgEmerald` | `#10B981` | Quest completion, Health habits, Success states |
| `rpgCyan` | `#06B6D4` | Focus chamber, Meditation, Study quests |
| `rpgCrimson` | `#F43F5E` | Urgent quests, Boss timers, Delete/Danger actions |

### 1.2 Gradients & Shaders
- **Hero Card Gradient**: `LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF312E81), Color(0xFF1E1B4B)])`
- **Gold Tier Gradient**: `LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)])`
- **XP Progress Bar**: `LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)])`
- **Streak Fire Ember**: `RadialGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)])`

---

## 2. Typography Scale

Clean sans-serif clarity (system default or Inter/Plus Jakarta Sans) elevated with expressive font weights and generous line heights.

```text
Display Large  : 32px / Bold (900)  — Level Up modals & Splash title
Headline Large : 24px / Bold (800)  — Hero Screen titles ("Quest Log", "Focus Chamber")
Headline Medium: 20px / Semi-bold (700) — Section headers & Category banners
Title Medium   : 16px / Semi-bold (600) — Habit / Quest titles
Body Medium    : 14px / Regular (400)   — Descriptions, subtitles, log dates
Label Large    : 12px / Bold (700)      — Badges, XP tags, streak counters (+0.5 letter-spacing)
Label Small    : 10px / Medium (500)    — 7-day mini-strip day codes, time stamps
```

---

## 3. Surface & Card Architecture (RPG Cards)

Instead of generic Material flat boxes, RPG surfaces introduce structured depth, crisp chamfered or rounded contours (`16px–20px`), subtle border highlights, and soft luminous glows.

### 3.1 Card Variants

1. **`QuestCard` (Standard Habit Tile)**
   - Rounded `18px` corners.
   - 1.5px subtle border (`rpgBorderDark` or `rpgBorderLight`).
   - When completed: shifts to a soft tinted background with an ambient border glow matching the quest's category color.
   - Interactive checkbox: Replaced with a **Shield / Crest Checkmark** with tactile micro-bounce.

2. **`HeroStatCard` (XP & Level Hub)**
   - Elevated container with deep indigo/violet gradient background.
   - Displays Player Avatar, Level Badge ("Lv. 14"), Rank Title ("Arcane Flow Adept"), and an animated dual-color XP progress bar.

3. **`ArtifactCard` (Achievements & Badges)**
   - Circular or shield-shaped icon container with a dual-ring border.
   - Locked: Desaturated slate with 30% opacity and a subtle lock glyph.
   - Unlocked: Vibrant gradient fill, subtle drop shadow, and golden sparkle accent.

---

## 4. Buttons & Interactive Controls

1. **`RpgFilledButton`**
   - Minimum height: `48px`.
   - Radius: `14px`.
   - Subtle top-edge inner highlight to simulate a sculpted fantasy stone or medallion.
   - State: Scale down to `0.96` on touch down (`GestureDetector` + `AnimatedScale`).

2. **`QuestChip` (Category Selector)**
   - Rounded pill (`20px`).
   - Selected: Solid category gemstone color with white bold label and soft drop shadow.
   - Unselected: Low-opacity slate with clear contrast.

3. **`FloatingRpgAction`**
   - Floating Action Button styled as a "New Quest" seal with a glowing sword/plus emblem and radial elevation.

---

## 5. Micro-Interactions & Haptics

All tactile feedback maps to in-game actions:

| Action | Haptic Type | Visual Animation |
| :--- | :--- | :--- |
| **Check off Quest** | `HapticFeedback.mediumImpact()` | Scale burst (`1.0 -> 1.15 -> 1.0`), burst of mini star particles |
| **Undo Quest Check** | `HapticFeedback.selectionClick()` | Smooth reverse fade & contraction |
| **Level-Up Reached** | `HapticFeedback.heavyImpact()` | Screen overlay banner, golden particle shower, badge unlock sound |
| **Streak Milestone** | Double `lightImpact()` | Flame icon glows with pulse animation |
| **Focus Challenge End** | Rhythmic double heavy impact | Circular progress explodes into victory crest |

---

## 6. Accessibility & Reduced-Motion Mode

1. **Touch Targets**: All interactive elements (especially the 7-day timeline buttons) guarantee a minimum touch target of **48x48 logical pixels** via invisible hit bounds (`HitTestBehavior.opaque`).
2. **Contrast Standards**: All text-to-background combinations meet or exceed **WCAG 2.1 AA** (minimum 4.5:1 for body copy, 3:1 for large headers and badges).
3. **Respecting Reduced Motion**:
   - Queries `MediaQuery.of(context).disableAnimations`.
   - When enabled: All scale bounces, particle confetti, and tween loops are automatically swapped for instantaneous state changes or subtle 100ms cross-fades.
4. **Haptics Master Switch**: All haptics pipe through a unified `HapticService` that checks the user's persistent preferences before dispatching platform calls.
