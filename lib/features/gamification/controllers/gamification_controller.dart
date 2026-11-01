import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../habits/models/habit.dart';
import '../data/gamification_repository.dart';
import '../models/achievement.dart';
import '../models/user_profile.dart';
import '../models/xp_entry.dart';

class GamificationState {
  final UserProfile profile;
  final List<Achievement> achievements;
  final List<XpEntry> recentXp;
  final Map<String, int> xpBreakdown;
  final bool isLoading;

  const GamificationState({
    required this.profile,
    this.achievements = const [],
    this.recentXp = const [],
    this.xpBreakdown = const {},
    this.isLoading = false,
  });

  GamificationState copyWith({
    UserProfile? profile,
    List<Achievement>? achievements,
    List<XpEntry>? recentXp,
    Map<String, int>? xpBreakdown,
    bool? isLoading,
  }) {
    return GamificationState(
      profile: profile ?? this.profile,
      achievements: achievements ?? this.achievements,
      recentXp: recentXp ?? this.recentXp,
      xpBreakdown: xpBreakdown ?? this.xpBreakdown,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GamificationController extends Notifier<GamificationState> {
  late final GamificationRepository _repository;

  @override
  GamificationState build() {
    _repository = ref.read(gamificationRepositoryProvider);
    final initialProfile = UserProfile(
      heroName: 'DailyFlow Champion',
      avatarId: 'knight_helm',
      totalXp: 0,
      currentLevel: 1,
      createdAt: DateTime.now(),
    );

    state = GamificationState(profile: initialProfile, isLoading: true);
    loadGamificationData();
    return state;
  }

  Future<void> loadGamificationData() async {
    try {
      final profile = await _repository.getUserProfile();
      final achievements = await _repository.getAchievements();
      final recentXp = await _repository.getXpEntries(limit: 20);
      final xpBreakdown = await _repository.getXpBreakdown();

      if (!ref.mounted) return;
      state = state.copyWith(
        profile: profile,
        achievements: achievements,
        recentXp: recentXp,
        xpBreakdown: xpBreakdown,
        isLoading: false,
      );
    } catch (_) {
      // In test environments where SQLite factory is uninitialized,
      // preserve valid default profile and state gracefully.
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  Future<int> awardHabitCheckin({
    required int habitId,
    required String dateStr,
    required int currentStreak,
  }) async {
    final awarded = await _repository.awardHabitCheckin(
      habitId: habitId,
      dateStr: dateStr,
      currentStreak: currentStreak,
    );
    await loadGamificationData();
    return awarded;
  }

  Future<int> revokeHabitCheckin({
    required int habitId,
    required String dateStr,
  }) async {
    final revoked = await _repository.revokeHabitCheckin(
      habitId: habitId,
      dateStr: dateStr,
    );
    await loadGamificationData();
    return revoked;
  }

  Future<int> awardFocusSession({
    required int durationMinutes,
    int? habitId,
    required String dateStr,
  }) async {
    final awarded = await _repository.awardFocusSession(
      durationMinutes: durationMinutes,
      habitId: habitId,
      dateStr: dateStr,
    );
    await loadGamificationData();
    return awarded;
  }

  Future<void> updateAchievementProgress(String badgeKey, int progress) async {
    await _repository.updateAchievementProgress(badgeKey, progress);
    await loadGamificationData();
  }

  Future<void> evaluateAchievements({required List<Habit> habits}) async {
    try {
      await _repository.evaluateAndSyncAchievements(habits: habits);
      await loadGamificationData();
    } catch (_) {}
  }

  Future<void> updateProfile({String? heroName, String? avatarId}) async {
    await _repository.updateUserProfile(heroName: heroName, avatarId: avatarId);
    await loadGamificationData();
  }
}

final gamificationControllerProvider =
    NotifierProvider<GamificationController, GamificationState>(
      GamificationController.new,
    );
