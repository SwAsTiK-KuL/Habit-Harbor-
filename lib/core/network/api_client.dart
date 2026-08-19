import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // ─── Base URLs For Vercel ────────────────────────────────────────────
  // static const String defaultAuthBaseUrl =
  //     'https://habit-harbor-backend-deploy.vercel.app/api/auth';
  // static const String defaultGoalsBaseUrl =
  //     'https://habit-harbor-backend-deploy.vercel.app/api';

  // Base URLs For GCP Cloud

  static const String defaultAuthBaseUrl =
      'https://habit-harbor-backend-1027244281745.asia-south1.run.app/api/auth';
  static const String defaultGoalsBaseUrl =
      'https://habit-harbor-backend-1027244281745.asia-south1.run.app/api';

  // //For Locally Run Server
  // static const String defaultAuthBaseUrl = 'http://10.207.134.23:3000/api/auth';
  // static const String defaultGoalsBaseUrl = 'http://10.207.134.23:3000/api';

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  late Dio _dio;
  final String baseUrl;

  // ✅ FIX: SharedPreferences is injected, not fetched inside interceptors.
  // Calling SharedPreferences.getInstance() inside a Dio interceptor (async)
  // causes a deadlock in release mode — the interceptor hangs waiting for
  // getInstance() which is locked by another operation, freezing the entire
  // network call and leaving AuthBloc permanently stuck on AuthLoading.
  final SharedPreferences _prefs;

  // ─── Constructors ────────────────────────────────────────

  ApiClient({required SharedPreferences prefs, String? customBaseUrl})
    : baseUrl = customBaseUrl ?? defaultAuthBaseUrl,
      _prefs = prefs {
    print('🔵 ApiClient created with baseUrl: $baseUrl');
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _setupInterceptors();
  }

  // ✅ Named constructors now require prefs to be passed in.
  // Use ApiClient.forAuth(prefs: sl()) in injection_container.dart.
  ApiClient.forAuth({required SharedPreferences prefs})
    : this(prefs: prefs, customBaseUrl: defaultAuthBaseUrl);

  ApiClient.forGoals({required SharedPreferences prefs})
    : this(prefs: prefs, customBaseUrl: defaultGoalsBaseUrl);

  // ─── Interceptors ────────────────────────────────────────

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        // ✅ FIX: Use injected _prefs synchronously — no async, no deadlock.
        onRequest: (options, handler) {
          try {
            final token = _prefs.getString(accessTokenKey);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              print('🔐 Token attached: ${options.path}');
            } else {
              print('⚠️ No token for: ${options.path}');
            }
          } catch (e) {
            print('❌ Error reading token: $e');
          }
          print('🔵 ${options.method} ${options.path}');
          handler.next(options);
        },

        onResponse: (response, handler) {
          print('✅ ${response.statusCode} ${response.requestOptions.path}');
          handler.next(response);
        },

        // ✅ On 401 — attempt token refresh
        onError: (error, handler) async {
          print('❌ ${error.response?.statusCode} ${error.requestOptions.path}');

          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/refresh') &&
              !error.requestOptions.path.contains('/login') &&
              !error.requestOptions.path.contains('/register')) {
            print('🔄 401 received — attempting token refresh...');
            final refreshed = await _tryRefreshToken();

            if (refreshed) {
              print('✅ Token refreshed — retrying original request...');
              try {
                // ✅ Use _prefs synchronously for the retry token too
                final newToken = _prefs.getString(accessTokenKey);
                final retryOptions = error.requestOptions;
                retryOptions.headers['Authorization'] = 'Bearer $newToken';
                final retryResponse = await _dio.fetch(retryOptions);
                return handler.resolve(retryResponse);
              } catch (retryError) {
                print('❌ Retry failed after token refresh: $retryError');
                return handler.next(error);
              }
            } else {
              print('❌ Token refresh failed — clearing session');
              _clearAllTokensSync();
              return handler.next(error);
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  // ─── Token Refresh Helper ────────────────────────────────

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = _prefs.getString(refreshTokenKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        print('⚠️ No refresh token stored');
        return false;
      }

      // Use a plain Dio (bypasses this interceptor) for refresh
      final refreshDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      final refreshUrl = '$defaultAuthBaseUrl/refresh';

      final response = await refreshDio.post(
        refreshUrl,
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        // ✅ Save new rotated token pair synchronously
        await _prefs.setString(accessTokenKey, data['access_token'] as String);
        await _prefs.setString(
          refreshTokenKey,
          data['refresh_token'] as String,
        );
        print('✅ Token pair rotated and saved');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Token refresh error: $e');
      return false;
    }
  }

  // ✅ Synchronous clear — safe to call anywhere
  void _clearAllTokensSync() {
    try {
      _prefs.remove(accessTokenKey);
      _prefs.remove(refreshTokenKey);
      _prefs.remove('user_data');
    } catch (e) {
      print('❌ Error clearing tokens: $e');
    }
  }

  // ─── Token Management ────────────────────────────────────

  Future<void> setAuthToken(String token) async {
    await _prefs.setString(accessTokenKey, token);
    print('✅ Access token saved');
  }

  Future<void> setRefreshToken(String token) async {
    await _prefs.setString(refreshTokenKey, token);
    print('✅ Refresh token saved');
  }

  Future<void> clearAuthToken() async {
    _clearAllTokensSync();
    print('✅ All tokens cleared');
  }

  bool get isAuthenticated {
    final token = _prefs.getString(accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  // ─── HTTP Methods ────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Server error occurred';
        return Exception('Server error ($statusCode): $message');
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      case DioExceptionType.connectionError:
        return Exception('No internet connection. Please check your network.');
      case DioExceptionType.badCertificate:
        return Exception('SSL certificate error');
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}
