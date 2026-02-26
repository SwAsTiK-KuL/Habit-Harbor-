import 'package:dartz/dartz.dart';
import '../../core/exceptions/exception.dart';
import '../../core/failures/failures.dart';
import '../../domain/entities/auth_request.dart';
import '../../domain/entities/auth/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/repository/auth_repository.dart';
import '../data_source/auth_local_data_source.dart';
import '../data_source/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, AuthResponse>> login(LoginRequest request) async {
    try {
      final authResponse = await remoteDataSource.login(
        request.email,
        request.password,
      );

      await localDataSource.cacheToken(authResponse.accessToken);
      await localDataSource.cacheRefreshToken(authResponse.refreshToken);
      await localDataSource.cacheUser(authResponse.user as UserModel);

      return Right(authResponse);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      print('❌ LOGIN ERROR: $e');
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> register(
    RegisterRequest request,
  ) async {
    try {
      final authResponse = await remoteDataSource.register(
        username: request.username,
        email: request.email,
        password: request.password,
        confirmPassword: request.confirmPassword,
        firstName: request.firstName,
        lastName: request.lastName,
      );

      await localDataSource.cacheToken(authResponse.accessToken);
      await localDataSource.cacheRefreshToken(authResponse.refreshToken);
      await localDataSource.cacheUser(authResponse.user as UserModel);

      return Right(authResponse);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      print('❌ REGISTER ERROR: $e');
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final refreshToken = await localDataSource.getCachedRefreshToken();
      if (refreshToken != null) {
        await remoteDataSource.logout(refreshToken: refreshToken);
      }
      await localDataSource.clearCache();
      return const Right(null);
    } on ServerException catch (e) {
      await localDataSource.clearCache();
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      await localDataSource.clearCache();
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> refreshAccessToken() async {
    try {
      final refreshToken = await localDataSource.getCachedRefreshToken();
      if (refreshToken == null) {
        return const Left(
          CacheFailure('No refresh token found. Please log in again.'),
        );
      }

      final newTokens = await remoteDataSource.refreshToken(refreshToken);

      await localDataSource.cacheToken(newTokens.accessToken);
      await localDataSource.cacheRefreshToken(newTokens.refreshToken);

      return Right(newTokens);
    } on ServerException catch (e) {
      await localDataSource.clearCache();
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      await localDataSource.clearCache();
      return Left(ServerFailure('Token refresh failed'));
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final token = await localDataSource.getCachedToken();
      if (token == null)
        return const Left(CacheFailure('No authentication token found'));

      final user = await remoteDataSource.getProfile(token);
      await localDataSource.cacheUser(user);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, User>> verifyToken() async {
    try {
      final token = await localDataSource.getCachedToken();
      if (token == null)
        return const Left(CacheFailure('No authentication token found'));

      final user = await remoteDataSource.verifyToken(token);
      await localDataSource.cacheUser(user);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> clearLocalData() async {
    try {
      await localDataSource.clearCache();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to clear local data'));
    }
  }
}
