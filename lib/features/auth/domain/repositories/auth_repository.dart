import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Returns the currently authenticated user or null if no user is logged in
  Future<UserEntity?> getCurrentUser();

  /// Returns a list of all users
  Future<List<UserEntity>> getUsers();

  /// Attempts to login with given credentials and returns user on success
  Future<UserEntity> login({required String email, required String password});

  /// Logs out the current user
  Future<void> logout();

  /// Sends a password reset email
  Future<void> sendPasswordResetEmail(String email);

  Future<UserEntity> createUserByAdmin({
    required String email,
    required String password,
    required String name,
    required String role,
    required UserPermissions permissions,
  });
}
