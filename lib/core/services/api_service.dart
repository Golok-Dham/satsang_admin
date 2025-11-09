import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../app/constants.dart';

/// API Service for backend communication
class ApiService {
  
  ApiService() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),);
    
    _setupInterceptors();
  }
  // Prefer AppConstants.apiBaseUrl as the single source of truth.
  // This remains for backward compatibility; avoid using directly.
  static String get baseUrl => AppConstants.apiBaseUrl;

  late final Dio dio;
  
  void _setupInterceptors() {
    // Response interceptor to handle JSON parsing issues
    dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) {
        // Handle empty responses or string responses that should be JSON
        if (response.data is String && response.data == '{}') {
          response.data = <String, dynamic>{};
        }
        handler.next(response);
      },
    ));
    
    // Auth interceptor - Add Firebase JWT token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          debugPrint('Error getting Firebase token: $e');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Deterministic backend: do NOT auto-retry on failures.
        // Only attempt a single token refresh if the original request had an Authorization header
        // and has not been retried yet.
        if (error.response?.statusCode == 401 &&
            error.requestOptions.headers.containsKey('Authorization') &&
            error.requestOptions.extra['retried'] != true) {
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await user.getIdToken(true); // Force refresh
              final newToken = await user.getIdToken();

              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $newToken';
              options.extra = Map<String, dynamic>.from(options.extra)..['retried'] = true;

              final response = await dio.fetch<dynamic>(options);
              handler.resolve(response);
              return;
            }
          } catch (e) {
            debugPrint('Error refreshing token: $e');
          }
        }
        // Pass the error through; callers will decide how to handle it.
        handler.next(error);
      },
    ),);
    
    // Logging interceptor (development only)
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),);
    }
  }
  
  // Generic HTTP methods
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get<T>(path, queryParameters: queryParameters);
  }
  
  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return dio.post<T>(path, data: data, queryParameters: queryParameters);
  }
  
  Future<Response<T>> put<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return dio.put<T>(path, data: data, queryParameters: queryParameters);
  }
  
  Future<Response<T>> delete<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters}) {
    return dio.delete<T>(path, data: data, queryParameters: queryParameters);
  }

  // ----- Verification helpers -----
  Future<Response<Map<String, dynamic>>> getVerificationStatus() {
    return dio.get<Map<String, dynamic>>('/api/users/me/verification/status');
  }

  Future<Response<Map<String, dynamic>>> markEmailVerified() {
    return dio.post<Map<String, dynamic>>('/api/users/me/verification/email');
  }

  Future<Response<Map<String, dynamic>>> markPhoneVerified({required String phoneNumber}) {
    return dio.post<Map<String, dynamic>>(
      '/api/users/me/verification/phone',
      data: {'phoneNumber': phoneNumber},
    );
  }
}

/// Global API service instance
final apiService = ApiService();
