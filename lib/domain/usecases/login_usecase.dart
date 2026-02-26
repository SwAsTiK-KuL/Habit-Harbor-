import 'package:dartz/dartz.dart';
import 'package:habit_harbor/domain/repository/auth_repository.dart';
import '../../core/failures/failures.dart';
import '../entities/auth_request.dart';
import '../entities/auth/auth_response.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, AuthResponse>> call(LoginRequest request) async {
    return await repository.login(request);
  }
}
