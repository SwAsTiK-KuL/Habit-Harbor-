import 'package:dartz/dartz.dart';

import '../../../core/exceptions/exception.dart';
import '../../../core/failures/failures.dart';
import '../../../domain/entities/goals/goals_log.dart';
import '../../../domain/entities/goals/goals_stats.dart';
import '../../../domain/repository/goals/goals_repository.dart';
import '../../data_source/goals/goal_remote_data_source.dart';
import '../../models/goals/goal.dart';

class GoalRepositoryImpl implements GoalRepository {
  final GoalRemoteDataSource remoteDataSource;

  GoalRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Goal>> createGoal({
    required String title,
    required String description,
    required String category,
    required String color,
    required String icon,
    required String targetFrequency,
    required int targetCount,
  }) async {
    try {
      final goal = await remoteDataSource.createGoal(
        title: title,
        description: description,
        category: category,
        color: color,
        icon: icon,
        targetFrequency: targetFrequency,
        targetCount: targetCount,
      );
      return Right(goal);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<Goal>>> getAllGoals() async {
    try {
      final goals = await remoteDataSource.getAllGoals();
      return Right(goals);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Goal>> getGoal(String goalId) async {
    try {
      final goal = await remoteDataSource.getGoal(goalId);
      return Right(goal);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Goal>> updateGoal({
    required String goalId,
    String? title,
    String? description,
    String? category,
    String? color,
    String? icon,
    String? targetFrequency,
    int? targetCount,
  }) async {
    try {
      final goal = await remoteDataSource.updateGoal(
        goalId: goalId,
        title: title,
        description: description,
        category: category,
        color: color,
        icon: icon,
        targetFrequency: targetFrequency,
        targetCount: targetCount,
      );
      return Right(goal);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGoal(String goalId) async {
    try {
      await remoteDataSource.deleteGoal(goalId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, GoalStats>> getGoalStats(
    String goalId, {
    int days = 30,
  }) async {
    try {
      final stats = await remoteDataSource.getGoalStats(goalId, days: days);
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, GoalLog>> logGoal({
    required String goalId,
    required String status,
    String? date,
    String? notes,
  }) async {
    try {
      final log = await remoteDataSource.logGoal(
        goalId: goalId,
        status: status,
        date: date,
        notes: notes,
      );
      return Right(log);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<GoalLog>>> getGoalLogs(
    String goalId, {
    int limit = 30,
  }) async {
    try {
      final logs = await remoteDataSource.getGoalLogs(goalId, limit: limit);
      return Right(logs);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<GoalLog>>> getTodayLogs() async {
    try {
      final logs = await remoteDataSource.getTodayLogs();
      return Right(logs);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, GoalLog>> updateGoalLog({
    required String logId,
    String? status,
    String? notes,
  }) async {
    try {
      final log = await remoteDataSource.updateGoalLog(
        logId: logId,
        status: status,
        notes: notes,
      );
      return Right(log);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGoalLog(String logId) async {
    try {
      await remoteDataSource.deleteGoalLog(logId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  // ✅ NEW ANALYTICS IMPLEMENTATIONS
  @override
  Future<Either<Failure, Map<String, dynamic>>> getOverviewAnalytics({
    String period = 'month',
  }) async {
    try {
      final analytics = await remoteDataSource.getOverviewAnalytics(
        period: period,
      );
      return Right(analytics);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getGoalAnalytics({
    required String goalId,
    String period = 'month',
  }) async {
    try {
      final analytics = await remoteDataSource.getGoalAnalytics(
        goalId: goalId,
        period: period,
      );
      return Right(analytics);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getGoalLogsForPeriod({
    required String goalId,
    String period = 'month',
    int limit = 365,
  }) async {
    try {
      final logs = await remoteDataSource.getGoalLogsForPeriod(
        goalId: goalId,
        period: period,
        limit: limit,
      );
      return Right(logs);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }
}
