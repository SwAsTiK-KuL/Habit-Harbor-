import 'package:dartz/dartz.dart';
import '../../core/failures/failures.dart';
import '../entities/auth_request.dart';
import '../entities/auth_response.dart';
import '../repository/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, AuthResponse>> call(RegisterRequest request) async {
    return await repository.register(request);
  }
}
