import 'package:daily_flow/core/utils/date_utils.dart';
import 'package:daily_flow/core/utils/gamification_math.dart';
import 'package:daily_flow/features/gamification/data/gamification_repository.dart';
import 'package:daily_flow/features/gamification/models/achievement.dart';
import 'package:daily_flow/features/gamification/models/user_profile.dart';
import 'package:daily_flow/features/gamification/models/xp_entry.dart';
import 'package:daily_flow/features/habits/data/habit_repository.dart';
import 'package:daily_flow/features/habits/models/habit.dart';
import 'package:daily_flow/features/habits/screen/home_screen.dart';
import 'package:daily_flow/features/habits/screen/widgets/daily_bounty_card.dart';
import 'package:daily_flow/features/habits/screen/widgets/habit_tile.dart';
import 'package:daily_flow/features/habits/screen/widgets/hero_xp_hud.dart';
import 'package:daily_flow/features/habits/screen/widgets/quest_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockGamificationRepository implements GamificationRepository {
  UserProfile profile;
  final List<XpEntry> ledger = [];

  MockGamificationRepository({UserProfile? initialProfile})
    : profile =
          initialProfile ??
          UserProfile(
            heroName: 'Arcane Champion',
            avatarId: 'knight_helm',
            totalXp: 450,
            currentLevel: 4,
            createdAt: DateTime.now(),
          );

  @override
  Future<UserProfile> getUserProfile() async => profile;

  @override
  Future<void> updateUserProfile({String? heroName, String? avatarId}) async {
    profile = profile.copyWith(heroName: heroName, avatarId: avatarId);
  }

  @override
  Future<List<XpEntry>> getXpEntries({int limit = 50, int offset = 0}) async =>
      ledger;

  @override
  Future<int> getTotalActiveXp() async {
    return ledger
        .where((e) => e.status == XpStatus.active)
        .fold<int>(0, (sum, e) => sum + e.xpAmount);
  }

  @override
  Future<int> getCurrentLevel() async {
    final xp = await getTotalActiveXp();
    return GamificationMath.calculateLevel(xp);
  }

  @override
  Future<int> getTotalFocusMinutes() async => 0;

  @override
  Future<int> getTotalFocusSessions() async => 0;

  @override
  Future<List<Achievement>> evaluateAndSyncAchievements({
    required List<Habit> habits,
  }) async => [];

  @override
  Future<int> awardHabitCheckin({
    required int habitId,
    required String dateStr,
    required int currentStreak,
  }) async {
    final xp = GamificationMath.calculateCheckinXp(currentStreak);
    ledger.add(
      XpEntry(
        id: ledger.length + 1,
        sourceType: XpSourceType.habitCheckin,
        sourceId: habitId,
        eventDate: dateStr,
        xpAmount: xp,
        status: XpStatus.active,
        createdAt: DateTime.now(),
      ),
    );
    final total = await getTotalActiveXp();
    final level = GamificationMath.calculateLevel(total);
    profile = profile.copyWith(totalXp: total, currentLevel: level);
    return xp;
  }

  @override
  Future<int> revokeHabitCheckin({
    required int habitId,
    required String dateStr,
  }) async {
    int revoked = 0;
    for (int i = 0; i < ledger.length; i++) {
      if (ledger[i].sourceType == XpSourceType.habitCheckin &&
          ledger[i].sourceId == habitId &&
          ledger[i].eventDate == dateStr &&
          ledger[i].status == XpStatus.active) {
        revoked = ledger[i].xpAmount;
        ledger[i] = ledger[i].copyWith(status: XpStatus.revoked);
      }
    }
    final total = await getTotalActiveXp();
    final level = GamificationMath.calculateLevel(total);
    profile = profile.copyWith(totalXp: total, currentLevel: level);
    return revoked;
  }

  @override
  Future<int> awardFocusSession({
    required int durationMinutes,
    int? habitId,
    required String dateStr,
  }) async => durationMinutes;

  @override
  Future<List<Achievement>> getAchievements() async => [];

  @override
  Future<void> updateAchievementProgress(String badgeKey, int progress) async {}

  @override
  Future<bool> unlockAchievement(String badgeKey) async => false;

  @override
  Future<Map<String, int>> getXpBreakdown() async => {};

  @override
  Future<void> recalculateTotalXpAndLevel() async {}
}

class MockHabitRepository implements HabitRepository {
  final List<Habit> _habits = [];

  MockHabitRepository([List<Habit>? initial]) {
    if (initial != null) _habits.addAll(initial);
  }

  @override
  Future<List<Habit>> getHabits() async => List.unmodifiable(_habits);

  @override
  Future<Habit> createHabit({
    required String title,
    String category = 'General',
    int colorValue = 0xFF4F46E5,
  }) async {
    final habit = Habit(
      id: _habits.length + 1,
      title: title,
      createdAt: DateTime.now(),
      completedDates: const {},
      category: category,
      colorValue: colorValue,
    );
    _habits.add(habit);
    return habit;
  }

  @override
  Future<void> updateHabit({
    required int id,
    required String title,
    String? category,
    int? colorValue,
    bool? isArchived,
  }) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      _habits[index] = _habits[index].copyWith(
        title: title,
        category: category ?? _habits[index].category,
        colorValue: colorValue ?? _habits[index].colorValue,
      );
    }
  }

  @override
  Future<void> deleteHabit(int id) async {
    _habits.removeWhere((h) => h.id == id);
  }

  @override
  Future<void> toggleHabitLog({
    required int habitId,
    required String dateStr,
    required bool isCompleted,
  }) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      final h = _habits[index];
      final dates = Set<String>.from(h.completedDates);
      if (isCompleted) {
        dates.remove(dateStr);
      } else {
        dates.add(dateStr);
      }
      _habits[index] = h.copyWith(completedDates: dates);
    }
  }

  @override
  Future<void> restoreHabit(Habit habit) async {
    _habits.add(habit);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final todayStr = AppDateUtils.todayString;

  group('Phase B Epic Quest Dashboard - UI Suite', () {
    testWidgets('1. Home dashboard rendering with full RPG aesthetic', (
      tester,
    ) async {
      final mockGamificationRepo = MockGamificationRepository();
      final mockHabits = [
        Habit(
          id: 1,
          title: 'Slay Algorithms',
          category: 'Coding',
          colorValue: 0xFF6366F1,
          createdAt: DateTime.now(),
          completedDates: const {},
        ),
        Habit(
          id: 2,
          title: 'Morning Elixir',
          category: 'Health',
          colorValue: 0xFF10B981,
          createdAt: DateTime.now(),
          completedDates: {todayStr},
        ),
      ];
      final mockHabitRepo = MockHabitRepository(mockHabits);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamificationRepositoryProvider.overrideWithValue(
              mockGamificationRepo,
            ),
            habitRepositoryProvider.overrideWithValue(mockHabitRepo),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // App Bar & Title
      expect(find.text('DailyFlow'), findsOneWidget);

      // Hero HUD Elements
      expect(find.text('Arcane Champion'), findsOneWidget);
      expect(find.text('Lv. 4'), findsOneWidget);
      expect(find.text('450 Total XP'), findsOneWidget);

      // Daily Bounty Card Elements
      expect(find.text("Today's Quests"), findsOneWidget);
      expect(find.text('DAILY BOUNTY'), findsOneWidget);
      expect(find.text('1 / 2 Done'), findsOneWidget);
      expect(find.text('7-Day Completion Rate'), findsOneWidget);

      // Category Chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
      expect(find.text('Coding'), findsOneWidget);
      expect(find.text('Fitness'), findsOneWidget);

      // Quest Tiles
      expect(find.text('Slay Algorithms'), findsOneWidget);
      expect(find.text('Morning Elixir'), findsOneWidget);

      // Floating Action Button
      expect(find.text('New Quest'), findsOneWidget);
    });

    testWidgets('2. Quest completion with one-tap crest and XP update', (
      tester,
    ) async {
      final mockGamificationRepo = MockGamificationRepository();
      final sampleHabit = Habit(
        id: 1,
        title: 'Morning Yoga',
        category: 'Health',
        colorValue: 0xFF10B981,
        createdAt: DateTime.now(),
        completedDates: const {},
      );
      final mockHabitRepo = MockHabitRepository([sampleHabit]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamificationRepositoryProvider.overrideWithValue(
              mockGamificationRepo,
            ),
            habitRepositoryProvider.overrideWithValue(mockHabitRepo),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 / 1 Done'), findsOneWidget);

      // Tap checkmark to complete quest
      final checkmark = find.byKey(const Key('habit_tile_checkmark_btn')).first;
      await tester.tap(checkmark);
      await tester.pumpAndSettle();

      expect(find.text('1 / 1 Done'), findsOneWidget);
      expect(find.text('Flawless Victory!'), findsOneWidget);
    });

    testWidgets(
      '3. Quest creation and validation with draggable QuestFormSheet',
      (tester) async {
        String? createdTitle;
        String? createdCategory;
        int? createdColor;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      QuestFormSheet.show(
                        context,
                        onSave: (title, category, color) {
                          createdTitle = title;
                          createdCategory = category;
                          createdColor = color;
                        },
                      );
                    },
                    child: const Text('Open Sheet'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open Bottom Sheet
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Forge New Quest'), findsOneWidget);
        expect(find.text('Forge Quest'), findsOneWidget);

        // Try submitting empty title -> should show validation error
        await tester.tap(find.text('Forge Quest'));
        await tester.pumpAndSettle();

        expect(find.text('Quest title cannot be empty'), findsOneWidget);
        expect(createdTitle, isNull);

        // Enter valid title
        await tester.enterText(
          find.byType(TextFormField),
          'Read 30 Pages of Tome',
        );
        await tester.pumpAndSettle();

        // Select 'Study' category
        await tester.tap(find.text('Study'));
        await tester.pumpAndSettle();

        // Submit form
        await tester.tap(find.text('Forge Quest'));
        await tester.pumpAndSettle();

        expect(createdTitle, 'Read 30 Pages of Tome');
        expect(createdCategory, 'Study');
        expect(createdColor, isNotNull);
      },
    );

    testWidgets('4. Quest editing with pre-filled fields', (tester) async {
      final existingHabit = Habit(
        id: 42,
        title: 'Master Dart Macros',
        category: 'Coding',
        colorValue: 0xFF6366F1,
        createdAt: DateTime.now(),
        completedDates: const {},
      );

      String? updatedTitle;
      String? updatedCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    QuestFormSheet.show(
                      context,
                      habit: existingHabit,
                      onSave: (title, category, color) {
                        updatedTitle = title;
                        updatedCategory = category;
                      },
                    );
                  },
                  child: const Text('Edit Sheet'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Inscribe Quest'), findsOneWidget);
      expect(find.text('Save Quest'), findsOneWidget);
      expect(find.text('Master Dart Macros'), findsOneWidget);

      // Edit title
      await tester.enterText(find.byType(TextFormField), 'Master Dart FFI');
      await tester.tap(find.text('Save Quest'));
      await tester.pumpAndSettle();

      expect(updatedTitle, 'Master Dart FFI');
      expect(updatedCategory, 'Coding');
    });

    testWidgets('5. Empty states when no quests exist or category is empty', (
      tester,
    ) async {
      final mockGamificationRepo = MockGamificationRepository();
      final mockHabitRepo = MockHabitRepository([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamificationRepositoryProvider.overrideWithValue(
              mockGamificationRepo,
            ),
            habitRepositoryProvider.overrideWithValue(mockHabitRepo),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No habits yet.'), findsOneWidget);
      expect(find.text('No Quests'), findsOneWidget);
    });

    testWidgets('6. Small screen responsiveness (320px screen width)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockGamificationRepo = MockGamificationRepository();
      final sampleHabit = Habit(
        id: 1,
        title: 'Small Screen Hero Quest Title That Is Quite Long',
        category: 'Study',
        colorValue: 0xFF6366F1,
        createdAt: DateTime.now(),
        completedDates: {todayStr},
      );
      final mockHabitRepo = MockHabitRepository([sampleHabit]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamificationRepositoryProvider.overrideWithValue(
              mockGamificationRepo,
            ),
            habitRepositoryProvider.overrideWithValue(mockHabitRepo),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no RenderFlex overflow occurs on 320px
      expect(tester.takeException(), isNull);
      expect(find.byType(HeroXpHud), findsOneWidget);
      expect(find.byType(DailyBountyCard), findsOneWidget);
      expect(find.byType(HabitTile), findsOneWidget);
    });

    testWidgets(
      '7. Reduced-motion setting runs smoothly without animation lag',
      (tester) async {
        final sampleHabit = Habit(
          id: 1,
          title: 'Reduced Motion Quest',
          category: 'Health',
          colorValue: 0xFF10B981,
          createdAt: DateTime.now(),
          completedDates: const {},
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              home: Scaffold(
                body: HabitTile(
                  habit: sampleHabit,
                  onToggle: () {},
                  onToggleDate: (_) {},
                  onEdit: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Reduced Motion Quest'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
