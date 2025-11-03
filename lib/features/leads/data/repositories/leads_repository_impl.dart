import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:mgt_app/features/leads/domain/entities/leads_entity.dart';
import 'package:mgt_app/features/leads/domain/repositories/lead_repository.dart';

class LeadsRepositoryImpl implements LeadRepository {
  final fs.CollectionReference _leadsCollection =
      fs.FirebaseFirestore.instance.collection('leads');

  @override
  Stream<List<LeadEntity>> watchLeads({
    String? status,
    String? assignedTo,
    String? source,
    bool? isPublic,
    bool? contactedToday,
  }) {
    fs.Query<Map<String, dynamic>> q = _leadsCollection as fs.Query<Map<String, dynamic>>;

    if (status != null) q = q.where('status', isEqualTo: status);
    if (assignedTo != null) q = q.where('assignedTo', isEqualTo: assignedTo);
    if (source != null) q = q.where('source', isEqualTo: source);
    if (isPublic != null) q = q.where('isPublic', isEqualTo: isPublic);
    if (contactedToday != null) {
      q = q.where('contactedToday', isEqualTo: contactedToday);
    }

    q = q.orderBy('createdAt', descending: true);

    return q.snapshots().map(
      (s) => s.docs.map((d) => LeadEntity.fromJson(d.data())).toList(),
    );
  }

  @override
  Stream<LeadEntity?> watchById(String id) {
    return _leadsCollection.doc(id).snapshots().map((d) {
      if (!d.exists) return null;
      return LeadEntity.fromJson(d.data() as Map<String, dynamic>);
    });
  }

  @override
  Future<LeadEntity?> getLead(String id) async {
    final doc = await _leadsCollection.doc(id).get();
    if (!doc.exists) return null;
    return LeadEntity.fromJson(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<void> addLead(LeadEntity lead) async {
    if (lead.id.isEmpty) {
      final docRef = _leadsCollection.doc();
      await docRef.set(lead.toJson()..['id'] = docRef.id);
    } else {
      await _leadsCollection.doc(lead.id).set(lead.toJson());
    }
  }

  @override
  Future<void> updateLead(LeadEntity lead) async {
    await _leadsCollection.doc(lead.id).update(lead.toJson());
  }

  @override
  Future<void> patch(String id, Map<String, dynamic> patch) async {
    await _leadsCollection.doc(id).update(patch);
  }

  @override
  Future<void> removeLead(String id) async {
    await _leadsCollection.doc(id).delete();
  }

  @override
  Stream<List<LeadEntity>> searchByName(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return watchLeads();
    return _leadsCollection
        .where('nameLower', isGreaterThanOrEqualTo: q)
        .where('nameLower', isLessThan: '$q\uf8ff')
        .orderBy('nameLower')
        .snapshots()
        .map((s) => s.docs.map((d) => LeadEntity.fromJson(d.data() as Map<String, dynamic>)).toList());
  }
}