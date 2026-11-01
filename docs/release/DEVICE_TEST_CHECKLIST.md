# DailyFlow — Manual Device QA Checklist

**Target Version:** 1.0.0 (Release Candidate)  
**Platforms:** Android (API 26+) & iOS (iOS 15+)  
**Purpose:** Complement automated test suites with physical hardware validation.

---

## 1. Automated Testing vs. Physical Device Matrix

| Capability | Automated Test Coverage | Physical Device Requirement | Rationale |
| :--- | :---: | :---: | :--- |
| **Logic & Math** | 100% | Optional | XP calculation, leveling curves, streak counting are fully verified in headless VM tests. |
| **Database Migrations** | 100% | Optional | Tested across SQLite versions using `sqflite_common_ffi`. |
| **UI Rendering & State** | 100% | Smoke Test | Widget layout and navigation are verified across test viewports. |
| **Physical Haptics** | Simulated via Callback | **MANDATORY** | Simulators and headless environments do not actuate ERM or linear resonant haptic motors. |
| **Background Timer** | Virtual Elapsed Clock | **MANDATORY** | Validates aggressive OS battery management (e.g. Android Doze, iOS Background App Refresh). |
| **Safe Area & Notches** | Mock Viewport | **MANDATORY** | Confirms layout clearance for Dynamic Island, sensor notches, and system gesture bars. |
| **Accessibility Scaling** | MediaQuery Mocking | **MANDATORY** | Verifies text readability at maximum system font scale (1.5x–2.0x) on small displays. |

---

## 2. Pre-Test Device Preparation

- [ ] Install release build on an Android physical device (e.g. Pixel, Samsung Galaxy).
- [ ] Install release build on an iOS physical device (e.g. iPhone with Dynamic Island or Face ID notch).
- [ ] Verify test device has internet connectivity disabled during testing to confirm 100% offline functionality.
- [ ] Ensure device battery is above 20% to avoid extreme low-power mode interference.

---

## 3. Physical Device Test Cases

### 3.1 Fresh Launch & Onboarding
- [ ] **TC-01: Splash Screen Transition**
  - Launch app from cold start.
  - **Expected:** Animated logo fades in smoothly and transitions cleanly to `MainShell` without white flash or jank.
- [ ] **TC-02: Default Profile Initialization**
  - Navigate to Profile tab ("Hero's Armory").
  - **Expected:** Default Hero "DailyFlow Champion", Level 1, 0 XP, Knight's Helm avatar displayed with zero errors.

---

### 3.2 Quest Dashboard & Habit Management
- [ ] **TC-03: Create New Quest**
  - Tap "+" Floating Action Button. Enter quest title: "Morning Run", select category "Health", pick a color, tap "Create Quest".
  - **Expected:** Quest card appears immediately in the Today tab list with category tag and XP reward badge (+15 XP).
- [ ] **TC-04: Check-in Haptic Feedback**
  - Tap the shield checkmark button on "Morning Run".
  - **Expected:** A crisp, satisfying medium vibration is felt on the device. Checkmark animates with emerald radial burst. Hero XP increases by 15.
- [ ] **TC-05: Anti-Farming Verification**
  - Tap the checkmark button 5 times rapidly.
  - **Expected:** Haptics respond cleanly. Total XP alternates between +15 and 0. No duplicate entries or runaway XP increments occur.
- [ ] **TC-06: Daily Milestone Toast ("Flawless Victory")**
  - Complete all displayed habits for today.
  - **Expected:** A non-blocking golden celebration toast appears ("Flawless Victory: All daily quests completed for today!"). Two light haptic pulses fire.
- [ ] **TC-07: Habit Deletion and Undo**
  - Open habit detail screen, tap Delete, confirm deletion.
  - **Expected:** Habit deleted. Tap "Undo" on the bottom SnackBar. Habit is immediately restored with intact streak history.

---

### 3.3 Focus Chamber (Pomodoro)
- [ ] **TC-08: Focus Countdown Display**
  - Navigate to Focus tab. Select "Morning Run" quest. Tap "Start Focus".
  - **Expected:** Arcane double ring begins pulsing smoothly. Digital countdown decrements second-by-second.
- [ ] **TC-09: Background Sleep Resilience (Crucial)**
  - Start a 25-minute focus session.
  - Lock the device screen (or switch to home screen) for 3 minutes.
  - Re-open the app.
  - **Expected:** Timer reflects exact real-world elapsed time (e.g. 22:00 remaining). Countdown did not pause or drift during background sleep.
- [ ] **TC-10: Session Completion & Victory Modal**
  - Let a 1-minute test focus session complete to 00:00.
  - **Expected:** Device vibrates with distinct victory pattern. `FocusVictoryDialog` modal appears displaying earned XP (+1 XP per minute) and updates hero level.

---

### 3.4 Hero's Armory (Profile & Achievements)
- [ ] **TC-11: Customize Hero Name & Crest**
  - Tap edit icon beside Hero Name. Change name to "Shadow Paladin", select "Paladin's Crest", tap "Save Hero".
  - **Expected:** Hero Card updates instantly with custom name and crest. Persists across app restart.
- [ ] **TC-12: Character Length Validation**
  - Attempt to enter empty name or name > 24 characters.
  - **Expected:** Inline error message displays; dialog prevents saving.
- [ ] **TC-13: Interactive Achievement Details Modal**
  - Tap any locked or unlocked achievement tile (e.g. "Flame Keeper").
  - **Expected:** Bottom modal opens showing lore description, progress bar (e.g. "7 / 7 Streak Days"), XP reward tag, and unlock date.
- [ ] **TC-14: Path Filter Chips**
  - Tap "Warrior's Path", "Scholar's Path", and "Architect's Path" tabs.
  - **Expected:** Badge list filters instantly by category without lag.

---

### 3.5 Hall of Records (Insights & Heatmap)
- [ ] **TC-15: 12-Week Consistency Heatmap**
  - Navigate to Insights tab.
  - **Expected:** 84-day grid renders smoothly with proper column spacing. Completed dates highlight in radiant gold or violet luminosity.
- [ ] **TC-16: Heatmap Tooltip Touch**
  - Tap and hold on any individual heatmap cell.
  - **Expected:** Tooltip appears displaying date and completion rate (e.g. "2026-10-31: 100% completed").
- [ ] **TC-17: Weekday Mana Pillars**
  - Inspect Weekday Performance bar chart.
  - **Expected:** Bar heights correspond to actual percentage rates. Golden crown icon sits atop the highest completion weekday.
- [ ] **TC-18: XP Reward Sources Breakdown**
  - Inspect XP Progression card.
  - **Expected:** Numbers accurately mirror check-in XP, focus XP, and achievement XP.

---

### 3.6 Settings & System Compatibility
- [ ] **TC-19: Dark / Light Mode Switching**
  - Toggle between Dark, Light, and System modes in Settings.
  - **Expected:** Entire UI updates instantly. In Dark mode, deep Abyss Navy (`#0B0F19`) is rendered; in Light mode, crisp high-contrast theme is applied.
- [ ] **TC-20: Haptics Toggle**
  - Turn off "Haptic Feedback" in Settings. Return to Today tab and complete a habit.
  - **Expected:** Habit checkmark updates visually, but device does NOT vibrate.
- [ ] **TC-21: Sound Effects Toggle**
  - Toggle "Sound Effects" switch.
  - **Expected:** Preference saves immediately to SharedPreferences without error.
- [ ] **TC-22: System Font Scaling (Accessibility 2.0x)**
  - In device OS settings, set font size to Maximum / Largest.
  - Open DailyFlow and inspect all 4 tabs.
  - **Expected:** Text scales up legibly. No text truncation of critical numbers. No `RenderFlex` overflow errors.
- [ ] **TC-23: App Kill & Relaunch State**
  - Force kill the application from the device multitasking tray.
  - Relaunch the app.
  - **Expected:** All habits, logs, XP, player level, custom avatar, and settings remain 100% intact.

---

## 4. Sign-Off Record

| Tester Name | Device Model | OS Version | Pass Rate | Date | Sign-off |
| :--- | :--- | :--- | :---: | :---: | :---: |
| *Pending QA* | Google Pixel / Galaxy | Android 14 / 15 | ___% | __/__/2026 | [ ] |
| *Pending QA* | iPhone 14/15/16 Pro | iOS 17 / 18 | ___% | __/__/2026 | [ ] |
