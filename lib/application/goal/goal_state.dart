import 'package:equatable/equatable.dart';

import '../../domain/entities/goals/goals_log.dart';
import '../../domain/entities/goals/goals_stats.dart';
import '../../infrastucture/models/goals/goal.dart';

abstract class GoalState extends Equatable {
  const GoalState();

  @override
  List<Object?> get props => [];
}

class GoalInitial extends GoalState {
  const GoalInitial();
}

class GoalLoading extends GoalState {
  const GoalLoading();
}

class GoalActionLoading extends GoalState {
  final List<Goal> goals;

  const GoalActionLoading({required this.goals});

  @override
  List<Object?> get props => [goals];
}

class GoalsLoaded extends GoalState {
  final List<Goal> goals;

  const GoalsLoaded({required this.goals});

  @override
  List<Object?> get props => [goals];
}

class GoalCreated extends GoalState {
  final Goal goal;
  final List<Goal> allGoals;

  const GoalCreated({required this.goal, required this.allGoals});

  @override
  List<Object?> get props => [goal, allGoals];
}

class GoalUpdated extends GoalState {
  final Goal goal;
  final List<Goal> allGoals;

  const GoalUpdated({required this.goal, required this.allGoals});

  @override
  List<Object?> get props => [goal, allGoals];
}

class GoalDeleted extends GoalState {
  final List<Goal> goals;

  const GoalDeleted({required this.goals});

  @override
  List<Object?> get props => [goals];
}

class GoalLogged extends GoalState {
  final GoalLog goalLog;
  final List<Goal> allGoals;

  const GoalLogged({required this.goalLog, required this.allGoals});

  @override
  List<Object?> get props => [goalLog, allGoals];
}

class GoalStatsLoaded extends GoalState {
  final GoalStats stats;
  final String goalId;

  const GoalStatsLoaded({required this.stats, required this.goalId});

  @override
  List<Object?> get props => [stats, goalId];
}

class GoalLogUpdated extends GoalState {
  final GoalLog goalLog;
  final List<Goal> allGoals;

  const GoalLogUpdated({required this.goalLog, required this.allGoals});

  @override
  List<Object?> get props => [goalLog, allGoals];
}

class GoalError extends GoalState {
  final String message;

  const GoalError({required this.message});

  @override
  List<Object?> get props => [message];
}

class GoalValidationError extends GoalState {
  final Map<String, String> fieldErrors;

  const GoalValidationError({required this.fieldErrors});

  @override
  List<Object?> get props => [fieldErrors];
}

// ✅ NEW ANALYTICS STATES
class AnalyticsLoading extends GoalState {
  const AnalyticsLoading();
}

class OverviewAnalyticsLoaded extends GoalState {
  final Map<String, dynamic> data;
  final String period;

  const OverviewAnalyticsLoaded({required this.data, required this.period});

  @override
  List<Object?> get props => [data, period];
}

class GoalAnalyticsLoaded extends GoalState {
  final String goalId;
  final Map<String, dynamic> data;
  final String period;

  const GoalAnalyticsLoaded({
    required this.goalId,
    required this.data,
    required this.period,
  });

  @override
  List<Object?> get props => [goalId, data, period];
}

class GoalLogsForPeriodLoaded extends GoalState {
  final String goalId;
  final Map<String, dynamic> data;
  final String period;

  const GoalLogsForPeriodLoaded({
    required this.goalId,
    required this.data,
    required this.period,
  });

  @override
  List<Object?> get props => [goalId, data, period];
}

class AnalyticsError extends GoalState {
  final String message;

  const AnalyticsError({required this.message});

  @override
  List<Object?> get props => [message];
}
