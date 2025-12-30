import '../../domain/entities/auth_response.dart';
import 'user_model.dart';

class AuthResponseModel extends AuthResponse {
  const AuthResponseModel({required super.user, required super.token});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'user': (user as UserModel).toJson(), 'token': token};
  }
}
