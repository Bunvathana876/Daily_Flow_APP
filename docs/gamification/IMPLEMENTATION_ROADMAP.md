# Gamification Phased Implementation Roadmap: DailyFlow

This roadmap breaks down the transformation of **DailyFlow** into a Cozy RPG productivity application into six discrete, independently testable phases.

---

## Roadmap Overview

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        PHASED EXECUTION PIPELINE                       │
├────────────────────────────────────────────────────────────────────────┤
│  Phase 1: Database v3, XP Ledger & Gamification Math Engine            │
│  Phase 2: Cozy RPG Design System & Theme Engine                        │
│  Phase 3: Quest Log & Interactive Quest Tiles (Today Tab)             │
│  Phase 4: Focus Chamber & Resilient Timestamp Timer                   │
│  Phase 5: Hero's Armory, Player Profile & Achievement Tree            │
│  Phase 6: Hall of Records & Polish (Celebrations & Reduced Motion)     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Database v3, XP Ledger & Gamification Math Engine

**Goal:** Establish persistent, anti-farming gamification data structures in SQLite and deterministic math utilities with 100% test coverage before touching any UI.

### Tasks:
1. **Enable SQLite Foreign Keys**: Update `openDatabase` in `lib/core/database/db_helper.dart` with `onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON;')`.
2. **Schema v3 Migration**: Implement `_onUpgrade` for `oldVersion < 3`:
   - Create `xp_ledger` table with indices.
   - Create `user_profile` table.
   - Create `achievements` table.
   - Add `is_archived` column to `habits`.
   - Backfill historical XP from existing `habit_logs`.
3. **Domain Models**:
   - Create `lib/features/gamification/models/user_profile.dart`.
   - Create `lib/features/gamification/models/xp_entry.dart`.
   - Create `lib/features/gamification/models/achievement.dart`.
4. **Gamification Math Utilities**:
   - Create `lib/core/utils/gamification_math.dart` implementing:
     - `calculateLevel(int totalXp)`
     - `xpRequiredForLevel(int level)`
     - `calculateStreakBonus(int streak)`
     - `xpProgressInCurrentLevel(int totalXp)`
5. **Data Repositories & Controllers**:
   - Create `lib/features/gamification/data/gamification_repository.dart`.
   - Create `lib/features/gamification/controllers/gamification_controller.dart`.

### Affected Files:
- [`lib/core/database/db_helper.dart`](file:///Users/bunvathana/Documents/Code/Project/daily_flow/lib/core/database/db_helper.dart)
- `lib/core/utils/gamification_math.dart` (New)
- `lib/features/gamification/models/user_profile.dart` (New)
- `lib/features/gamification/models/xp_entry.dart` (New)
- `lib/features/gamification/models/achievement.dart` (New)
- `lib/features/gamification/data/gamification_repository.dart` (New)
- `lib/features/gamification/controllers/gamification_controller.dart` (New)
- `test/gamification_math_test.dart` (New)
- `test/xp_ledger_test.dart` (New)

### Acceptance Criteria:
- `flutter test` passes with zero regressions.
- Existing habits and completions remain 100% intact.
- XP cannot be duplicated by rapid on/off toggling.

---

## Phase 2: Cozy RPG Design System & Theme Engine

**Goal:** Deliver the RPG color palette, typography scale, buttons, and design tokens without altering business logic.

### Tasks:
1. **Design Tokens**: Create `lib/core/theme/rpg_colors.dart` and `lib/core/theme/rpg_text_styles.dart`.
2. **Theme Configuration**: Refactor `lib/core/theme/app_theme.dart` with Abyss Navy (`#0B0F19`), Arcane Violet (`#8B5CF6`), Radiant Gold (`#F59E0B`), and M3 dark/light palettes.
3. **Persistent Theme Controller**: Add `shared_preferences` to persist theme choices across app launches.
4. **Reusable RPG Components**:
   - `lib/core/widgets/rpg_card.dart`
   - `lib/core/widgets/rpg_filled_button.dart`
   - `lib/core/widgets/kpi_stat_card.dart`
5. **Haptics Master Service**: Create `lib/core/services/haptics_service.dart` to respect user settings globally.

### Affected Files:
- `pubspec.yaml` (Add `shared_preferences`)
- [`lib/core/theme/app_theme.dart`](file:///Users/bunvathana/Documents/Code/Project/daily_flow/lib/core/theme/app_theme.dart)
- [`lib/core/theme/theme_provider.dart`](file:///Users/bunvathana/Documents/Code/Project/daily_flow/lib/core/theme/theme_provider.dart)
- `lib/core/theme/rpg_colors.dart` (New)
- `lib/core/services/haptics_service.dart` (New)
- `lib/core/widgets/rpg_card.dart` (New)
- `lib/core/widgets/rpg_filled_button.dart` (New)

---

## Phase 3: Quest Log & Interactive Quest Tiles (Today Tab)

**Goal:** Transform the home screen into the **Daily Quest Log** with the Hero XP HUD and interactive 48px touch targets.

### Tasks:
1. **Hero XP HUD**: Build the animated top header displaying Player Level, Avatar, Rank, and XP bar.
2. **Daily Bounty Progress Card**: Replace `WeeklyOverviewCard` with a Daily Bounty completion card showing progress toward today's clean sheet.
3. **Quest Tiles (`HabitTile` Redesign)**:
   - Shield checkmark with micro-burst.
   - XP reward tags (`+20 XP`, `+35 XP`).
   - 48x48px touch target bounds on 7-day runic circles.
4. **Draggable New Quest Sheet**: Replace `HabitFormDialog` with a modern, keyboard-safe `QuestFormSheet` including title validation.
5. **Tie Check-in to XP Ledger**: On habit check, call `gamificationController.awardHabitCheckin(...)`.

### Affected Files:
- [`lib/features/habits/screen/home_screen.dart`](file:///Users/bunvathana/Documents/Code/Project/daily_flow/lib/features/habits/screen/home_screen.dart)
- [`lib/features/habits/screen/widgets/habit_tile.dart`](file:///Users/bunvathana/Documents/Code/Project/daily_flow/lib/features/habits/screen/widgets/habit_tile.dart)
- [`lib/features/habits/screen/widgets/habit_form_dialog.dart`](file:///Users/bunvathana/Documents/Code/Project/daily_flow/lib/features/habits/screen/widgets/habit_form_dialog.dart)
- `lib/features/habits/screen/widgets/daily_bounty_card.dart` (New)
- `lib/features/habits/screen/widgets/hero_xp_hud.dart` (New)

---

## Phase 4: Focus Chamber & Resilient Timestamp Timer

**Goal:** Transform the Focus screen into an arcane trial chamber with a timer that survives backgrounding and screen locks.

### Tasks:
1. **Timestamp-Based Timer Engine**: Switch from `Timer.periodic` decrement to `targetEndTime.difference(DateTime.now())`.
2. **Arcane Countdown Ring**: Double-ring circular indicator with smooth visual pulse and glow matching active habit's gemstone color.
3. **Focus XP Awards**: On session conclusion, write `FOCUS_SESSION` XP into the ledger (1 XP / min) and auto-complete the linked habit for today.
4. **Completion Haptics & Reward Sheet**: Victory modal displaying time focused and XP gained.

### Affected Files:
- [`lib/features/focus/screen/focus_screen.dart`](file:///Users/bunvathana/Documents/Code/Project/daily_flow/lib/features/focus/screen/focus_screen.dart)
- `lib/features/focus/widgets/arcane_timer_ring.dart` (New)

---

## 5. Phase 5: Hero's Armory, Player Profile & Achievement Tree

**Goal:** Create a rewarding character progression dashboard and dynamic achievement trophy room.

### Tasks:
1. **Dynamic Character Hub**: Render actual player level, title rank, total check-ins, and customizable avatar.
2. **Achievement Tree & Badge Grid**:
   - Render locked/unlocked state dynamically from the `achievements` SQLite table.
   - Implement real-time unlock checks upon completing habits or focus sessions.
3. **Badge Lore Modal**: Tapping any badge reveals its backstory, criteria, and XP reward.
4. **Traveler's Settings**: Wire up settings persistence, real haptics switch, and clean legacy shims.

### Affected Files:
- [`lib/features/profile/screen/profile_screen.dart`](file:///Users/bunvathana/Documents/Code/Project/daily_flow/lib/features/profile/screen/profile_screen.dart)
- [`lib/features/settings/screen/settings_screen.dart`](file:///Users/bunvathana/Documents/Code/Project/daily_flow/lib/features/settings/screen/settings_screen.dart)
- `lib/features/gamification/widgets/achievement_badge_tile.dart` (New)
- `lib/features/gamification/widgets/achievement_detail_modal.dart` (New)

---

## 6. Phase 6: Hall of Records & Celebratory Polish

**Goal:** Redesign analytics into the ancient Hall of Records and add smooth celebrations with reduced-motion support.

### Tasks:
1. **Mosaic Heatmap**: Polish the 84-day grid with runic styling, color luminosity scaling, and golden sparkles on 100% days.
2. **Battle Rhythm (Mana Pillars)**: Weekday bar chart styled as glowing vertical energy pillars with a golden crown for the top day.
3. **Level-Up Celebration Modal**: Celebratory modal with rank badge and confetti.
4. **Reduced-Motion Integration**: Wrap all celebratory effects with `MediaQuery.of(context).disableAnimations` guards.
5. **Asset Optimization**: Compress 5.5MB icons into lightweight mobile assets.

### Affected Files:
- [`lib/features/analytics/screen/stats_screen.dart`](file:///Users/bunvathana/Documents/Code/Project/daily_flow/lib/features/analytics/screen/stats_screen.dart)
- `lib/features/gamification/widgets/level_up_dialog.dart` (New)
- `assets/icons/app_icon.png` (Optimized)

---

## 7. Recommended First Implementation Task

### **Task: Phase 1 — Database v3 Schema, Gamification Models & Anti-Farming XP Engine**

**Scope:**
1. Update [`DBHelper`](file:///Users/bunvathana/Documents/Code/Project/daily_flow/lib/core/database/db_helper.dart) with `onConfigure` to enforce SQLite foreign keys (`PRAGMA foreign_keys = ON;`).
2. Add the safe, transactional SQLite `version: 3` migration with historical XP backfill so existing users immediately unlock their true starting level.
3. Create domain models (`UserProfile`, `XpEntry`, `Achievement`).
4. Implement the deterministic mathematical formulas in `GamificationMath` (`calculateLevel`, `calculateStreakBonus`).
5. Write complete unit tests in `test/gamification_math_test.dart` and `test/xp_ledger_test.dart` to verify zero regression and anti-farming protection.

*This foundation introduces zero UI risk, guarantees existing data safety, and prepares the backend data structures required by all upcoming RPG views.*
