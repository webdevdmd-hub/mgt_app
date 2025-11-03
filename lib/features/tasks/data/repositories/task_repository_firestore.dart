import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import '../../domain/entities/task_entity.dart';

class TasksRepositoryFirestore {
  final fs.FirebaseFirestore _db;
  final String collectionPath;

  TasksRepositoryFirestore({
    fs.FirebaseFirestore? firestore,
    this.collectionPath = 'tasks',
  }) : _db = firestore ?? fs.FirebaseFirestore.instance;

  fs.CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionPath);

  // STREAM all tasks (optionally scope by projectId)
  Stream<List<TaskEntity>> watchTasks({String? projectId}) {
    fs.Query<Map<String, dynamic>> q = _col;
    if (projectId != null) {
      q = q.where('projectId', isEqualTo: projectId);
    }
    return q
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => _taskFromDoc(d.id, d.data())).toList());
  }

  // Helpers
  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is fs.Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  List<String> _stringList(dynamic v) {
    if (v is List) {
      return v.whereType<String>().toList();
    }
    return const [];
  }

  Map<String, dynamic> _pruneNulls(Map<String, dynamic> m) {
    m.removeWhere((_, v) => v == null);
    return m;
  }

  // ===== Mapping (now includes all TaskEntity fields) =====
  TaskEntity _taskFromDoc(String id, Map<String, dynamic> m) {
    return TaskEntity(
      id: id,
      title: (m['title'] as String?) ?? '',
      description: m['description'] as String?,
      parentId: m['parentId'] as String?,
      linkedId: m['linkedId'] as String?,
      linkedType: m['linkedType'] as String?,
      assigneeId: m['assigneeId'] as String?,
      assigneeName: m['assigneeName'] as String?,
      department: (m['department'] as String?) ?? 'general',
      dueDate: _toDate(m['dueDate']),
      createdAt: _toDate(m['createdAt']) ?? DateTime.now(),

      priority: TaskPriority
          .values[(m['priority'] as int?) ?? TaskPriority.medium.index],
      status:
          TaskStatus.values[(m['status'] as int?) ?? TaskStatus.pending.index],
      tags: _stringList(m['tags']),
      timeSpentSec: (m['timeSpentSec'] as num?)?.toInt() ?? 0,
      attachments: _stringList(m['attachments']),
      createdBy: m['createdBy'] as String?,
      notes: m['notes'] as String?,
    );
  }

  Map<String, dynamic> _toMap(TaskEntity t) {
    final map = <String, dynamic>{
      'title': t.title,
      'description': t.description,
      'parentId': t.parentId,
      'linkedId': t.linkedId,
      'linkedType': t.linkedType,
      'assigneeId': t.assigneeId,
      'assigneeName': t.assigneeName,
      'department': t.department,
      'dueDate': t.dueDate != null ? fs.Timestamp.fromDate(t.dueDate!) : null,
      'createdAt': fs.Timestamp.fromDate(t.createdAt),

      'priority': t.priority.index,
      'status': t.status.index,
      'tags': t.tags,
      'timeSpentSec': t.timeSpentSec,
      'attachments': t.attachments,
      'createdBy': t.createdBy,
      'notes': t.notes,
    };
    return _pruneNulls(map);
  }

  // Write ops keep your existing behavior, but ensure timestamps are set
  Future<void> addTask(TaskEntity t) async {
    final data = _toMap(t)
      ..putIfAbsent('createdAt', () => fs.FieldValue.serverTimestamp())
      ..['updatedAt'] = fs.FieldValue.serverTimestamp();
    final id = (t.id.isNotEmpty) ? t.id : _col.doc().id;
    await _col.doc(id).set(data);
  }

  Future<void> updateTask(String id, TaskEntity updated) async {
    final data = _toMap(updated)
      ..['updatedAt'] = fs.FieldValue.serverTimestamp();
    await _col.doc(id).set(data, fs.SetOptions(merge: true));
  }

  Future<void> patch(String id, Map<String, dynamic> patch) async {
    await _col
        .doc(id)
        .set(
          _pruneNulls({...patch, 'updatedAt': fs.FieldValue.serverTimestamp()}),
          fs.SetOptions(merge: true),
        );
  }

  Future<void> deleteTask(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> incrementTimeSpent(String id, int seconds) async {
    await _col.doc(id).update({
      'timeSpentSec': fs.FieldValue.increment(seconds),
      'updatedAt': fs.FieldValue.serverTimestamp(),
    });
  }
}
