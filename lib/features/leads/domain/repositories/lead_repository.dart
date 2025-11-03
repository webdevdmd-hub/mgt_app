import '../entities/leads_entity.dart';

abstract class LeadRepository {
  Stream<List<LeadEntity>> watchLeads({
    String? status,
    String? assignedTo,
    String? source,
    bool? isPublic,
    bool? contactedToday,
  });
  Stream<LeadEntity?> watchById(String id);
  Future<LeadEntity?> getLead(String id);
  Future<void> addLead(LeadEntity lead);
  Future<void> updateLead(LeadEntity lead);
  Future<void> patch(String id, Map<String, dynamic> patch);
  Future<void> removeLead(String id);
  Stream<List<LeadEntity>> searchByName(String query);
}