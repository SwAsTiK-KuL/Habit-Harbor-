import 'package:dartz/dartz.dart';
import '../../core/failures/failures.dart';
import '../repository/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}
