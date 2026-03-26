import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

String get _baseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000/api';
  }
  // Android Emulator  → 10.0.2.2
  // Real Device (LAN) → your PC's actual IP from ipconfig
  // Gopichand's PC IP → 10.158.22.135
  const bool isEmulator = false; // ← set true if using emulator, false for real device

  if (isEmulator) {
    return 'http://10.0.2.2:3000/api';
  }
  return 'http://10.131.168.135:3000/api';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _storage = const FlutterSecureStorage();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'access_token');
          }
          return handler.next(error);
        },
      ),
    );

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> postFormData(String path, FormData data) => _dio.post(
        path,
        data: data,
        options: Options(contentType: 'multipart/form-data'),
      );
}