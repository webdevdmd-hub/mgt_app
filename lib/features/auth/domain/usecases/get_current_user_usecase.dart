import '../entities/user_entity.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository _authRepository;

  GetCurrentUserUseCase(this._authRepository);

  Future<UserEntity?> call() async {
    return await _authRepository.getCurrentUser();
  }
}