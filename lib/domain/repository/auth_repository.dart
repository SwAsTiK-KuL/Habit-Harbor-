import 'package:dartz/dartz.dart';
import 'package:habit_harbor/core/failures/failures.dart';
import '../entities/auth_request.dart';
import '../entities/auth/auth_response.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResponse>> login(LoginRequest request);
  Future<Either<Failure, AuthResponse>> register(RegisterRequest request);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, AuthResponse>> refreshAccessToken();
  Future<Either<Failure, User>> getProfile();
  Future<Either<Failure, User>> verifyToken();
  Future<Either<Failure, void>> clearLocalData();
}
