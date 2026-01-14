import 'package:dartz/dartz.dart';
import 'package:habit_harbor/infrastucture/models/goals/goal.dart';

import '../../../core/failures/failures.dart';
import '../../entities/goals/goals_log.dart';
import '../../entities/goals/goals_stats.dart';

abstract class GoalRepository {
  // Goal management
  Future<Either<Failure, Goal>> createGoal({
    required String title,
    required String description,
    required String category,
    required String color,
    required String icon,
    required String targetFrequency,
    required int targetCount,
  });

  Future<Either<Failure, List<Goal>>> getAllGoals();
  Future<Either<Failure, Goal>> getGoal(String goalId);

  Future<Either<Failure, Goal>> updateGoal({
    required String goalId,
    String? title,
    String? description,
    String? category,
    String? color,
    String? icon,
    String? targetFrequency,
    int? targetCount,
  });

  Future<Either<Failure, void>> deleteGoal(String goalId);
  Future<Either<Failure, GoalStats>> getGoalStats(
    String goalId, {
    int days = 30,
  });

  // Goal logging
  Future<Either<Failure, GoalLog>> logGoal({
    required String goalId,
    required String status,
    String? date,
    String? notes,
  });

  Future<Either<Failure, List<GoalLog>>> getGoalLogs(
    String goalId, {
    int limit = 30,
  });
  Future<Either<Failure, List<GoalLog>>> getTodayLogs();

  Future<Either<Failure, GoalLog>> updateGoalLog({
    required String logId,
    String? status,
    String? notes,
  });

  Future<Either<Failure, void>> deleteGoalLog(String logId);

  // Analytics endpoints
  Future<Either<Failure, Map<String, dynamic>>> getOverviewAnalytics({
    String period = 'month',
  });

  Future<Either<Failure, Map<String, dynamic>>> getGoalAnalytics({
    required String goalId,
    String period = 'month',
  });

  Future<Either<Failure, Map<String, dynamic>>> getGoalLogsForPeriod({
    required String goalId,
    String period = 'month',
    int limit = 365,
  });
}
