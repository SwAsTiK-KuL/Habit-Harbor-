import 'package:dartz/dartz.dart';
import 'package:habit_harbor/domain/repository/notification/notification_repository.dart';
import '../../core/failures/failures.dart';

class RemoveFcmTokenUseCase {
  final NotificationRepository repository;

  RemoveFcmTokenUseCase(this.repository);

  Future<Either<Failure, void>> call(String fcmToken) async {
    return await repository.removeToken(fcmToken);
  }
}
