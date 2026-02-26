import 'package:dartz/dartz.dart';
import 'package:habit_harbor/domain/repository/notification/notification_repository.dart';
import 'package:habit_harbor/infrastucture/data_source/notification/notification_remote_data_source.dart';
import '../../../core/exceptions/exception.dart';
import '../../../core/failures/failures.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> registerToken(String fcmToken) async {
    try {
      await remoteDataSource.registerToken(fcmToken);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> removeToken(String fcmToken) async {
    try {
      await remoteDataSource.removeToken(fcmToken);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }
}
