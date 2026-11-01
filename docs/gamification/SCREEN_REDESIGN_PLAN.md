# Screen-by-Screen Gamified UI Redesign Plan

This document details the visual, structural, and behavioral transformations for every screen in **DailyFlow**, translating the cozy RPG aesthetic into clean, responsive mobile layouts.

---

## 1. App Shell & Navigation Bar (`MainShell`)

### Current State:
Standard Material 3 `NavigationBar` with generic outlined icons (`Today`, `Insights`, `Focus`, `Profile`).

### Gamified Redesign:
- **Bar Styling**: Floating or frosted bottom nav with deep midnight background (`#161C2E`), subtle top border highlight (`#26304E`), and soft ambient glow.
- **Iconography & Thematic Nomenclature**:
  1. **Quests** (formerly *Today*): Shield emblem (`Icons.shield_outlined` / `Icons.shield_rounded`).
  2. **Records** (formerly *Insights*): Grimoire / Scroll (`Icons.menu_book_rounded` / `Icons.auto_stories_rounded`).
  3. **Focus** (formerly *Focus*): Hourglass / Arcane Orb (`Icons.hourglass_top_rounded` / `Icons.hourglass_full_rounded`).
  4. **Hero** (formerly *Profile*): Knight Helm / Crest (`Icons.military_tech_rounded` / `Icons.person_rounded`).
- **Active State Indicator**: Glowing arcane gemstone pill (`#6366F1` with 20% opacity) with active icon rendered in radiant white and category gem tint.
- **Haptics**: Tactile `selectionClick()` on every tab change.

---

## 2. Launch Splash Experience (`SplashScreen`)

### Current State:
Scales `assets/icons/app_icon.png` (5.5MB) with simple text "Build consistency, one day at a time".

### Gamified Redesign:
- **Visuals**:
  - Deep twilight gradient (`#0B0F19` to `#1E1B4B`).
  - Optimized, compressed emblem with a glowing aura.
  - Subtitle: *"Embark on your journey of mastery"*.
- **XP / Level Pre-warm**:
  - Initializes SQLite and computes current player level and XP in parallel with habit data loading.
  - Smooth fade into `MainShell` with no layout flicker.

---

## 3. Quests Screen (`HomeScreen` / `QuestLogScreen`)

```text
┌────────────────────────────────────────────────────────┐
│ [Avatar] Lv. 14 Knight of Habit          [🔥 12d Streak] │
│ XP: [████████████████░░░░░░] 740 / 1000 XP (+45 to Lv) │
├────────────────────────────────────────────────────────┤
│ 🏆 DAILY BOUNTY: 3 / 4 Quests Completed  (🎁 +50 XP)   │
├────────────────────────────────────────────────────────┤
│ [All] [⚔️ General] [🌿 Health] [📚 Study] [⚡ Coding]   │
├────────────────────────────────────────────────────────┤
│ 🛡️ Morning Meditation              [+20 XP] [🔥 8d]    │
│    Category: Health • Common Quest                     │
│    [M]  [T]  [W]  [T]  [F]  [S]  [S]                   │
│    (●)  (●)  (●)  (●)  (●)  (○)  ( )                   │
├────────────────────────────────────────────────────────┤
│ 🛡️ Read 20 Pages                  [+35 XP] [🔥 14d]   │
│    Category: Study • Veteran Quest (Streak Multiplier) │
│    [M]  [T]  [W]  [T]  [F]  [S]  [S]                   │
│    (●)  (●)  (●)  (●)  (●)  (●)  (●)  ✓ Completed    │
├────────────────────────────────────────────────────────┤
│                                     [ ⚔️ New Quest + ]  │
└────────────────────────────────────────────────────────┘
```

### Key UI Components:
1. **Hero Header (XP HUD)**:
   - Replaces the generic AppBar.
   - Shows player avatar, level badge (`Lv. X`), title rank, and an animated gradient XP bar with current progress.
2. **Daily Bounty Progress Card**:
   - Replaces `WeeklyOverviewCard`.
   - Displays today's completion ratio as a quest objective (e.g., *"3 of 5 Quests Completed — 2 remaining for the Clean Sheet +50 XP Bounty"*).
3. **Quest Filter Chips**:
   - Filter chips with fantasy/RPG icons (`⚔️ General`, `🌿 Health`, `📚 Study`, `⚡ Coding`, `🏃 Fitness`).
4. **RPG Quest Card (`HabitTile`)**:
   - **Interactive Checkmark**: A sculpted crest checkbox that fills with the quest's gemstone color upon completion.
   - **XP Tag**: Shows potential reward (`+20 XP` or `+35 XP` with streak bonus).
   - **7-Day Strip**: Upgraded touch targets (`48x48px` hit bounds) with circular runic dots (`M`, `T`, `W`, `T`, `F`, `S`, `S`). Completed days show a glowing gemstone dot.
   - **Completion Feedback**: Micro-burst of particles (disabled in reduced-motion mode) + tactile haptic response.

---

## 4. Hall of Records (`StatsScreen`)

### Current State:
KPI cards, 84-day heatmap, and weekday bar chart.

### Gamified Redesign:
1. **Hero KPI Banners**:
   - **Total Quests Vanquished**: Total check-in count with trophy icon.
   - **Legendary Streak**: All-time longest streak with blazing flame badge.
   - **Adventurer Rank**: Current title rank and unlocked badge count.
2. **Chronicle Heatmap (12-Week Consistency Grid)**:
   - Styled as an ancient mosaic or runic parchment.
   - Zero days: Dim slate tile.
   - Tier 1–4 completions: Progressive celestial blue/violet luminosity.
   - Full completion days: Radiant gold sparkle tile.
3. **Battle Rhythm (Weekday Bar Chart)**:
   - Displays completion rates as glowing magical mana pillars.
   - Top-performing day highlighted with a small golden crown.

---

## 5. Focus Chamber & Trials (`FocusScreen`)

### Current State:
Dropdown habit selector, duration chips, circular countdown indicator, Start/Pause buttons.

### Gamified Redesign:
1. **Atmosphere**:
   - Styled as a mystical meditation sanctum or arcane clockwork chamber.
2. **Linked Quest Selector**:
   - Card showing the habit being empowered by this focus session.
3. **Arcane Countdown Ring**:
   - Double-ring circular indicator with rotating runic particle accents.
   - Inside: Large digital timer (`25:00`) with ambient colored glow matching the habit's color.
   - Subtitle: *"Channeling focus for +25 XP"*.
4. **Wall-Clock Resilient Engine**:
   - Calculates time remaining using `targetEndTime.difference(DateTime.now())`, preventing pause on app backgrounding.
5. **Session Victory**:
   - When the timer hits `00:00`: Tactile celebratory double haptic, auto-checks off the linked habit for today, awards session XP into the ledger, and displays a victory reward sheet.

---

## 6. Hero's Profile & Armory (`ProfileScreen`)

### Current State:
Static card with hardcoded "DailyFlow Champion", static badge cards, category list.

### Gamified Redesign:
1. **Hero Character Card**:
   - Customizable player avatar / crest.
   - Dynamic Level, Rank Title, and Total Accumulated XP.
   - "Next Rank In: XXX XP" progress tracker.
2. **Trophy Room / Badges Showcase**:
   - Dynamic badge grid displaying unlocked vs. locked achievements across *The Warrior’s Path*, *The Scholar’s Path*, and *The Architect’s Path*.
   - Tapping any badge opens an **Achievement Modal** detailing:
     - Badge title & icon.
     - Lore description.
     - Progress bar (e.g., "7 / 30 Streak Days").
     - XP Reward value.
3. **Guild Statistics**:
   - Category distribution presented as hero skill affinities (e.g., *Level 4 in Study*, *Level 2 in Fitness*).

---

## 7. Quest Chronicle & Detail (`HabitDetailScreen`)

### Current State:
Top stat cards, month navigation, and numeric calendar days.

### Gamified Redesign:
1. **Quest Banner**:
   - Displays quest title, category gem, creation date, and total XP generated by this specific quest.
2. **Milestone Progress Bar**:
   - Shows progress toward the next streak milestone (e.g., *Day 18 / 30 for the "Iron Will" Badge*).
3. **Interactive Monthly Chronicle (Calendar)**:
   - Calendar grid where completed days appear as stamped wax seals or glowing runic gems.
   - Tapping any past date toggles completion state and automatically updates the XP ledger with proper audit records.

---

## 8. New Quest Bottom Sheet (`HabitFormDialog` Replacement)

### Current State:
Standard centered `AlertDialog` that fails silently if title is empty.

### Gamified Redesign:
- **Draggable Modal Bottom Sheet** (`showModalBottomSheet`):
  - Natural gesture-based dismissal on mobile.
  - Automatically raises above the keyboard.
- **Form Controls**:
  - `TextField` with helper text and explicit inline validation ("Quest title cannot be empty").
  - Category selector chips with thematic icons.
  - Color palette gemstone picker.
  - Projected XP preview: *"Grants +20 XP per completion"*.
