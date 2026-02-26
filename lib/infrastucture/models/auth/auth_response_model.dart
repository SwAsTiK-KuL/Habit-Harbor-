import 'package:habit_harbor/domain/entities/auth/auth_response.dart';
import 'package:habit_harbor/infrastucture/models/user_model.dart';

class AuthResponseModel extends AuthResponse {
  const AuthResponseModel({
    required super.user,
    required super.accessToken,
    required super.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': (user as UserModel).toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }
}
