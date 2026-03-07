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

  factory GoalStats.fromJson(Map<String, dynamic> json) {
    return GoalStats(
      totalDays: json['total_days'] ?? 0,
      completed: json['completed'] ?? 0,
      missed: json['missed'] ?? 0,
      holiday: json['holiday'] ?? 0,
      sick: json['sick'] ?? 0,
      skipped: json['skipped'] ?? 0,
      completionRate: json['completion_rate'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
    );
  }

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

  int get totalLogged => completed + missed + holiday + sick + skipped;
  int get excusedTotal => holiday + sick;
  int get uncompletedTotal => missed + skipped;

  double get completionPercentage => completionRate.toDouble();

  bool get isOnStreak => currentStreak > 0;

  String get performanceLevel {
    if (completionRate >= 90) return 'Excellent';
    if (completionRate >= 75) return 'Good';
    if (completionRate >= 50) return 'Average';
    return 'Needs Improvement';
  }

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
}
