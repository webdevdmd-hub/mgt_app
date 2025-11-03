import 'package:mgt_app/features/auth/domain/entities/user_entity.dart';
import 'package:mgt_app/features/auth/domain/repositories/auth_repository.dart';

class GetUsersUseCase {
  final AuthRepository repository;

  GetUsersUseCase(this.repository);

  Future<List<UserEntity>> call() {
    return repository.getUsers();
  }
}
