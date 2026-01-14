import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/failures/failures.dart';
import '../entities/goals/goals_log.dart';
import '../repository/goals/goals_repository.dart';

// ✅ Overview Analytics Use Case
class GetOverviewAnalyticsUseCase {
  final GoalRepository repository;

  GetOverviewAnalyticsUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(
    OverviewAnalyticsParams params,
  ) async {
    return await repository.getOverviewAnalytics(period: params.period);
  }
}

class OverviewAnalyticsParams extends Equatable {
  final String period;

  const OverviewAnalyticsParams({this.period = 'month'});

  @override
  List<Object?> get props => [period];
}

// ✅ Goal Analytics Use Case
class GetGoalAnalyticsUseCase {
  final GoalRepository repository;

  GetGoalAnalyticsUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(
    GoalAnalyticsParams params,
  ) async {
    return await repository.getGoalAnalytics(
      goalId: params.goalId,
      period: params.period,
    );
  }
}

class GoalAnalyticsParams extends Equatable {
  final String goalId;
  final String period;

  const GoalAnalyticsParams({required this.goalId, this.period = 'month'});

  @override
  List<Object?> get props => [goalId, period];
}

// ✅ Goal Logs for Period Use Case
class GetGoalLogsForPeriodUseCase {
  final GoalRepository repository;

  GetGoalLogsForPeriodUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(
    GoalLogsForPeriodParams params,
  ) async {
    return await repository.getGoalLogsForPeriod(
      goalId: params.goalId,
      period: params.period,
      limit: params.limit,
    );
  }
}

class GoalLogsForPeriodParams extends Equatable {
  final String goalId;
  final String period;
  final int limit;

  const GoalLogsForPeriodParams({
    required this.goalId,
    this.period = 'month',
    this.limit = 365,
  });

  @override
  List<Object?> get props => [goalId, period, limit];
}

// ✅ Update Goal Log Use Case
class UpdateGoalLogUseCase {
  final GoalRepository repository;

  UpdateGoalLogUseCase(this.repository);

  Future<Either<Failure, GoalLog>> call(UpdateGoalLogParams params) async {
    return await repository.updateGoalLog(
      logId: params.logId,
      status: params.status,
      notes: params.notes,
    );
  }
}

class UpdateGoalLogParams extends Equatable {
  final String logId;
  final String? status;
  final String? notes;

  const UpdateGoalLogParams({required this.logId, this.status, this.notes});

  @override
  List<Object?> get props => [logId, status, notes];
}
