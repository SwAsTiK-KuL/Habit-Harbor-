import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/failures/failures.dart';
import '../entities/goals/goals_stats.dart';
import '../repository/goals/goals_repository.dart';

class GetGoalStatsUseCase {
  final GoalRepository repository;

  GetGoalStatsUseCase(this.repository);

  Future<Either<Failure, GoalStats>> call(GoalStatsParams params) async {
    return await repository.getGoalStats(params.goalId, days: params.days);
  }
}

class GoalStatsParams extends Equatable {
  final String goalId;
  final int days;

  const GoalStatsParams({required this.goalId, this.days = 30});

  @override
  List<Object?> get props => [goalId, days];
}
