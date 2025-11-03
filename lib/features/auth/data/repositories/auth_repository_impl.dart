import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;

  AuthRepositoryImpl({
    required this.remote,
    required this.local,
  });

  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await local.getToken();
    if (token == null) {
      // If no token, try remote to get user without token (e.g. Firebase auth currentUser)
      return remote.getCurrentUser();
    }
    return remote.getCurrentUser();
    // OR, if your remote needs token in your real api, adjust accordingly
  }

  @override
  Future<UserEntity> login({required String email, required String password}) async {
    final user = await remote.login(email: email, password: password);
    // Simulate token from backend (or get real token if remote returns)
    await local.saveToken('token_${user.id}');
    return user;
  }

  @override
  Future<void> logout() async {
    await local.clearToken();
    await remote.logout();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return remote.sendPasswordResetEmail(email);
  }

  @override
  Future<UserEntity> createUserByAdmin({
    required String email,
    required String password,
    required String name,
    required String role,
    required UserPermissions permissions,
  }) {
    // 👈 Delegate the heavy lifting (Firebase Auth and Firestore writes) 
    //    to the Remote Data Source implementation (AuthRemoteDataSourceImplFirebase).
    return remote.createUserByAdmin(
      email: email,
      password: password,
      name: name,
      role: role,
      permissions: permissions,
    );
  }

  @override
  Future<List<UserEntity>> getUsers() {
    return remote.getUsers();
  }
}