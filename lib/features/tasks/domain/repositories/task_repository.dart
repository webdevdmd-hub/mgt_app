import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<List<TaskEntity>> fetchTasks();

  Future<TaskEntity?> getTaskById(String id);

  Future<void> addTask(TaskEntity task);

  Future<void> updateTask(TaskEntity task);

  Future<void> deleteTask(String id);
}