import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Domain - Auth
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

// Core
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

  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  print('✅ SharedPreferences registered');

  // ✅ FIXED: Using your actual IP address from ipconfig
  final String baseIp = '10.121.108.143'; // Your computer's actual IP
  final String alternativeIp = '10.0.2.2'; // Fallback to emulator mapping
  final int port = 3000;

  print('🔍 Testing server connectivity with IP: $baseIp');

  // ✅ Auth API Dio instance with your actual IP
  final authDio = Dio(
    BaseOptions(
      baseUrl: 'http://$baseIp:$port/api/auth',
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

  // Add logging interceptor for auth API
  authDio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
      logPrint: (obj) => print('🔵 Auth API: $obj'),
    ),
  );

  // ✅ Add connection test interceptor
  authDio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        print('❌ Auth API Connection Error:');
        print('   Status: ${error.response?.statusCode}');
        print('   Message: ${error.message}');
        print('   Type: ${error.type}');
        print('   URL: ${error.requestOptions.uri}');
        handler.next(error);
      },
    ),
  );

  sl.registerLazySingleton(() => authDio);
  print('✅ Auth Dio registered with IP: $baseIp');

  // ✅ Goals API Dio instance with your actual IP
  final goalsDio = Dio(
    BaseOptions(
      baseUrl: 'http://$baseIp:$port/api',
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

  // Add logging interceptor for goals API
  goalsDio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
      logPrint: (obj) => print('🎯 Goals API: $obj'),
    ),
  );

  // ✅ Add auth token interceptor for goals API
  goalsDio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final storageService = sl<StorageService>();
          final token = await storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            print('🔐 Added auth token to Goals API request');
          } else {
            print('⚠️ No auth token found for Goals API request');
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
        print('❌ Response: ${error.response?.data}');
        handler.next(error);
      },
    ),
  );

  sl.registerLazySingleton(() => goalsDio, instanceName: 'goalsDio');
  print('✅ Goals Dio registered with IP: $baseIp');

  // Core services
  sl.registerLazySingleton<StorageService>(() => StorageService(sl()));
  print('✅ StorageService registered');

  // ✅ Test connectivity immediately with your IP
  try {
    print('🔍 Testing server connection to: http://$baseIp:$port');
    final testResponse = await authDio.get(
      '/health',
      options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    print('✅ Server connection SUCCESSFUL!');
    print('📋 Server response: ${testResponse.data}');
  } catch (e) {
    print('❌ Server connection failed with your IP: $e');
    print('🔄 Trying fallback IP: $alternativeIp');

    // Try alternative configuration
    try {
      authDio.options.baseUrl = 'http://$alternativeIp:$port/api/auth';
      goalsDio.options.baseUrl = 'http://$alternativeIp:$port/api';

      final retryResponse = await authDio.get('/health');
      print('✅ Fallback server connection successful!');
    } catch (e2) {
      print('❌ Both IP addresses failed: $e2');
      print('⚠️ Please check if your server is running on port $port');
    }
  }

  // ✅ ApiClient registration
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient.forAuth(), // ✅ Uses /api/auth base URL
  );
  print('✅ Auth ApiClient registered');

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient.forGoals(), // ✅ Uses /api base URL
    instanceName: 'goalsApiClient',
  );
  print('✅ Goals ApiClient registered');

  // Data sources - Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl()),
  );
  print('✅ Auth data sources registered');

  // Data sources - Goals
  sl.registerLazySingleton<GoalRemoteDataSource>(
    () => GoalRemoteDataSourceImpl(sl(instanceName: 'goalsApiClient')),
  );
  print('✅ Goal data source registered');

  // Repository - Auth
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );
  print('✅ Auth repository registered');

  // Repository - Goals
  sl.registerLazySingleton<GoalRepository>(
    () => GoalRepositoryImpl(remoteDataSource: sl()),
  );
  print('✅ Goal repository registered');

  // Use cases - Auth
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => VerifyTokenUseCase(sl()));
  print('✅ Auth use cases registered');

  // Use cases - Goals
  sl.registerLazySingleton(() => GetAllGoalsUseCase(sl()));
  sl.registerLazySingleton(() => CreateGoalUseCase(sl()));
  sl.registerLazySingleton(() => LogGoalUseCase(sl()));
  sl.registerLazySingleton(() => GetGoalStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetOverviewAnalyticsUseCase(sl()));
  sl.registerLazySingleton(() => GetGoalAnalyticsUseCase(sl()));
  sl.registerLazySingleton(() => GetGoalLogsForPeriodUseCase(sl()));

  print('✅ Goal use cases registered');

  // BLoC - Auth
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      getProfileUseCase: sl(),
      verifyTokenUseCase: sl(),
    ),
  );
  print('✅ AuthBloc registered');

  // BLoC - Goals
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
  print('✅ GoalBloc registered');

  print('🎉 All dependencies initialized successfully!');
  print('📱 Using IP: $baseIp for server connectivity');
}

// Helper functions remain the same
Future<void> updateAuthTokenForAllClients(String token) async {
  try {
    final storageService = sl<StorageService>();
    await storageService.saveToken(token);
    print('✅ Auth token updated for all API clients');
  } catch (e) {
    print('❌ Error updating auth token: $e');
  }
}

Future<void> clearAuthTokenForAllClients() async {
  try {
    final storageService = sl<StorageService>();
    await storageService.saveToken('');
    print('✅ Auth token cleared from all API clients');
  } catch (e) {
    print('❌ Error clearing auth token: $e');
  }
}

Future<void> testGoalsAPIConnection() async {
  try {
    final goalsDio = sl<Dio>(instanceName: 'goalsDio');
    final response = await goalsDio.get('/health');
    print('✅ Goals API connection test successful: ${response.data}');
  } catch (e) {
    print('❌ Goals API connection test failed: $e');
  }
}

Future<bool> checkAuthenticationStatus() async {
  try {
    final storageService = sl<StorageService>();
    final token = await storageService.getToken();
    final isAuthenticated = token != null && token.isNotEmpty;
    print(
      '🔐 Authentication status: ${isAuthenticated ? "Authenticated" : "Not authenticated"}',
    );
    return isAuthenticated;
  } catch (e) {
    print('❌ Error checking authentication status: $e');
    return false;
  }
}
