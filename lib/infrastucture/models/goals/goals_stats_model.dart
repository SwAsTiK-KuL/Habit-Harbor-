import '../../../domain/entities/goals/goals_stats.dart';

class GoalStatsModel {
  final int totalDays;
  final int completed;
  final int missed;
  final int holiday;
  final int sick;
  final int skipped;
  final int completionRate;
  final int currentStreak;
  final int longestStreak;

  const GoalStatsModel({
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

  factory GoalStatsModel.fromJson(Map<String, dynamic> json) {
    return GoalStatsModel(
      totalDays: json['total_days'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      missed: json['missed'] as int? ?? 0,
      holiday: json['holiday'] as int? ?? 0,
      sick: json['sick'] as int? ?? 0,
      skipped: json['skipped'] as int? ?? 0,
      completionRate: json['completion_rate'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_days': totalDays,
      'completed': completed,
      'missed': missed,
      'holiday': holiday,
      'sick': sick,
      'skipped': skipped,
      'completion_rate': completionRate,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
    };
  }

  // ✅ CRITICAL: This method converts model to entity
  GoalStats toEntity() {
    return GoalStats(
      totalDays: totalDays,
      completed: completed,
      missed: missed,
      holiday: holiday,
      sick: sick,
      skipped: skipped,
      completionRate: completionRate,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }

  factory GoalStatsModel.fromEntity(GoalStats stats) {
    return GoalStatsModel(
      totalDays: stats.totalDays,
      completed: stats.completed,
      missed: stats.missed,
      holiday: stats.holiday,
      sick: stats.sick,
      skipped: stats.skipped,
      completionRate: stats.completionRate,
      currentStreak: stats.currentStreak,
      longestStreak: stats.longestStreak,
    );
  }
}
