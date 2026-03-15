import 'package:dio/dio.dart';
import 'package:habit_harbor/domain/entities/goals/goal_reminder.dart';
import 'package:habit_harbor/infrastucture/models/goals/goal.dart';
import '../../../core/exceptions/exception.dart';
import '../../../core/network/api_client.dart';
import '../../../domain/entities/goals/goals_log.dart';
import '../../../domain/entities/goals/goals_stats.dart';
import '../../models/goals/goal_model.dart';
import '../../models/goals/goal_log_model.dart';
import '../../models/goals/goals_stats_model.dart';

abstract class GoalRemoteDataSource {
  Future<Goal> createGoal({
    required String title,
    required String description,
    required String category,
    required String color,
    required String icon,
    required String targetFrequency,
    required int targetCount,
  });

  Future<List<Goal>> getAllGoals();
  Future<Goal> getGoal(String goalId);

  Future<Goal> updateGoal({
    required String goalId,
    String? title,
    String? description,
    String? category,
    String? color,
    String? icon,
    String? targetFrequency,
    int? targetCount,
  });

  Future<void> deleteGoal(String goalId);
  Future<GoalStats> getGoalStats(String goalId, {int days = 30});

  Future<GoalLog> logGoal({
    required String goalId,
    required String status,
    String? date,
    String? notes,
  });

  Future<List<GoalLog>> getGoalLogs(String goalId, {int limit = 30});
  Future<List<GoalLog>> getTodayLogs();

  Future<GoalLog> updateGoalLog({
    required String logId,
    String? status,
    String? notes,
  });

  Future<GoalLog> editHistoryLog({
    required String goalId,
    required String date,
    required String status,
    String? notes,
  });

  Future<Goal> updateGoalReminders({
    required String goalId,
    required List<GoalReminder> reminders,
  });

  Future<void> deleteGoalLog(String logId);

  // Analytics methods
  Future<Map<String, dynamic>> getOverviewAnalytics({String period = 'month'});
  Future<Map<String, dynamic>> getGoalAnalytics({
    required String goalId,
    String period = 'month',
  });
  Future<Map<String, dynamic>> getGoalLogsForPeriod({
    required String goalId,
    String period = 'month',
    int limit = 365,
  });
}

class GoalRemoteDataSourceImpl implements GoalRemoteDataSource {
  final ApiClient apiClient;

  GoalRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Goal> createGoal({
    required String title,
    required String description,
    required String category,
    required String color,
    required String icon,
    required String targetFrequency,
    required int targetCount,
  }) async {
    try {
      print('🔵 GoalRemoteDataSource: Creating goal with title: $title');

      final response = await apiClient.post(
        '/goals',
        data: {
          'title': title,
          'description': description,
          'category': category,
          'color': color,
          'icon': icon,
          'target_frequency': targetFrequency,
          'target_count': targetCount,
        },
      );

      print(
        '✅ GoalRemoteDataSource: Received response: ${response['success']}',
      );

      if (response['success'] == true) {
        final goal = GoalModel.fromJson(response['data']).toEntity();
        print('✅ Goal entity created: ${goal.id}');
        return goal;
      } else {
        throw ServerException(response['message'] ?? 'Failed to create goal');
      }
    } on DioException catch (e) {
      print('❌ Network error creating goal: ${e.message}');
      print('❌ Response data: ${e.response?.data}');
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error creating goal: $e');
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<Goal>> getAllGoals() async {
    try {
      print('🔵 GoalRemoteDataSource: Fetching all goals');

      final response = await apiClient.get('/goals');

      print(
        '✅ GoalRemoteDataSource: Received goals response: ${response['success']}',
      );

      if (response['success'] == true) {
        final List<dynamic> goalsData = response['data'] as List<dynamic>;
        final goals =
            goalsData
                .map((json) => GoalModel.fromJson(json).toEntity())
                .toList();
        print('✅ Parsed ${goals.length} goals');
        return goals;
      } else {
        throw ServerException(response['message'] ?? 'Failed to fetch goals');
      }
    } on DioException catch (e) {
      print('❌ Network error fetching goals: ${e.message}');
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error fetching goals: $e');
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<Goal> getGoal(String goalId) async {
    try {
      final response = await apiClient.get('/goals/$goalId');

      if (response['success'] == true) {
        return GoalModel.fromJson(response['data']).toEntity();
      } else {
        throw ServerException(response['message'] ?? 'Failed to fetch goal');
      }
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<Goal> updateGoal({
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
      final Map<String, dynamic> data = {};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (category != null) data['category'] = category;
      if (color != null) data['color'] = color;
      if (icon != null) data['icon'] = icon;
      if (targetFrequency != null) data['target_frequency'] = targetFrequency;
      if (targetCount != null) data['target_count'] = targetCount;

      final response = await apiClient.put('/goals/$goalId', data: data);

      if (response['success'] == true) {
        return GoalModel.fromJson(response['data']).toEntity();
      } else {
        throw ServerException(response['message'] ?? 'Failed to update goal');
      }
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    try {
      final response = await apiClient.delete('/goals/$goalId');

      if (response['success'] != true) {
        throw ServerException(response['message'] ?? 'Failed to delete goal');
      }
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<GoalStats> getGoalStats(String goalId, {int days = 30}) async {
    try {
      final response = await apiClient.get('/goals/$goalId/stats?days=$days');

      if (response['success'] == true) {
        return GoalStatsModel.fromJson(response['data']).toEntity();
      } else {
        throw ServerException(
          response['message'] ?? 'Failed to fetch goal stats',
        );
      }
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<GoalLog> logGoal({
    required String goalId,
    required String status,
    String? date,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> data = {'status': status};
      if (date != null) data['date'] = date;
      if (notes != null) data['notes'] = notes;

      final response = await apiClient.post('/goals/$goalId/logs', data: data);

      if (response['success'] == true) {
        return GoalLogModel.fromJson(response['data']).toEntity();
      } else {
        throw ServerException(response['message'] ?? 'Failed to log goal');
      }
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<GoalLog>> getGoalLogs(String goalId, {int limit = 30}) async {
    try {
      final response = await apiClient.get('/goals/$goalId/logs?limit=$limit');

      if (response['success'] == true) {
        final List<dynamic> logsData = response['data'] as List<dynamic>;
        return logsData
            .map((json) => GoalLogModel.fromJson(json).toEntity())
            .toList();
      } else {
        throw ServerException(
          response['message'] ?? 'Failed to fetch goal logs',
        );
      }
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<GoalLog>> getTodayLogs() async {
    try {
      final response = await apiClient.get('/goal-logs/today');

      if (response['success'] == true) {
        final List<dynamic> logsData = response['data'] as List<dynamic>;
        return logsData
            .map((json) => GoalLogModel.fromJson(json).toEntity())
            .toList();
      } else {
        throw ServerException(
          response['message'] ?? 'Failed to fetch today\'s logs',
        );
      }
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<GoalLog> updateGoalLog({
    required String logId,
    String? status,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (status != null) data['status'] = status;
      if (notes != null) data['notes'] = notes;

      final response = await apiClient.put('/goal-logs/$logId', data: data);

      if (response['success'] == true) {
        return GoalLogModel.fromJson(response['data']).toEntity();
      } else {
        throw ServerException(
          response['message'] ?? 'Failed to update goal log',
        );
      }
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<void> deleteGoalLog(String logId) async {
    try {
      final response = await apiClient.delete('/goal-logs/$logId');

      if (response['success'] != true) {
        throw ServerException(
          response['message'] ?? 'Failed to delete goal log',
        );
      }
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  // ✅ NEW ANALYTICS METHODS
  @override
  Future<Map<String, dynamic>> getOverviewAnalytics({
    String period = 'month',
  }) async {
    try {
      print(
        '📊 GoalRemoteDataSource: Fetching overview analytics for period: $period',
      );

      final response = await apiClient.get(
        '/analytics/overview?period=$period',
      );

      print(
        '✅ GoalRemoteDataSource: Received analytics response: ${response['success']}',
      );

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw ServerException(
          response['message'] ?? 'Failed to fetch analytics',
        );
      }
    } on DioException catch (e) {
      print('❌ Network error fetching analytics: ${e.message}');
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error fetching analytics: $e');
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getGoalAnalytics({
    required String goalId,
    String period = 'month',
  }) async {
    try {
      print(
        '📊 GoalRemoteDataSource: Fetching goal analytics for $goalId, period: $period',
      );

      final response = await apiClient.get(
        '/goals/$goalId/analytics?period=$period',
      );

      print(
        '✅ GoalRemoteDataSource: Received goal analytics response: ${response['success']}',
      );

      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw ServerException(
          response['message'] ?? 'Failed to fetch goal analytics',
        );
      }
    } on DioException catch (e) {
      print('❌ Network error fetching goal analytics: ${e.message}');
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error fetching goal analytics: $e');
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  @override
  Future<Map<String, dynamic>> getGoalLogsForPeriod({
    required String goalId,
    String period = 'month',
    int limit = 365,
  }) async {
    try {
      print('📊 GoalRemoteDataSource: Fetching goal logs for $goalId');

      final response = await apiClient.get(
        '/goals/$goalId/logs?limit=$limit', // ← period removed
      );

      print(
        '✅ GoalRemoteDataSource: Received goal logs response: ${response['success']}',
      );

      if (response['success'] == true) {
        final List<dynamic> logs = response['data'] as List<dynamic>;
        return {
          // ← wrap List in Map
          'logs': logs,
          'total': logs.length,
        };
      } else {
        throw ServerException(
          response['message'] ?? 'Failed to fetch goal logs',
        );
      }
    } on DioException catch (e) {
      print('❌ Network error fetching goal logs: ${e.message}');
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error fetching goal logs: $e');
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<GoalLog> editHistoryLog({
    required String goalId,
    required String date,
    required String status,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> data = {'status': status};
      if (notes != null) data['notes'] = notes;

      final response = await apiClient.put(
        '/goals/$goalId/logs/date/$date',
        data: data,
      );

      if (response['success'] == true) {
        return GoalLogModel.fromJson(response['data']).toEntity();
      } else {
        throw ServerException(
          response['message'] ?? 'Failed to edit history log',
        );
      }
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<Goal> updateGoalReminders({
    required String goalId,
    required List<GoalReminder> reminders,
  }) async {
    try {
      final response = await apiClient.put(
        '/goals/$goalId/reminders',
        data: {
          'reminders':
              reminders
                  .map(
                    (r) => {
                      'id': r.id,
                      'time': r.time,
                      'label': r.label,
                      'enabled': r.enabled,
                    },
                  )
                  .toList(),
        },
      );
      if (response['success'] == true) {
        return GoalModel.fromJson(response['data']).toEntity();
      }
      throw ServerException(
        response['message'] ?? 'Failed to update reminders',
      );
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }
}
