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
  Future<void> logout(String token);
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
  Future<void> logout(String token) async {
    // ✅ FIXED: Since your ApiClient doesn't support headers parameter,
    // we'll need to modify this approach. Your ApiClient should handle
    // auth headers automatically or we need to set the token beforehand
    try {
      final response = await apiClient.post('/logout');

      if (response['success'] != true) {
        throw ServerException(response['message'] ?? 'Logout failed');
      }
    } catch (e) {
      throw ServerException('Logout failed: $e');
    }
  }

  @override
  Future<UserModel> getProfile(String token) async {
    // ✅ FIXED: Your ApiClient should handle auth automatically via interceptors
    try {
      final response = await apiClient.get('/profile');

      if (response['success'] == true) {
        return UserModel.fromJson(response['data']['user']);
      } else {
        throw ServerException(response['message'] ?? 'Failed to get profile');
      }
    } catch (e) {
      throw ServerException('Failed to get profile: $e');
    }
  }

  @override
  Future<UserModel> verifyToken(String token) async {
    // ✅ FIXED: Your ApiClient should handle auth automatically via interceptors
    try {
      final response = await apiClient.get('/verify-token');

      if (response['success'] == true) {
        return UserModel.fromJson(response['data']['user']);
      } else {
        throw ServerException(
          response['message'] ?? 'Token verification failed',
        );
      }
    } catch (e) {
      throw ServerException('Token verification failed: $e');
    }
  }
}
