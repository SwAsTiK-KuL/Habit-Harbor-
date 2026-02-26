import '../../core/exceptions/exception.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../../core/network/api_client.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
  Future<AuthResponseModel> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    String? firstName,
    String? lastName,
  });
  Future<void> logout({required String refreshToken});
  Future<AuthResponseModel> refreshToken(String refreshToken);
  Future<UserModel> getProfile(String token);
  Future<UserModel> verifyToken(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    final response = await apiClient.post(
      '/login',
      data: {'email': email, 'password': password},
    );
    if (response['success'] == true) {
      return AuthResponseModel.fromJson(response['data']);
    } else {
      throw ServerException(response['message'] ?? 'Login failed');
    }
  }

  @override
  Future<AuthResponseModel> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    String? firstName,
    String? lastName,
  }) async {
    final response = await apiClient.post(
      '/register',
      data: {
        'username': username,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
      },
    );
    if (response['success'] == true) {
      return AuthResponseModel.fromJson(response['data']);
    } else {
      throw ServerException(response['message'] ?? 'Registration failed');
    }
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    try {
      final response = await apiClient.post(
        '/logout',
        data: {'refresh_token': refreshToken},
      );
      if (response['success'] != true) {
        throw ServerException(response['message'] ?? 'Logout failed');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Logout failed: $e');
    }
  }

  @override
  Future<AuthResponseModel> refreshToken(String refreshToken) async {
    try {
      final response = await apiClient.post(
        '/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;

        return AuthResponseModel(
          user: UserModel(
            id: 'pending',
            username: '',
            email: '',
            createdAt: DateTime.now(),
          ),
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
        );
      } else {
        throw ServerException(response['message'] ?? 'Token refresh failed');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Token refresh failed: $e');
    }
  }

  @override
  Future<UserModel> getProfile(String token) async {
    try {
      final response = await apiClient.get('/profile');
      if (response['success'] == true) {
        return UserModel.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        throw ServerException(response['message'] ?? 'Failed to get profile');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get profile: $e');
    }
  }

  @override
  Future<UserModel> verifyToken(String token) async {
    try {
      final response = await apiClient.get('/verify-token');
      if (response['success'] == true) {
        return UserModel.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        throw ServerException(
          response['message'] ?? 'Token verification failed',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Token verification failed: $e');
    }
  }
}
