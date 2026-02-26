import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // ─── Base URLs ────────────────────────────────────────────

  // For Locally Run Server
  // static const String defaultAuthBaseUrl =
  //     'http://10.235.220.143:3000/api/auth';
  // static const String defaultGoalsBaseUrl = 'http://10.235.220.143:3000/api';

  static const String defaultAuthBaseUrl =
      'https://habit-harbor-backend-deploy.vercel.app/api/auth';
  static const String defaultGoalsBaseUrl =
      'https://habit-harbor-backend-deploy.vercel.app/api';

  // ✅ Updated key names to match StorageService
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  late Dio _dio;
  String? _authToken;
  final String baseUrl;

  // ─── Constructors ────────────────────────────────────────
  ApiClient({String? customBaseUrl})
    : baseUrl = customBaseUrl ?? defaultAuthBaseUrl {
    print('🔵 ApiClient created with baseUrl: $baseUrl');
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _setupInterceptors();
    _loadAuthToken();
  }

  ApiClient.forAuth() : this(customBaseUrl: defaultAuthBaseUrl);
  ApiClient.forGoals() : this(customBaseUrl: defaultGoalsBaseUrl);

  // ─── Interceptors ────────────────────────────────────────

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        // ── Attach access token to every request ───────────
        onRequest: (options, handler) async {
          try {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString(accessTokenKey); // ✅ correct key
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

        // ✅ On 401 — silently try to refresh the access token
        onError: (error, handler) async {
          print('❌ ${error.response?.statusCode} ${error.requestOptions.path}');

          // Only attempt refresh on 401 and avoid infinite loop on /refresh itself
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/refresh') &&
              !error.requestOptions.path.contains('/login') &&
              !error.requestOptions.path.contains('/register')) {
            print('🔄 401 received — attempting token refresh...');
            final refreshed = await _tryRefreshToken();

            if (refreshed) {
              print('✅ Token refreshed — retrying original request...');
              try {
                // Retry the original request with the new access token
                final prefs = await SharedPreferences.getInstance();
                final newToken = prefs.getString(accessTokenKey);

                final retryOptions = error.requestOptions;
                retryOptions.headers['Authorization'] = 'Bearer $newToken';

                final retryResponse = await _dio.fetch(retryOptions);
                return handler.resolve(retryResponse);
              } catch (retryError) {
                print('❌ Retry failed after token refresh: $retryError');
                return handler.next(error);
              }
            } else {
              // ✅ Refresh failed — clear tokens, user must log in again
              print('❌ Token refresh failed — clearing session');
              await _clearAllTokens();
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
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(refreshTokenKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        print('⚠️ No refresh token stored');
        return false;
      }

      // Call /refresh directly via a plain Dio (bypasses this interceptor)
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: baseUrl.contains('/auth') ? baseUrl : defaultAuthBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      // Make sure we hit /api/auth/refresh regardless of current baseUrl
      final refreshUrl =
          defaultAuthBaseUrl.endsWith('/auth')
              ? '$defaultAuthBaseUrl/refresh'
              : '${defaultAuthBaseUrl.replaceAll(RegExp(r'/api.*'), '')}/api/auth/refresh';

      final response = await refreshDio.post(
        refreshUrl,
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        // ✅ Save new rotated token pair
        await prefs.setString(accessTokenKey, data['access_token'] as String);
        await prefs.setString(refreshTokenKey, data['refresh_token'] as String);

        print('✅ Token pair rotated and saved');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Token refresh error: $e');
      return false;
    }
  }

  Future<void> _clearAllTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(accessTokenKey);
      await prefs.remove(refreshTokenKey);
      await prefs.remove('user_data');
    } catch (e) {
      print('❌ Error clearing tokens: $e');
    }
  }

  // ─── Token Management ────────────────────────────────────

  Future<void> _loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(accessTokenKey);
      print('🔵 Auth token: ${_authToken != null ? "present" : "absent"}');
    } catch (e) {
      print('❌ Error loading auth token: $e');
    }
  }

  Future<void> setAuthToken(String token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(accessTokenKey, token);
      print('✅ Access token saved');
    } catch (e) {
      print('❌ Error saving auth token: $e');
    }
  }

  Future<void> setRefreshToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(refreshTokenKey, token);
      print('✅ Refresh token saved');
    } catch (e) {
      print('❌ Error saving refresh token: $e');
    }
  }

  Future<void> clearAuthToken() async {
    await _clearAllTokens();
    _authToken = null;
    print('✅ All tokens cleared');
  }

  String? get authToken => _authToken;
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

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
