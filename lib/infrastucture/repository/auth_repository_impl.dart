import 'package:dartz/dartz.dart';
import '../../core/exceptions/exception.dart';
import '../../core/failures/failures.dart';
import '../../domain/entities/auth_request.dart';
import '../../domain/entities/auth_response.dart';
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

      // Cache the token and user data locally
      await localDataSource.cacheToken(authResponse.token);
      await localDataSource.cacheUser(authResponse.user as UserModel);

      return Right(authResponse);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
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

      // Cache the token and user data locally
      await localDataSource.cacheToken(authResponse.token);
      await localDataSource.cacheUser(authResponse.user as UserModel);

      return Right(authResponse);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final token = await localDataSource.getCachedToken();

      if (token != null) {
        await remoteDataSource.logout(token);
      }

      await localDataSource.clearCache();
      return const Right(null);
    } on ServerException catch (e) {
      // Even if server logout fails, clear local data
      await localDataSource.clearCache();
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      // Ensure local data is cleared even on unexpected errors
      await localDataSource.clearCache();
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final token = await localDataSource.getCachedToken();

      if (token == null) {
        return const Left(CacheFailure('No authentication token found'));
      }

      final user = await remoteDataSource.getProfile(token);

      // Update cached user data
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

      if (token == null) {
        return const Left(CacheFailure('No authentication token found'));
      }

      final user = await remoteDataSource.verifyToken(token);

      // Update cached user data
      await localDataSource.cacheUser(user);

      return Right(user);
    } on ServerException catch (e) {
      // Token might be expired or invalid, clear local data
      await localDataSource.clearCache();
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
