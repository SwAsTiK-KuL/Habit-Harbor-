import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Domain
import '../../domain/repository/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/verify_token_usecase.dart';

// Application
import '../../application/auth/auth_bloc.dart';

// Infrastructure / Core
import '../../infrastucture/data_source/auth_local_data_source.dart';
import '../../infrastucture/data_source/auth_remote_data_source.dart';
import '../../infrastucture/repository/auth_repository_impl.dart';
import '../network/api_client.dart';
import '../storage/storage_service.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:3000/api/auth', // Use this for Android emulator
      // For real device, use your PC's local IP: 'http://192.168.x.x:3000/api/auth'
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Optional: Add auth interceptor (will auto-add token when available)
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = sl<StorageService>().getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  sl.registerLazySingleton<Dio>(() => dio);

  // Core
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl<Dio>()));
  sl.registerLazySingleton<StorageService>(
    () => StorageService(sl<SharedPreferences>()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl<StorageService>()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetProfileUseCase>(
    () => GetProfileUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<VerifyTokenUseCase>(
    () => VerifyTokenUseCase(sl<AuthRepository>()),
  );

  // BLoC
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getProfileUseCase: sl<GetProfileUseCase>(),
      verifyTokenUseCase: sl<VerifyTokenUseCase>(),
    ),
  );
}
