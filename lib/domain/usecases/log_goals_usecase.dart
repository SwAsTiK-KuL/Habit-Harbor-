import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/failures/failures.dart';
import '../entities/goals/goals_log.dart';
import '../repository/goals/goals_repository.dart';

class LogGoalUseCase {
  final GoalRepository repository;

  LogGoalUseCase(this.repository);

  Future<Either<Failure, GoalLog>> call(LogGoalParams params) async {
    return await repository.logGoal(
      goalId: params.goalId,
      status: params.status,
      date: params.date,
      notes: params.notes,
    );
  }
}

class LogGoalParams extends Equatable {
  final String goalId;
  final String status;
  final String? date;
  final String? notes;

  const LogGoalParams({
    required this.goalId,
    required this.status,
    this.date,
    this.notes,
  });

  @override
  List<Object?> get props => [goalId, status, date, notes];
}
