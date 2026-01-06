import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:habit_harbor/infrastucture/models/goals/goal.dart';
import '../../core/failures/failures.dart';
import '../repository/goals/goals_repository.dart';

class CreateGoalUseCase {
  final GoalRepository repository;

  CreateGoalUseCase(this.repository);

  Future<Either<Failure, Goal>> call(CreateGoalParams params) async {
    return await repository.createGoal(
      title: params.title,
      description: params.description,
      category: params.category,
      color: params.color,
      icon: params.icon,
      targetFrequency: params.targetFrequency,
      targetCount: params.targetCount,
    );
  }
}

class CreateGoalParams extends Equatable {
  final String title;
  final String description;
  final String category;
  final String color;
  final String icon;
  final String targetFrequency;
  final int targetCount;

  const CreateGoalParams({
    required this.title,
    required this.description,
    required this.category,
    required this.color,
    required this.icon,
    required this.targetFrequency,
    required this.targetCount,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    category,
    color,
    icon,
    targetFrequency,
    targetCount,
  ];
}
