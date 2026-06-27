import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_service.dart';
import '../../../services/local_storage.dart';
import '../models/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _auth;

  AuthNotifier(this._auth)
      : super(const AuthState(status: AuthStatus.initial));

  /// Restores session on app launch. If a cached user exists, applies it
  /// immediately — the splash screen must never sit waiting on a slow or
  /// cold-starting backend — then revalidates with the API in the
  /// background. Only blocks on the network when there's no cache yet.
  Future<void> initialize() async {
    state = const AuthState(status: AuthStatus.loading);
    final hasToken = await _auth.isLoggedIn;
    if (!hasToken) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    final cached = LocalStorage.getUser();
    if (cached != null) {
      _applyUser(cached);
      _refreshUserInBackground();
      return;
    }

    try {
      final user = await _auth.getMe();
      await LocalStorage.saveUser(user);
      _applyUser(user);
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _refreshUserInBackground() async {
    try {
      final user = await _auth.getMe();
      await LocalStorage.saveUser(user);
      _applyUser(user);
    } catch (_) {
      // Stale cache is fine to keep showing — don't log the user out just
      // because a background refresh failed.
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user =
          await _auth.register(email: email, password: password, name: name);
      // New accounts must verify their email via the 6-digit code before
      // reaching the dashboard.
      _applyUser(user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _extractMessage(e),
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await _auth.login(email: email, password: password);
      _applyUser(user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _extractMessage(e),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await _auth.signInWithGoogle();
      _applyUser(user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _extractMessage(e),
      );
    }
  }

  Future<void> resendVerificationEmail() async {
    await _auth.resendVerificationEmail();
  }

  /// Submits the 6-digit code. Throws on invalid/expired code.
  Future<void> verifyEmailCode(String code) async {
    await _auth.verifyEmailCode(code);
    final user = await _auth.getMe();
    await LocalStorage.saveUser(user);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> logout() async {
    await _auth.logout();
    await LocalStorage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void _applyUser(Map<String, dynamic> user) {
    final emailVerified = user['emailVerified'] as bool? ?? false;
    // Google-authenticated users have an inherently verified email
    final provider = user['provider'] as String? ?? '';
    final isVerified = emailVerified || provider == 'google';
    state = isVerified
        ? AuthState(status: AuthStatus.authenticated, user: user)
        : AuthState(status: AuthStatus.unverified, user: user);
  }

  String _extractMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['error'] ?? data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'No internet connection. Please try again.';
      }
    }
    final raw = e.toString();
    return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }
}

final authServiceProvider = Provider<AuthService>((_) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
