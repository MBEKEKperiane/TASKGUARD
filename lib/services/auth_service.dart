import 'package:google_sign_in/google_sign_in.dart';
import 'api_client.dart';
import 'local_storage.dart';

class AuthService {
  final _api = ApiClient();

  // serverClientId must be the Web OAuth client ID — the backend verifies the
  // Google ID token's `aud` claim against this same value (GOOGLE_CLIENT_ID).
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '1022948483427-k3ar0hkrdrsnpgngb23qrius7h2f0lc1.apps.googleusercontent.com',
  );

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final res = await _api.post('/auth/register', data: {
      'email': email,
      'password': password,
      if (name != null && name.isNotEmpty) 'name': name,
    });
    final data = res.data as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    await _api.saveTokens(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
    await LocalStorage.saveUser(user);
    return user;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = res.data as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    await _api.saveTokens(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
    await LocalStorage.saveUser(user);
    return user;
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    // Sign out first so the account picker always appears (avoids silent reuse
    // of a previous account that may belong to a different user).
    await _googleSignIn.signOut();
    final account = await _googleSignIn.signIn();
    if (account == null) throw Exception('Google sign-in was cancelled.');

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw Exception(
        'Could not obtain a Google ID token. '
        'Add your Web Client ID as serverClientId in GoogleSignIn().',
      );
    }

    final res = await _api.post('/auth/google', data: {'idToken': idToken});
    final data = res.data as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    await _api.saveTokens(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
    await LocalStorage.saveUser(user);
    return user;
  }

  Future<void> resendVerificationEmail() async {
    await _api.post('/auth/resend-verification');
  }

  Future<void> verifyEmailCode(String code) async {
    await _api.post('/auth/verify-email', data: {'code': code});
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', data: {'email': email});
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _api.get('/auth/me');
    return res.data['user'] as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _api.clearTokens();
    await _googleSignIn.signOut();
  }

  Future<bool> get isLoggedIn => _api.hasToken;
}
