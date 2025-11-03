import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task_entity.dart';
import '../../data/repositories/task_repository_firestore.dart';

// Provide the Firestore repository
final tasksRepositoryProvider = Provider<TasksRepositoryFirestore>(
  (ref) => TasksRepositoryFirestore(),
);

class TasksNotifier extends StateNotifier<List<TaskEntity>> {
  TasksNotifier(this._repo) : super(const []) {
    // Start listening to Firestore
    _sub = _repo.watchTasks().listen((tasks) {
      state = tasks;
    });
  }

  final TasksRepositoryFirestore _repo;
  late final StreamSubscription<List<TaskEntity>> _sub;

  // local tickers for smooth UI every second
  final Map<String, Timer> _tickers = {};
  // when a timer is running, we store start time to persist only on pause/reset
  final Map<String, DateTime> _runningSince = {};

  // CRUD
  Future<void> addTask(TaskEntity t) async {
    // optimistic update
    state = [...state, t];
    await _repo.addTask(t);
  }

  Future<void> updateTask(String id, TaskEntity updated) async {
    state = [
      for (final t in state)
        if (t.id == id) updated else t,
    ];
    await _repo.updateTask(id, updated);
  }

  Future<void> removeTask(String id) async {
    pauseTimer(id); // ensure timer stopped before delete
    state = [
      for (final t in state)
        if (t.id != id) t,
    ];
    await _repo.deleteTask(id);
  }

  Future<void> fetchTasks() async {
    // No-op; using stream in constructor
    return;
  }

  TaskEntity? getById(String id) {
    try {
      return state.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // Timer API (UI smooth locally, persist on pause/reset)
  bool isTimerRunning(String taskId) => _tickers.containsKey(taskId);

  void startTimer(String taskId) {
    if (_tickers.containsKey(taskId)) return;
    _runningSince.putIfAbsent(taskId, () => DateTime.now());

    _tickers[taskId] = Timer.periodic(const Duration(seconds: 1), (_) {
      final t = getById(taskId);
      if (t == null) return;
      // local increment for smooth UI
      state = [
        for (final x in state)
          if (x.id == taskId)
            x.copyWith(timeSpentSec: x.timeSpentSec + 1)
          else
            x,
      ];
    });
  }

  Future<void> pauseTimer(String taskId) async {
    _tickers[taskId]?.cancel();
    _tickers.remove(taskId);

    final started = _runningSince.remove(taskId);
    if (started != null) {
      final elapsed = DateTime.now().difference(started).inSeconds;
      if (elapsed > 0) {
        // persist only the delta to Firestore
        await _repo.incrementTimeSpent(taskId, elapsed);
      }
    }
  }

  Future<void> resetTimer(String taskId) async {
    await pauseTimer(taskId);
    final t = getById(taskId);
    if (t == null) return;
    // optimistic local reset
    state = [
      for (final x in state)
        if (x.id == taskId) x.copyWith(timeSpentSec: 0) else x,
    ];
    // persist reset
    await _repo.patch(taskId, {'timeSpentSec': 0});
  }

  @override
  void dispose() {
    for (final t in _tickers.values) {
      t.cancel();
    }
    _tickers.clear();
    _sub.cancel();
    super.dispose();
  }
}

// Provider using the Firestore-backed notifier
final tasksProvider = StateNotifierProvider<TasksNotifier, List<TaskEntity>>(
  (ref) => TasksNotifier(ref.read(tasksRepositoryProvider)),
);

final subtasksProvider = Provider.family<List<TaskEntity>, String>((
  ref,
  parentId,
) {
  final allTasks = ref.watch(tasksProvider);
  // Also sort subtasks by creation date
  return allTasks.where((task) => task.parentId == parentId).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
});
