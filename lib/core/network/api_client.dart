import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String defaultAuthBaseUrl = 'http://10.70.39.143:3000/api/auth';
  static const String defaultGoalsBaseUrl = 'http://10.70.39.143:3000/api';
  static const String authTokenKey = 'auth_token';

  late Dio _dio;
  String? _authToken;
  final String baseUrl;

  // ✅ Constructor now accepts custom base URL
  ApiClient({String? customBaseUrl})
    : baseUrl = customBaseUrl ?? defaultAuthBaseUrl {
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

  // ✅ Named constructors for convenience
  ApiClient.forAuth() : this(customBaseUrl: defaultAuthBaseUrl);
  ApiClient.forGoals() : this(customBaseUrl: defaultGoalsBaseUrl);

  void _setupInterceptors() {
    // Request interceptor to add auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }

          print('🔵 API Request: ${options.method} ${options.path}');
          print('📋 Headers: ${options.headers}');
          print('📋 Data: ${options.data}');
          print('🌐 Base URL: $baseUrl'); // ✅ Show which base URL is being used

          handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '✅ API Response: ${response.statusCode} ${response.requestOptions.path}',
          );
          print('📋 Response Data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          print(
            '❌ API Error: ${error.response?.statusCode} ${error.requestOptions.path}',
          );
          print('❌ Error Message: ${error.message}');
          print('❌ Error Response: ${error.response?.data}');
          handler.next(error);
        },
      ),
    );
  }

  Future<void> _loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(authTokenKey);
      print(
        '🔵 Loaded auth token: ${_authToken != null ? "Token present" : "No token"}',
      );
    } catch (e) {
      print('❌ Error loading auth token: $e');
    }
  }

  Future<void> setAuthToken(String token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(authTokenKey, token);
      print('✅ Auth token saved');
    } catch (e) {
      print('❌ Error saving auth token: $e');
    }
  }

  Future<void> clearAuthToken() async {
    _authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(authTokenKey);
      print('✅ Auth token cleared');
    } catch (e) {
      print('❌ Error clearing auth token: $e');
    }
  }

  String? get authToken => _authToken;
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  // HTTP Methods
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
      case DioExceptionType.unknown:
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}
