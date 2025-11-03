import 'package:mgt_app/features/projects/domain/entities/project_entity.dart';
import 'package:mgt_app/features/projects/domain/repositories/project_repository.dart';

class GetProjectUseCase {
  final ProjectRepository repository;

  GetProjectUseCase(this.repository);

  Future<ProjectEntity?> call(String id) {
    return repository.getProject(id);
  }
}
