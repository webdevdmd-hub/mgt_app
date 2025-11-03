import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mgt_app/features/auth/domain/entities/user_entity.dart';
import 'package:mgt_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:mgt_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mgt_app/features/auth/domain/usecases/get_users_usecase.dart';
import 'package:mgt_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:mgt_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mgt_app/features/auth/presentation/providers/auth_state.dart';
import 'package:mgt_app/features/auth/data/repositories/auth_repository_impl_firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Firestore-backed repo enforces admin-created users; no allowlist arg needed
  return AuthRepositoryImplFirebase();
});

/// Use case providers
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.read(authRepositoryProvider));
});

final getUsersUseCaseProvider = Provider<GetUsersUseCase>((ref) {
  return GetUsersUseCase(ref.read(authRepositoryProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.read(authRepositoryProvider));
});

/// Auth notifier + state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref: ref,
    getCurrentUser: ref.read(getCurrentUserUseCaseProvider),
    loginUseCase: ref.read(loginUseCaseProvider),
    logoutUseCase: ref.read(logoutUseCaseProvider),
  );
});

/// Expose the current user object
final currentUserProvider = Provider<UserEntity?>((ref) {
  ref.watch(authProvider); // trigger rebuild on state changes
  return ref.read(authProvider.notifier).user;
});

final usersProvider = FutureProvider<List<UserEntity>>((ref) async {
  final getUsers = ref.read(getUsersUseCaseProvider);
  return await getUsers();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final GetCurrentUserUseCase getCurrentUser;
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;

  UserEntity? _user;
  UserEntity? get user => _user;

  AuthNotifier({
    required this.ref,
    required this.getCurrentUser,
    required this.loginUseCase,
    required this.logoutUseCase,
  }) : super(AuthState.loading()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final u = await getCurrentUser();
      _user = u;

      debugPrint('AuthNotifier._bootstrap user=$u');
      state = u == null
          ? AuthState.unauthenticated()
          : AuthState.authenticated(u.id);
    } catch (_) {
      state = AuthState.error('Failed to restore session');
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final u = await loginUseCase(email: email, password: password);
      _user = u;
      state = AuthState.authenticated(u.id);
    } catch (e) {
      state = AuthState.error(e.toString()); // show real reason
    }
  }

  Future<void> logout() async {
    state = AuthState.loading();
    await logoutUseCase();
    _user = null;
    state = AuthState.unauthenticated();
  }

  Future<void> sendPasswordReset(String email) {
    // Directly call repository for this optional action.
    return ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
  }

  // ...inside successful sign-in / after setting claims...
  Future<void> refreshIdToken() async {
    await FirebaseAuth.instance.currentUser?.getIdToken(
      true,
    ); // refresh token so custom claims appear
    // then update your currentUserProvider or reload user profile
  }
}
