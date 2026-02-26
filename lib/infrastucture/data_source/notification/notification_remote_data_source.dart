import 'package:habit_harbor/core/exceptions/exception.dart';
import 'package:habit_harbor/core/network/api_client.dart';

abstract class NotificationRemoteDataSource {
  Future<void> registerToken(String fcmToken);
  Future<void> removeToken(String fcmToken);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;

  NotificationRemoteDataSourceImpl(this.apiClient);

  @override
  Future<void> registerToken(String fcmToken) async {
    try {
      final response = await apiClient.post(
        '/notifications/register-token',
        data: {'fcm_token': fcmToken},
      );

      if (response['success'] != true) {
        throw ServerException(
          response['message'] ?? 'Failed to register FCM token',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to register FCM token: $e');
    }
  }

  @override
  Future<void> removeToken(String fcmToken) async {
    try {
      final response = await apiClient.post(
        '/notifications/remove-token',
        data: {'fcm_token': fcmToken},
      );

      if (response['success'] != true) {
        throw ServerException(
          response['message'] ?? 'Failed to remove FCM token',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to remove FCM token: $e');
    }
  }
}
