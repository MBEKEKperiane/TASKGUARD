import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const _renderUrl = 'https://taskguard-xilh.onrender.com/api';

  static String get _baseUrl {
    // All platforms point to the hosted Render backend in production.
    // To develop locally on Android, temporarily swap _renderUrl for
    // 'http://192.168.8.101:3000/api' (your machine's LAN IP).
    return _renderUrl;
  }

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        // Auto-refresh on 401
        if (err.response?.statusCode == 401) {
          try {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final token = await _storage.read(key: 'access_token');
              err.requestOptions.headers['Authorization'] = 'Bearer $token';
              final retry = await _dio.fetch(err.requestOptions);
              return handler.resolve(retry);
            }
          } catch (_) {}
        }
        handler.next(err);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return false;

    final res = await Dio().post(
      '$_baseUrl/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    await _storage.write(key: 'access_token', value: res.data['accessToken']);
    await _storage.write(key: 'refresh_token', value: res.data['refreshToken']);
    return true;
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<void> saveTokens(String access, String refresh) async {
    await Future.wait([
      _storage.write(key: 'access_token', value: access),
      _storage.write(key: 'refresh_token', value: refresh),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: 'access_token'),
      _storage.delete(key: 'refresh_token'),
    ]);
  }

  Future<bool> get hasToken async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }
}
