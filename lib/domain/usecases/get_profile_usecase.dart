import 'package:dartz/dartz.dart';
import 'package:habit_harbor/core/failures/failures.dart';
import 'package:habit_harbor/domain/repository/auth_repository.dart';
import '../entities/user.dart';

class GetProfileUseCase {
  final AuthRepository repository;

  GetProfileUseCase(this.repository);

  Future<Either<Failure, User>> call() async {
    return await repository.getProfile();
  }
}
