import '../entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  Future<UserEntity> call({
    required String email,
    required String password,
  }) async {
    return await _authRepository.login(email: email, password: password);
  }
}
