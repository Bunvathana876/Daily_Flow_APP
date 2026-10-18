import '../../../core/utils/date_utils.dart';

class Habit {
  final int? id;
  final String title;
  final DateTime createdAt;
  final Set<String> completedDates;
  final String category;
  final int colorValue;

  Habit({
    this.id,
    required this.title,
    required this.createdAt,
    required this.completedDates,
    this.category = 'General',
    this.colorValue = 0xFF4F46E5,
  });

  static String formatDate(DateTime date) => AppDateUtils.formatDate(date);

  bool get isCompletedToday =>
      completedDates.contains(AppDateUtils.todayString);

  int get currentStreak => AppDateUtils.calculateStreak(completedDates);

  int get bestStreak => AppDateUtils.calculateBestStreak(completedDates);

  int get totalCompletions => completedDates.length;

  Habit copyWith({
    int? id,
    String? title,
    DateTime? createdAt,
    Set<String>? completedDates,
    String? category,
    int? colorValue,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
