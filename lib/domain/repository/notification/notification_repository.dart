import 'package:dartz/dartz.dart';
import 'package:habit_harbor/core/failures/failures.dart';

abstract class NotificationRepository {
  Future<Either<Failure, void>> registerToken(String fcmToken);
  Future<Either<Failure, void>> removeToken(String fcmToken);
}
