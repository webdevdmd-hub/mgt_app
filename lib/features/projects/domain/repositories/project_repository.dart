import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/project_entity.dart';

abstract class ProjectRepository {
  Stream<List<ProjectEntity>> watchProjects({String? status, String? leadId});
  Future<ProjectEntity?> getProject(String id);
  Future<void> addProject(ProjectEntity project);
  Future<void> updateProject(ProjectEntity project);
  Future<void> patch(String id, Map<String, dynamic> patch);
  Future<void> removeProject(String id);
  Stream<List<ProjectEntity>> searchByName(String query);
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  throw UnimplementedError('ProjectRepository provider not implemented');
});
