import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import 'api_result.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    String? token,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
                responseType: ResponseType.json,
                headers: <String, String>{
                  'Content-Type': 'application/json',
                  if (token != null && token.isNotEmpty)
                    'Authorization': 'Bearer $token',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          if (kDebugMode) {
            debugPrint(
              '[RoadGuard API] ${options.method} ${options.baseUrl}${options.path}',
            );
          }
          handler.next(options);
        },
        onResponse: (Response<dynamic> response, ResponseInterceptorHandler handler) {
          if (kDebugMode) {
            debugPrint(
              '[RoadGuard API] ${response.statusCode} ${response.requestOptions.path}',
            );
          }
          handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) {
          if (kDebugMode) {
            debugPrint(
              '[RoadGuard API] ERROR ${error.requestOptions.path} ${error.message}',
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;

  Future<ApiResult<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return ApiResult<Map<String, dynamic>>.success(
        data: _toMap(response.data),
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      return ApiResult<Map<String, dynamic>>.failure(
        message: _mapDioError(error),
        statusCode: error.response?.statusCode,
      );
    } catch (_) {
      return ApiResult<Map<String, dynamic>>.failure(
        message: 'Unexpected network error occurred.',
      );
    }
  }

  Future<ApiResult<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );

      return ApiResult<Map<String, dynamic>>.success(
        data: _toMap(response.data),
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      return ApiResult<Map<String, dynamic>>.failure(
        message: _mapDioError(error),
        statusCode: error.response?.statusCode,
      );
    } catch (_) {
      return ApiResult<Map<String, dynamic>>.failure(
        message: 'Unexpected network error occurred.',
      );
    }
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{'data': data};
  }

  String _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out while contacting the RoadGuard backend.';
      case DioExceptionType.sendTimeout:
        return 'Request timed out while sending data to the backend.';
      case DioExceptionType.receiveTimeout:
        return 'The backend took too long to respond.';
      case DioExceptionType.badResponse:
        final dynamic detail = error.response?.data;
        if (detail is Map && detail['detail'] is String) {
          return detail['detail'] as String;
        }
        return 'Backend request failed with status ${error.response?.statusCode}.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Unable to reach the RoadGuard backend.';
      case DioExceptionType.badCertificate:
        return 'Backend certificate validation failed.';
      case DioExceptionType.unknown:
        return 'An unknown network error occurred.';
    }
  }
}
