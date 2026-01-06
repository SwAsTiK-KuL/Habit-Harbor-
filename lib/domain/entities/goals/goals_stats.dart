import 'package:equatable/equatable.dart';

class GoalStats extends Equatable {
  final int totalDays;
  final int completed;
  final int missed;
  final int holiday;
  final int sick;
  final int skipped;
  final int completionRate;
  final int currentStreak;
  final int longestStreak;

  const GoalStats({
    required this.totalDays,
    required this.completed,
    required this.missed,
    required this.holiday,
    required this.sick,
    required this.skipped,
    required this.completionRate,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  List<Object?> get props => [
    totalDays,
    completed,
    missed,
    holiday,
    sick,
    skipped,
    completionRate,
    currentStreak,
    longestStreak,
  ];

  // Computed properties
  int get totalLogged => completed + missed + holiday + sick + skipped;
  int get missedTotal => missed + skipped;
  int get excusedTotal => holiday + sick;

  // Add copyWith method for consistency
  GoalStats copyWith({
    int? totalDays,
    int? completed,
    int? missed,
    int? holiday,
    int? sick,
    int? skipped,
    int? completionRate,
    int? currentStreak,
    int? longestStreak,
  }) {
    return GoalStats(
      totalDays: totalDays ?? this.totalDays,
      completed: completed ?? this.completed,
      missed: missed ?? this.missed,
      holiday: holiday ?? this.holiday,
      sick: sick ?? this.sick,
      skipped: skipped ?? this.skipped,
      completionRate: completionRate ?? this.completionRate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }

  // Helper methods for analytics
  double get completionPercentage =>
      totalDays > 0 ? (completed / totalDays) * 100 : 0;
  bool get isOnStreak => currentStreak > 0;
  bool get hasCompletedToday =>
      completed > 0; // This would need more context in real usage

  // Performance indicators
  String get performanceLevel {
    if (completionRate >= 90) return 'Excellent';
    if (completionRate >= 75) return 'Good';
    if (completionRate >= 50) return 'Average';
    return 'Needs Improvement';
  }
}
