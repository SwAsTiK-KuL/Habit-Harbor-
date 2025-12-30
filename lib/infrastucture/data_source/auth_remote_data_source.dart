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
    final response = await apiClient.post(
      '/logout',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response['success'] != true) {
      throw ServerException(response['message'] ?? 'Logout failed');
    }
  }

  @override
  Future<UserModel> getProfile(String token) async {
    final response = await apiClient.get(
      '/profile',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response['success'] == true) {
      return UserModel.fromJson(response['data']['user']);
    } else {
      throw ServerException(response['message'] ?? 'Failed to get profile');
    }
  }

  @override
  Future<UserModel> verifyToken(String token) async {
    final response = await apiClient.get(
      '/verify-token',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response['success'] == true) {
      return UserModel.fromJson(response['data']['user']);
    } else {
      throw ServerException(response['message'] ?? 'Token verification failed');
    }
  }
}
