import 'package:dio/dio.dart';
import 'package:habit_harbor/core/exceptions/exception.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio) {
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          throw ServerException(_mapErrorMessage(error));
        },
      ),
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: Options(headers: headers),
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw ServerException(_mapErrorMessage(e));
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        options: Options(headers: headers),
        queryParameters: queryParameters,
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw ServerException(_mapErrorMessage(e));
      }
      rethrow;
    }
  }

  String _mapErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.badResponse:
        if (error.response?.data != null &&
            error.response?.data['message'] != null) {
          return error.response!.data['message'];
        }
        return 'Server error occurred. Please try again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
