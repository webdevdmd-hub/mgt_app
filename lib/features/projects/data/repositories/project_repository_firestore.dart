import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project_entity.dart';

final projectRepositoryFirestoreProvider = Provider<ProjectRepositoryFirestore>(
  (ref) => ProjectRepositoryFirestore(),
);

class ProjectRepositoryFirestore {
  ProjectRepositoryFirestore({
    fs.FirebaseFirestore? firestore,
    this.collectionPath = 'projects',
  }) : _db = firestore ?? fs.FirebaseFirestore.instance;

  final fs.FirebaseFirestore _db;
  final String collectionPath;

  fs.CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionPath);

  Stream<List<ProjectEntity>> watchProjects({String? status, String? leadId}) {
    fs.Query<Map<String, dynamic>> q = _col;
    if (status != null) q = q.where('status', isEqualTo: status);
    if (leadId != null) q = q.where('leadId', isEqualTo: leadId);
    q = q.orderBy('startDate', descending: true);

    return q.snapshots().map(
      (s) => s.docs.map((d) => _fromDoc(d.id, d.data())).toList(),
    );
  }

  Stream<ProjectEntity?> watchById(String id) {
    return _col.doc(id).snapshots().map((d) {
      if (!d.exists) return null;
      return _fromDoc(d.id, d.data()!);
    });
  }

  Future<ProjectEntity?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return _fromDoc(doc.id, doc.data()!);
  }

  Future<void> add(ProjectEntity project) async {
    final id = project.id.isNotEmpty ? project.id : _col.doc().id;
    final data = _toMap(project)
      ..putIfAbsent('createdAt', () => fs.FieldValue.serverTimestamp())
      ..['updatedAt'] = fs.FieldValue.serverTimestamp();
    await _col.doc(id).set(data);
  }

  Future<void> update(ProjectEntity project) async {
    final data = _toMap(project)
      ..['updatedAt'] = fs.FieldValue.serverTimestamp();
    await _col.doc(project.id).set(data, fs.SetOptions(merge: true));
  }

  Future<void> patch(String id, Map<String, dynamic> patch) async {
    await _col.doc(id).set({
      ..._pruneNulls(patch),
      'updatedAt': fs.FieldValue.serverTimestamp(),
    }, fs.SetOptions(merge: true));
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Stream<List<ProjectEntity>> searchByName(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return watchProjects();
    return _col
        .where('nameLower', isGreaterThanOrEqualTo: q)
        .where('nameLower', isLessThan: '$q\uf8ff')
        .orderBy('nameLower')
        .snapshots()
        .map((s) => s.docs.map((d) => _fromDoc(d.id, d.data())).toList());
  }

  ProjectEntity _fromDoc(String id, Map<String, dynamic> m) {
    return ProjectEntity(
      id: id,
      name: m['name'] as String? ?? '',
      clientName: m['clientName'] as String? ?? '',
      leadId: m['leadId'] as String? ?? '',
      description: m['description'] as String? ?? '',
      status: m['status'] as String? ?? 'Ongoing',
      startDate: _toDate(m['startDate']) ?? DateTime.now(),
      endDate: _toDate(m['endDate']),
      budget: _toDouble(m['budget']),
      assignedTeam: m['assignedTeam'] as String?,
      projectManager: m['projectManager'] as String?,
      remarks: m['remarks'] as String?,
    );
  }

  Map<String, dynamic> _toMap(ProjectEntity p) {
    final map = <String, dynamic>{
      'id': p.id,
      'name': p.name,
      'nameLower': p.name.toLowerCase(),
      'clientName': p.clientName,
      'leadId': p.leadId,
      'description': p.description,
      'status': p.status,
      'startDate': p.startDate,
      'endDate': p.endDate,
      'budget': p.budget,
      'assignedTeam': p.assignedTeam,
      'projectManager': p.projectManager,
      'remarks': p.remarks,
    };
    return _pruneNulls(map);
  }

  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is fs.Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Map<String, dynamic> _pruneNulls(Map<String, dynamic> m) {
    m.removeWhere((_, v) => v == null);
    return m;
  }
}
