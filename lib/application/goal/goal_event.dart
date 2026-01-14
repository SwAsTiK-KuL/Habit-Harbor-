import 'package:equatable/equatable.dart';

abstract class GoalEvent extends Equatable {
  const GoalEvent();

  @override
  List<Object?> get props => [];
}

class LoadGoals extends GoalEvent {
  const LoadGoals();
}

class CreateGoal extends GoalEvent {
  final String title;
  final String description;
  final String category;
  final String color;
  final String icon;
  final String targetFrequency;
  final int targetCount;

  const CreateGoal({
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

class UpdateGoal extends GoalEvent {
  final String goalId;
  final String? title;
  final String? description;
  final String? category;
  final String? color;
  final String? icon;
  final String? targetFrequency;
  final int? targetCount;

  const UpdateGoal({
    required this.goalId,
    this.title,
    this.description,
    this.category,
    this.color,
    this.icon,
    this.targetFrequency,
    this.targetCount,
  });

  @override
  List<Object?> get props => [
    goalId,
    title,
    description,
    category,
    color,
    icon,
    targetFrequency,
    targetCount,
  ];
}

class DeleteGoal extends GoalEvent {
  final String goalId;

  const DeleteGoal({required this.goalId});

  @override
  List<Object?> get props => [goalId];
}

class LogGoalStatus extends GoalEvent {
  final String goalId;
  final String status;
  final String? date;
  final String? notes;

  const LogGoalStatus({
    required this.goalId,
    required this.status,
    this.date,
    this.notes,
  });

  @override
  List<Object?> get props => [goalId, status, date, notes];
}

class LoadGoalStats extends GoalEvent {
  final String goalId;
  final int days;

  const LoadGoalStats({required this.goalId, this.days = 30});

  @override
  List<Object?> get props => [goalId, days];
}

class UpdateGoalLogStatus extends GoalEvent {
  final String logId;
  final String? status;
  final String? notes;

  const UpdateGoalLogStatus({required this.logId, this.status, this.notes});

  @override
  List<Object?> get props => [logId, status, notes];
}

class GoalErrorCleared extends GoalEvent {
  const GoalErrorCleared();
}

// ✅ NEW ANALYTICS EVENTS
class LoadOverviewAnalytics extends GoalEvent {
  final String period;

  const LoadOverviewAnalytics({this.period = 'month'});

  @override
  List<Object?> get props => [period];
}

class LoadGoalAnalytics extends GoalEvent {
  final String goalId;
  final String period;

  const LoadGoalAnalytics({required this.goalId, this.period = 'month'});

  @override
  List<Object?> get props => [goalId, period];
}

class LoadGoalLogsForPeriod extends GoalEvent {
  final String goalId;
  final String period;
  final int limit;

  const LoadGoalLogsForPeriod({
    required this.goalId,
    this.period = 'month',
    this.limit = 365,
  });

  @override
  List<Object?> get props => [goalId, period, limit];
}
