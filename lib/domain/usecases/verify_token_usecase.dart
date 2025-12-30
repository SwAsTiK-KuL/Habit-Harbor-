import 'package:dartz/dartz.dart';
import '../../core/failures/failures.dart';
import '../entities/user.dart';
import '../repository/auth_repository.dart';

class VerifyTokenUseCase {
  final AuthRepository repository;

  VerifyTokenUseCase(this.repository);

  Future<Either<Failure, User>> call() async {
    return await repository.verifyToken();
  }
}
