enum AuthStatus { initial, loading, authenticated, unverified, unauthenticated }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  String? get userEmail => user?['email'] as String?;
  String? get userName => user?['name'] as String?;
}
