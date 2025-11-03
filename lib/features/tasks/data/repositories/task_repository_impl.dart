import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  // In-memory storage example
  final List<TaskEntity> _tasks = [];

  @override
  Future<List<TaskEntity>> fetchTasks() async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_tasks);
  }

  @override
  Future<TaskEntity?> getTaskById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addTask(TaskEntity task) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _tasks.add(task);
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _tasks.removeWhere((t) => t.id == id);
  }
}
