import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/leads_entity.dart';

final leadsRepositoryFirestoreProvider = Provider<LeadsRepositoryFirestore>(
  (ref) => LeadsRepositoryFirestore(),
);

class LeadsRepositoryFirestore {
  LeadsRepositoryFirestore({
    fs.FirebaseFirestore? firestore,
    this.collectionPath = 'leads',
  }) : _db = firestore ?? fs.FirebaseFirestore.instance;

  final fs.FirebaseFirestore _db;
  final String collectionPath;

  fs.CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionPath);

  // Streams ---------------------------------------------------------------

  Stream<List<LeadEntity>> watchLeads({
    String? status,
    String? assignedTo,
    String? source,
    bool? isPublic,
    bool? contactedToday,
    String? currentUserId,
    String? userRole,
  }) {
    fs.Query<Map<String, dynamic>> q = _col;

    // Apply role-based filtering first
    if (currentUserId != null && userRole != null && assignedTo == null) {
      if (userRole.toLowerCase() == 'sales executive') {
        // Sales executives see only leads assigned to them
        q = q.where('assignedTo', isEqualTo: currentUserId);
      } else if (userRole.toLowerCase() == 'sales manager') {
        // Sales managers see leads they created
        q = q.where('createdBy', isEqualTo: currentUserId);
      }
      // Admin sees all (no filter)
    }

    // Additional filters
    if (status != null) q = q.where('status', isEqualTo: status);
    if (assignedTo != null) q = q.where('assignedTo', isEqualTo: assignedTo);
    if (source != null) q = q.where('source', isEqualTo: source);
    if (isPublic != null) q = q.where('isPublic', isEqualTo: isPublic);
    if (contactedToday != null) {
      q = q.where('contactedToday', isEqualTo: contactedToday);
    }

    q = q.orderBy('createdAt', descending: true);

    return q.snapshots().map(
      (s) => s.docs.map((d) => _fromDoc(d.id, d.data())).toList(),
    );
  }

  Stream<LeadEntity?> watchById(String id) {
    return _col.doc(id).snapshots().map((d) {
      if (!d.exists) return null;
      return _fromDoc(d.id, d.data()!);
    });
  }

  // CRUD ------------------------------------------------------------------

  Future<LeadEntity?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return _fromDoc(doc.id, doc.data()!);
  }

  Future<void> add(LeadEntity lead) async {
    final id = lead.id.isNotEmpty ? lead.id : _col.doc().id;
    final data = _toMap(lead)
      ..putIfAbsent('createdAt', () => fs.FieldValue.serverTimestamp())
      ..['updatedAt'] = fs.FieldValue.serverTimestamp();
    await _col.doc(id).set(data);
  }

  Future<void> update(LeadEntity lead) async {
    final data = _toMap(lead)..['updatedAt'] = fs.FieldValue.serverTimestamp();
    await _col.doc(lead.id).set(data, fs.SetOptions(merge: true));
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

  // Search by name (requires stored field `nameLower`)
  Stream<List<LeadEntity>> searchByName(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return watchLeads();
    return _col
        .where('nameLower', isGreaterThanOrEqualTo: q)
        .where('nameLower', isLessThan: '$q\uf8ff')
        .orderBy('nameLower')
        .snapshots()
        .map((s) => s.docs.map((d) => _fromDoc(d.id, d.data())).toList());
  }

  // Mapping ---------------------------------------------------------------

  LeadEntity _fromDoc(String id, Map<String, dynamic> m) {
    return LeadEntity(
      id: id,
      status: (m['status'] as String?) ?? '',
      source: m['source'] as String?,
      assignedTo: m['assignedTo'] as String?,
      assignedToName: m['assignedToName'] as String?,
      assignedBy: m['assignedBy'] as String?,
      assignedAt: _toDate(m['assignedAt']),
      tags:
          (m['tags'] as List<dynamic>?)?.whereType<String>().toList() ??
          const [],
      name: (m['name'] as String?) ?? '',
      position: m['position'] as String?,
      email: m['email'] as String?,
      website: m['website'] as String?,
      phone: m['phone'] as String?,
      leadValue: m['leadValue'] as String?,
      company: m['company'] as String?,
      address: m['address'] as String?,
      city: m['city'] as String?,
      state: m['state'] as String?,
      country: m['country'] as String?,
      zip: m['zip'] as String?,
      defaultLanguage: m['defaultLanguage'] as String?,
      description: m['description'] as String?,
      isPublic: (m['isPublic'] as bool?) ?? false,
      contactedToday: (m['contactedToday'] as bool?) ?? false,
      createdAt: _toDate(m['createdAt']) ?? DateTime.now(),
      createdBy: m['createdBy'] as String?,
    );
  }

  Map<String, dynamic> _toMap(LeadEntity l) {
    final map = <String, dynamic>{
      'id': l.id,
      'status': l.status,
      'source': l.source,
      'assignedTo': l.assignedTo,
      'assignedToName': l.assignedToName,
      'assignedBy': l.assignedBy,
      'assignedAt': l.assignedAt != null ? fs.Timestamp.fromDate(l.assignedAt!) : null,
      'tags': l.tags,
      'name': l.name,
      'nameLower': l.name.toLowerCase(),
      'position': l.position,
      'email': l.email,
      'website': l.website,
      'phone': l.phone,
      'leadValue': l.leadValue,
      'company': l.company,
      'address': l.address,
      'city': l.city,
      'state': l.state,
      'country': l.country,
      'zip': l.zip,
      'defaultLanguage': l.defaultLanguage,
      'description': l.description,
      'isPublic': l.isPublic,
      'contactedToday': l.contactedToday,
      'createdAt': fs.Timestamp.fromDate(l.createdAt),
      'createdBy': l.createdBy,
    };
    return _pruneNulls(map);
  }

  // Helpers ---------------------------------------------------------------

  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is fs.Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    try {
      final toDate = (v as dynamic).toDate?.call();
      if (toDate is DateTime) return toDate;
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _pruneNulls(Map<String, dynamic> m) {
    m.removeWhere((_, v) => v == null);
    return m;
  }
}
