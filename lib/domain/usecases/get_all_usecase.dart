import 'package:dartz/dartz.dart';
import 'package:habit_harbor/infrastucture/models/goals/goal.dart';
import '../../core/failures/failures.dart';
import '../repository/goals/goals_repository.dart';

class GetAllGoalsUseCase {
  final GoalRepository repository;

  GetAllGoalsUseCase(this.repository);

  Future<Either<Failure, List<Goal>>> call() async {
    return await repository.getAllGoals();
  }
}
