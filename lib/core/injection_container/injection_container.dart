import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:habit_harbor/core/service/notification/notification_service.dart';
import 'package:habit_harbor/domain/repository/notification/notification_repository.dart';
import 'package:habit_harbor/domain/usecases/register_fcm_token_usecase.dart';
import 'package:habit_harbor/domain/usecases/remove_fcm_token_usecase.dart';
import 'package:habit_harbor/infrastucture/data_source/notification/notification_remote_data_source.dart';
import 'package:habit_harbor/infrastucture/repository/notification/notification_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../application/auth/auth_bloc.dart';
import '../../application/goal/goal_bloc.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/goals/goals_repository.dart';
import '../../domain/usecases/analytics_usecase.dart';
import '../../domain/usecases/create_goal_usecase.dart';
import '../../domain/usecases/get_all_usecase.dart';
import '../../domain/usecases/get_goals_status_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/log_goals_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_token_usecase.dart';

import '../../infrastucture/data_source/auth_local_data_source.dart';
import '../../infrastucture/data_source/auth_remote_data_source.dart';
import '../../infrastucture/data_source/goals/goal_remote_data_source.dart';
import '../../infrastucture/repository/auth_repository_impl.dart';
import '../../infrastucture/repository/goals/goal_repository_impl.dart';
import '../network/api_client.dart';
import '../storage/storage_service.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  print('🔵 Initializing dependencies...');

  // ─── External ───────────────────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  print('✅ SharedPreferences registered');

  // ─── Production URLs ────────────────────────────────────
  const String baseUrl = 'https://habit-harbor-backend-deploy.vercel.app';
  // final String baseUrl = 'http://10.235.220.143:3000/api/auth/';

  const String authApiUrl = '$baseUrl/api/auth';
  const String goalsApiUrl =
      '$baseUrl/api'; // ✅ Fixed: was 'http://$baseUrl:$port/api'

  print('🔍 Using server: $baseUrl');

  // ─── Auth Dio ───────────────────────────────────────────
  final authDio = Dio(
    BaseOptions(
      baseUrl: authApiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      followRedirects: true,
      maxRedirects: 3,
    ),
  );

  authDio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
      logPrint: (obj) => print('🔵 Auth API: $obj'),
    ),
  );

  authDio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        print(
          '❌ Auth API Error: ${error.response?.statusCode} ${error.message}',
        );
        handler.next(error);
      },
    ),
  );

  sl.registerLazySingleton(() => authDio);
  print('✅ Auth Dio registered');

  // ─── Goals Dio ──────────────────────────────────────────
  final goalsDio = Dio(
    BaseOptions(
      baseUrl: goalsApiUrl, // ✅ Fixed URL
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      followRedirects: true,
      maxRedirects: 3,
    ),
  );

  goalsDio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('🎯 Goals API: $obj'),
    ),
  );

  goalsDio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final storageService = sl<StorageService>();
          final token = await storageService.getToken(); // ✅ reads access_token
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            print('🔐 Auth token added to Goals API request');
          } else {
            print('⚠️ No auth token for Goals API request');
          }
        } catch (e) {
          print('❌ Error getting token for Goals API: $e');
        }
        handler.next(options);
      },
      onError: (error, handler) {
        print(
          '❌ Goals API Error: ${error.response?.statusCode} - ${error.message}',
        );
        handler.next(error);
      },
    ),
  );

  sl.registerLazySingleton(() => goalsDio, instanceName: 'goalsDio');
  print('✅ Goals Dio registered');

  // ─── Core Services ──────────────────────────────────────
  sl.registerLazySingleton<StorageService>(() => StorageService(sl()));
  print('✅ StorageService registered');

  // ─── Connectivity Test ──────────────────────────────────
  try {
    final testResponse = await authDio.get(
      '/health',
      options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    print('✅ Server connection OK: ${testResponse.data}');
  } catch (e) {
    print('⚠️ Server connectivity check failed: $e');
  }

  // ─── ApiClient Instances ────────────────────────────────
  sl.registerLazySingleton<ApiClient>(() => ApiClient.forAuth());
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient.forGoals(),
    instanceName: 'goalsApiClient',
  );
  print('✅ ApiClient instances registered');

  // ─── Data Sources ───────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<GoalRemoteDataSource>(
    () => GoalRemoteDataSourceImpl(sl(instanceName: 'goalsApiClient')),
  );
  print('✅ Data sources registered');

  // ─── Repositories ───────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );
  sl.registerLazySingleton<GoalRepository>(
    () => GoalRepositoryImpl(remoteDataSource: sl()),
  );
  print('✅ Repositories registered');

  // ─── Use Cases — Auth ───────────────────────────────────
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => VerifyTokenUseCase(sl()));
  print('✅ Auth use cases registered');

  // ─── Use Cases — Goals ──────────────────────────────────
  sl.registerLazySingleton(() => GetAllGoalsUseCase(sl()));
  sl.registerLazySingleton(() => CreateGoalUseCase(sl()));
  sl.registerLazySingleton(() => LogGoalUseCase(sl()));
  sl.registerLazySingleton(() => GetGoalStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetOverviewAnalyticsUseCase(sl()));
  sl.registerLazySingleton(() => GetGoalAnalyticsUseCase(sl()));
  sl.registerLazySingleton(() => GetGoalLogsForPeriodUseCase(sl()));
  print('✅ Goal use cases registered');

  // ─── Notifications ──────────────────────────────────────
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(sl(instanceName: 'goalsApiClient')),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => RegisterFcmTokenUseCase(sl()));
  sl.registerLazySingleton(() => RemoveFcmTokenUseCase(sl()));
  print('✅ Notification dependencies registered');

  // ─── BLoCs ──────────────────────────────────────────────
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      getProfileUseCase: sl(),
      verifyTokenUseCase: sl(),
      registerFcmTokenUseCase: sl(),
      removeFcmTokenUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => GoalBloc(
      getAllGoalsUseCase: sl(),
      createGoalUseCase: sl(),
      logGoalUseCase: sl(),
      getGoalStatsUseCase: sl(),
      goalRepository: sl(),
      getOverviewAnalyticsUseCase: sl(),
      getGoalAnalyticsUseCase: sl(),
      getGoalLogsForPeriodUseCase: sl(),
    ),
  );
  print('✅ BLoCs registered');

  print('🎉 All dependencies initialized!');
}
