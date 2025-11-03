enum AuthStatus { authenticated, unauthenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? errorMessage;

  const AuthState._({required this.status, this.userId, this.errorMessage});

  factory AuthState.unauthenticated() =>
      const AuthState._(status: AuthStatus.unauthenticated);

  factory AuthState.authenticated(String userId) =>
      AuthState._(status: AuthStatus.authenticated, userId: userId);

  factory AuthState.loading() => const AuthState._(status: AuthStatus.loading);

  factory AuthState.error(String message) =>
      AuthState._(status: AuthStatus.error, errorMessage: message);
}
