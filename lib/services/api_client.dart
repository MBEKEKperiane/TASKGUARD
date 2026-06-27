import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // LOCAL DEV — phone and PC must be on the same Wi-Fi network.
  static const _renderUrl = 'http://192.168.246.77:3000/api';
  // static const _renderUrl = 'https://taskguard-xilh.onrender.com/api'; // Uncomment before production deployment

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
      // Render's free tier spins the backend down when idle; the first
      // request after that can take 30-50s to wake it back up.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // A secure-storage read failure (e.g. a web Web-Crypto decrypt race,
        // or a Keystore hiccup on Android) must not block the whole request
        // pipeline — fall back to sending the request unauthenticated.
        try {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
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

        // Render's free tier can take well over a minute to wake from idle.
        // The very first request after a cold start commonly times out while
        // the instance boots, but an immediate retry succeeds instantly once
        // it's up — so retry once before surfacing "no internet" to the user.
        final isTimeout = err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError;
        final alreadyRetried =
            err.requestOptions.extra['retried_cold_start'] == true;
        if (isTimeout && !alreadyRetried) {
          try {
            err.requestOptions.extra['retried_cold_start'] = true;
            final retry = await _dio.fetch(err.requestOptions);
            return handler.resolve(retry);
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

  // Deliberately unguarded: a read failure here must propagate so that
  // AuthNotifier.initialize() falls back to the cached user instead of
  // treating a transient storage error as "no session".
  Future<bool> get hasToken async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }
}
