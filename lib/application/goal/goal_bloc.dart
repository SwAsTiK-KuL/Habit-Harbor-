import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/failures/failures.dart';
import '../../domain/repository/goals/goals_repository.dart';
import '../../domain/usecases/analytics_usecase.dart';
import '../../domain/usecases/create_goal_usecase.dart';
import '../../domain/usecases/get_all_usecase.dart';
import '../../domain/usecases/get_goals_status_usecase.dart';
import '../../domain/usecases/log_goals_usecase.dart';
import '../../infrastucture/models/goals/goal.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final GetAllGoalsUseCase getAllGoalsUseCase;
  final CreateGoalUseCase createGoalUseCase;
  final LogGoalUseCase logGoalUseCase;
  final GetGoalStatsUseCase getGoalStatsUseCase;
  final GoalRepository goalRepository;

  // ✅ Analytics use cases
  final GetOverviewAnalyticsUseCase getOverviewAnalyticsUseCase;
  final GetGoalAnalyticsUseCase getGoalAnalyticsUseCase;
  final GetGoalLogsForPeriodUseCase getGoalLogsForPeriodUseCase;

  List<Goal> _currentGoals = [];

  GoalBloc({
    required this.getAllGoalsUseCase,
    required this.createGoalUseCase,
    required this.logGoalUseCase,
    required this.getGoalStatsUseCase,
    required this.goalRepository,
    required this.getOverviewAnalyticsUseCase,
    required this.getGoalAnalyticsUseCase,
    required this.getGoalLogsForPeriodUseCase,
  }) : super(const GoalInitial()) {
    on<LoadGoals>(_onLoadGoals);
    on<CreateGoal>(_onCreateGoal);
    on<UpdateGoal>(_onUpdateGoal);
    on<DeleteGoal>(_onDeleteGoal);
    on<LogGoalStatus>(_onLogGoalStatus);
    on<LoadGoalStats>(_onLoadGoalStats);
    on<UpdateGoalLogStatus>(_onUpdateGoalLogStatus);
    on<GoalErrorCleared>(_onGoalErrorCleared);

    // ✅ Analytics event handlers
    on<LoadOverviewAnalytics>(_onLoadOverviewAnalytics);
    on<LoadGoalAnalytics>(_onLoadGoalAnalytics);
    on<LoadGoalLogsForPeriod>(_onLoadGoalLogsForPeriod);
  }

  Future<void> _onLoadGoals(LoadGoals event, Emitter<GoalState> emit) async {
    emit(const GoalLoading());

    final result = await getAllGoalsUseCase();

    result.fold(
      (failure) => emit(GoalError(message: _getFailureMessage(failure))),
      (goals) {
        _currentGoals = goals;
        emit(GoalsLoaded(goals: goals));
      },
    );
  }

  Future<void> _onCreateGoal(CreateGoal event, Emitter<GoalState> emit) async {
    emit(GoalActionLoading(goals: _currentGoals));

    final result = await createGoalUseCase(
      CreateGoalParams(
        title: event.title,
        description: event.description,
        category: event.category,
        color: event.color,
        icon: event.icon,
        targetFrequency: event.targetFrequency,
        targetCount: event.targetCount,
      ),
    );

    result.fold(
      (failure) {
        if (failure is ValidationFailure) {
          emit(
            GoalValidationError(
              fieldErrors: _parseValidationErrors(failure.message),
            ),
          );
        } else {
          emit(GoalError(message: _getFailureMessage(failure)));
        }
      },
      (goal) {
        // ✅ Add the new goal to current list and emit immediately
        _currentGoals = [..._currentGoals, goal];
        emit(GoalCreated(goal: goal, allGoals: _currentGoals));
      },
    );
  }

  Future<void> _onUpdateGoal(UpdateGoal event, Emitter<GoalState> emit) async {
    emit(GoalActionLoading(goals: _currentGoals));

    final result = await goalRepository.updateGoal(
      goalId: event.goalId,
      title: event.title,
      description: event.description,
      category: event.category,
      color: event.color,
      icon: event.icon,
      targetFrequency: event.targetFrequency,
      targetCount: event.targetCount,
    );

    result.fold(
      (failure) {
        if (failure is ValidationFailure) {
          emit(
            GoalValidationError(
              fieldErrors: _parseValidationErrors(failure.message),
            ),
          );
        } else {
          emit(GoalError(message: _getFailureMessage(failure)));
        }
      },
      (goal) async {
        // Check if emit is still active before proceeding
        if (emit.isDone) return;

        // Reload goals to get updated list
        final goalsResult = await getAllGoalsUseCase();

        // Check again before emitting
        if (emit.isDone) return;

        goalsResult.fold(
          (failure) => emit(GoalError(message: _getFailureMessage(failure))),
          (goals) {
            _currentGoals = goals;
            emit(GoalUpdated(goal: goal, allGoals: goals));
          },
        );
      },
    );
  }

  Future<void> _onDeleteGoal(DeleteGoal event, Emitter<GoalState> emit) async {
    emit(GoalActionLoading(goals: _currentGoals));

    final result = await goalRepository.deleteGoal(event.goalId);

    result.fold(
      (failure) => emit(GoalError(message: _getFailureMessage(failure))),
      (_) async {
        // Check if emit is still active before proceeding
        if (emit.isDone) return;

        // Reload goals to get updated list
        final goalsResult = await getAllGoalsUseCase();

        // Check again before emitting
        if (emit.isDone) return;

        goalsResult.fold(
          (failure) => emit(GoalError(message: _getFailureMessage(failure))),
          (goals) {
            _currentGoals = goals;
            emit(GoalDeleted(goals: goals));
          },
        );
      },
    );
  }

  Future<void> _onLogGoalStatus(
    LogGoalStatus event,
    Emitter<GoalState> emit,
  ) async {
    emit(GoalActionLoading(goals: _currentGoals));

    final result = await logGoalUseCase(
      LogGoalParams(
        goalId: event.goalId,
        status: event.status,
        date: event.date,
        notes: event.notes,
      ),
    );

    result.fold(
      (failure) {
        if (failure is ValidationFailure) {
          emit(
            GoalValidationError(
              fieldErrors: _parseValidationErrors(failure.message),
            ),
          );
        } else {
          emit(GoalError(message: _getFailureMessage(failure)));
        }
      },
      (goalLog) async {
        // Emit success state immediately to stop loading spinner
        emit(GoalLogged(goalLog: goalLog, allGoals: _currentGoals));

        // Then reload in background to get updated data
        try {
          final goalsResult = await getAllGoalsUseCase();
          if (!emit.isDone) {
            goalsResult.fold(
              (failure) {
                print(
                  '⚠️ Failed to reload goals after logging: ${_getFailureMessage(failure)}',
                );
              },
              (goals) {
                _currentGoals = goals;
                emit(GoalsLoaded(goals: goals));
              },
            );
          }
        } catch (e) {
          print('⚠️ Error during background reload: $e');
        }
      },
    );
  }

  Future<void> _onLoadGoalStats(
    LoadGoalStats event,
    Emitter<GoalState> emit,
  ) async {
    final result = await getGoalStatsUseCase(
      GoalStatsParams(goalId: event.goalId, days: event.days),
    );

    result.fold(
      (failure) => emit(GoalError(message: _getFailureMessage(failure))),
      (stats) => emit(GoalStatsLoaded(stats: stats, goalId: event.goalId)),
    );
  }

  Future<void> _onUpdateGoalLogStatus(
    UpdateGoalLogStatus event,
    Emitter<GoalState> emit,
  ) async {
    emit(GoalActionLoading(goals: _currentGoals));

    final result = await goalRepository.updateGoalLog(
      logId: event.logId,
      status: event.status,
      notes: event.notes,
    );

    result.fold(
      (failure) {
        if (failure is ValidationFailure) {
          emit(
            GoalValidationError(
              fieldErrors: _parseValidationErrors(failure.message),
            ),
          );
        } else {
          emit(GoalError(message: _getFailureMessage(failure)));
        }
      },
      (goalLog) async {
        // Check if emit is still active before proceeding
        if (emit.isDone) return;

        // Reload goals to get updated today's status
        final goalsResult = await getAllGoalsUseCase();

        // Check again before emitting
        if (emit.isDone) return;

        goalsResult.fold(
          (failure) => emit(GoalError(message: _getFailureMessage(failure))),
          (goals) {
            _currentGoals = goals;
            emit(GoalLogUpdated(goalLog: goalLog, allGoals: goals));
          },
        );
      },
    );
  }

  void _onGoalErrorCleared(GoalErrorCleared event, Emitter<GoalState> emit) {
    if (_currentGoals.isNotEmpty) {
      emit(GoalsLoaded(goals: _currentGoals));
    } else {
      emit(const GoalInitial());
    }
  }

  // ✅ ANALYTICS EVENT HANDLERS
  Future<void> _onLoadOverviewAnalytics(
    LoadOverviewAnalytics event,
    Emitter<GoalState> emit,
  ) async {
    emit(const AnalyticsLoading());

    print(
      '📊 GoalBloc: Loading overview analytics for period: ${event.period}',
    );

    final result = await getOverviewAnalyticsUseCase(
      OverviewAnalyticsParams(period: event.period),
    );

    result.fold(
      (failure) {
        print(
          '❌ GoalBloc: Failed to load overview analytics: ${_getFailureMessage(failure)}',
        );
        emit(AnalyticsError(message: _getFailureMessage(failure)));
      },
      (data) {
        print('✅ GoalBloc: Overview analytics loaded successfully');
        emit(OverviewAnalyticsLoaded(data: data, period: event.period));
      },
    );
  }

  Future<void> _onLoadGoalAnalytics(
    LoadGoalAnalytics event,
    Emitter<GoalState> emit,
  ) async {
    // Don't emit loading state here to avoid interfering with overview loading
    print(
      '📊 GoalBloc: Loading goal analytics for ${event.goalId}, period: ${event.period}',
    );

    final result = await getGoalAnalyticsUseCase(
      GoalAnalyticsParams(goalId: event.goalId, period: event.period),
    );

    result.fold(
      (failure) {
        print(
          '❌ GoalBloc: Failed to load goal analytics: ${_getFailureMessage(failure)}',
        );
        emit(AnalyticsError(message: _getFailureMessage(failure)));
      },
      (data) {
        print(
          '✅ GoalBloc: Goal analytics loaded successfully for ${event.goalId}',
        );
        emit(
          GoalAnalyticsLoaded(
            goalId: event.goalId,
            data: data,
            period: event.period,
          ),
        );
      },
    );
  }

  Future<void> _onLoadGoalLogsForPeriod(
    LoadGoalLogsForPeriod event,
    Emitter<GoalState> emit,
  ) async {
    print(
      '📊 GoalBloc: Loading goal logs for ${event.goalId}, period: ${event.period}',
    );

    final result = await getGoalLogsForPeriodUseCase(
      GoalLogsForPeriodParams(
        goalId: event.goalId,
        period: event.period,
        limit: event.limit,
      ),
    );

    result.fold(
      (failure) {
        print(
          '❌ GoalBloc: Failed to load goal logs: ${_getFailureMessage(failure)}',
        );
        emit(AnalyticsError(message: _getFailureMessage(failure)));
      },
      (data) {
        print('✅ GoalBloc: Goal logs loaded successfully');
        emit(
          GoalLogsForPeriodLoaded(
            goalId: event.goalId,
            data: data,
            period: event.period,
          ),
        );
      },
    );
  }

  String _getFailureMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return failure.message;
      case NetworkFailure:
        return 'Please check your internet connection';
      case ValidationFailure:
        return failure.message;
      default:
        return 'An unexpected error occurred';
    }
  }

  Map<String, String> _parseValidationErrors(String message) {
    // Simple parsing - in a real app, you might want more sophisticated parsing
    // Based on your backend's error response format
    if (message.toLowerCase().contains('title')) {
      return {'title': message};
    } else if (message.toLowerCase().contains('description')) {
      return {'description': message};
    } else if (message.toLowerCase().contains('category')) {
      return {'category': message};
    } else if (message.toLowerCase().contains('target_frequency')) {
      return {'target_frequency': message};
    } else if (message.toLowerCase().contains('target_count')) {
      return {'target_count': message};
    } else if (message.toLowerCase().contains('status')) {
      return {'status': message};
    } else if (message.toLowerCase().contains('date')) {
      return {'date': message};
    } else if (message.toLowerCase().contains('notes')) {
      return {'notes': message};
    }

    return {'general': message};
  }
}
