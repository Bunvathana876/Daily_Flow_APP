# Testing Strategy & Quality Assurance: DailyFlow Gamification

This document details the automated testing plan, test cases, and quality gates required to protect existing habit functionality while verifying all new gamification logic.

---

## 1. Testing Hierarchy & Coverage Objectives

```text
┌────────────────────────────────────────────────────────┐
│                   TEST COVERAGE TARGETS                │
├────────────────────────────────────────────────────────┤
│  1. Existing Regression Suite:       100% Pass Rate    │
│  2. Gamification & XP Math Unit:     100% Code Coverage│
│  3. Anti-Farming & Ledger Isolation: 100% Scenarios    │
│  4. Database v2 -> v3 Migration:     Deterministic Run │
│  5. Accessibility & Reduced Motion:  Golden & Semantics│
└────────────────────────────────────────────────────────┘
```

---

## 2. Regression Testing (Protecting Existing Functionality)

Before any new code merges, the existing test suite must run clean:
1. **`test/date_utils_test.dart`** (16 unit tests):
   - Current streak calculations.
   - Best streak calculations across month boundaries.
   - 7-day strip generation (`getLast7DaysWithLabels`).
   - Heatmap 84-day data generation.
   - Weekday rates (Monday–Sunday).
2. **`test/widget_test.dart`** (7 widget tests):
   - Rendering headers and category filter chips in the Today tab.
   - Theme toggle behavior.
   - Navigation between all four shell tabs.
   - Habit tile navigation to detail screen.
   - Splash screen transition.

---

## 3. New Gamification & XP Math Test Suite (`test/gamification_math_test.dart`)

### 3.1 Level Calculation & Formula Inverses

```dart
group('GamificationMath.calculateLevel', () {
  test('0 XP returns Level 1', () {
    expect(GamificationMath.calculateLevel(0), 1);
  });

  test('99 XP remains Level 1', () {
    expect(GamificationMath.calculateLevel(99), 1);
  });

  test('100 XP unlocks Level 2', () {
    expect(GamificationMath.calculateLevel(100), 2);
  });

  test('Higher levels match the polynomial curve 100 * (L - 1)^1.4', () {
    expect(GamificationMath.calculateLevel(264), 3);
    expect(GamificationMath.calculateLevel(466), 4);
    expect(GamificationMath.calculateLevel(701), 5);
    expect(GamificationMath.calculateLevel(2298), 10);
  });

  test('Level never decreases on XP addition (Monotonicity)', () {
    int prevLevel = 1;
    for (int xp = 0; xp <= 5000; xp += 25) {
      final level = GamificationMath.calculateLevel(xp);
      expect(level >= prevLevel, isTrue);
      prevLevel = level;
    }
  });
});
```

### 3.2 Streak Momentum Bonus Tests

```dart
group('GamificationMath.calculateStreakBonus', () {
  test('0 day streak gives 0 bonus XP', () {
    expect(GamificationMath.calculateStreakBonus(0), 0);
  });

  test('3 day streak gives 6 bonus XP', () {
    expect(GamificationMath.calculateStreakBonus(3), 6);
  });

  test('Caps at +15 XP for streaks >= 8 days', () {
    expect(GamificationMath.calculateStreakBonus(8), 15);
    expect(GamificationMath.calculateStreakBonus(50), 15);
  });
});
```

---

## 4. Anti-Farming & Ledger Idempotency Tests (`test/xp_ledger_test.dart`)

These tests verify that users cannot manipulate their level or farm XP by repeatedly checking and unchecking habits.

```dart
group('XpLedger Anti-Farming & Idempotency', () {
  late FakeXpRepository xpRepo;

  setUp(() {
    xpRepo = FakeXpRepository();
  });

  test('First check-in awards +20 XP', () async {
    await xpRepo.logHabitCheckin(habitId: 1, date: '2026-11-01');
    expect(await xpRepo.getTotalActiveXp(), 20);
  });

  test('Unchecking habit revokes +20 XP', () async {
    await xpRepo.logHabitCheckin(habitId: 1, date: '2026-11-01');
    await xpRepo.revokeHabitCheckin(habitId: 1, date: '2026-11-01');
    expect(await xpRepo.getTotalActiveXp(), 0);
  });

  test('Repeated toggling (Farm Attack) does NOT multiply XP', () async {
    // Simulate user toggling check-in 10 times in a row
    for (int i = 0; i < 10; i++) {
      await xpRepo.logHabitCheckin(habitId: 1, date: '2026-11-01');
      await xpRepo.revokeHabitCheckin(habitId: 1, date: '2026-11-01');
    }
    // Final check
    await xpRepo.logHabitCheckin(habitId: 1, date: '2026-11-01');
    
    // User should have exactly 20 XP, NOT 200 XP
    expect(await xpRepo.getTotalActiveXp(), 20);
  });

  test('Backdated completion on previous day logs with correct event_date', () async {
    await xpRepo.logHabitCheckin(habitId: 1, date: '2026-10-31');
    final record = await xpRepo.getRecord(habitId: 1, date: '2026-10-31');
    expect(record.eventDate, '2026-10-31');
    expect(record.xpAmount, 20);
  });
});
```

---

## 5. Database v2 to v3 Migration Verification (`test/db_migration_test.dart`)

```dart
test('Migrates v2 database with existing habit logs to v3 and calculates starting XP', () async {
  // 1. Create v2 schema in memory
  // 2. Insert 5 habits and 25 completed habit_logs
  // 3. Trigger _onUpgrade to v3
  // 4. Verify xp_ledger table exists and has 25 rows
  // 5. Verify user_profile has total_xp = 500 (25 * 20) and appropriate level
  // 6. Verify original habits and habit_logs are completely intact
});
```

---

## 6. Accessibility & Reduced-Motion Testing

```dart
testWidgets('Celebration effects respect MediaQuery.disableAnimations', (tester) async {
  // Pump widget with disableAnimations: true
  // Trigger habit completion
  // Verify confetti/particle controller is NOT started
  // Verify static reward banner is displayed instead
});
```
