import '../../domain/repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository _authRepository;
  LogoutUseCase(this._authRepository);

  Future<void> call() {
    return _authRepository.logout();
  }
}
