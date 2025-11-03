import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/repositories/project_repository.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/usecases/get_project_usecase.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepositoryImpl();
});

final projectsProvider = StateNotifierProvider<ProjectsNotifier, List<ProjectEntity>>((ref) {
  return ProjectsNotifier(ref.read(projectRepositoryProvider));
});

final getProjectUseCaseProvider = Provider<GetProjectUseCase>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return GetProjectUseCase(repository);
});

final getProjectProvider = FutureProvider.family<ProjectEntity?, String>((ref, id) {
  final getProject = ref.watch(getProjectUseCaseProvider);
  return getProject(id);
});

class ProjectsNotifier extends StateNotifier<List<ProjectEntity>> {
  final ProjectRepository _repository;
  StreamSubscription? _projectsSubscription;

  ProjectsNotifier(this._repository) : super([]) {
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    _projectsSubscription?.cancel();
    _repository.watchProjects().listen((projects) {
      state = projects;
    });
  }

  Future<void> addProjectAsync(ProjectEntity project) async {
    await _repository.addProject(project);
  }

  Future<void> updateProjectAsync(ProjectEntity project) async {
    await _repository.updateProject(project);
  }

  Future<void> removeProjectAsync(String id) async {
    await _repository.removeProject(id);
  }

  @override
  void dispose() {
    _projectsSubscription?.cancel();
    super.dispose();
  }
}
