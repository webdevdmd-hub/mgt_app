import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/leads_entity.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../data/repositories/leads_repository_impl.dart';
import '../../domain/usecases/get_lead_usecase.dart';

final leadRepositoryProvider = Provider<LeadRepository>((ref) {
  return LeadsRepositoryImpl();
});

final getLeadUseCaseProvider = Provider<GetLeadUseCase>((ref) {
  final repository = ref.watch(leadRepositoryProvider);
  return GetLeadUseCase(repository);
});

final getLeadProvider = FutureProvider.family<LeadEntity?, String>((ref, id) {
  final getLead = ref.watch(getLeadUseCaseProvider);
  return getLead(id);
});

final leadsProvider = StateNotifierProvider<LeadsNotifier, List<LeadEntity>>((ref) {
  return LeadsNotifier(ref.read(leadRepositoryProvider));
});

class LeadsNotifier extends StateNotifier<List<LeadEntity>> {
  final LeadRepository _repository;
  StreamSubscription? _leadsSubscription;

  LeadsNotifier(this._repository) : super([]) {
    fetchLeads();
  }

  Future<void> fetchLeads() async {
    _leadsSubscription?.cancel();
    _repository.watchLeads().listen((leads) {
      state = leads;
    });
  }

  Future<void> addLeadAsync(LeadEntity lead) async {
    await _repository.addLead(lead);
  }

  Future<void> updateLeadAsync(LeadEntity lead) async {
    await _repository.updateLead(lead);
  }

  Future<void> removeLeadAsync(String id) async {
    await _repository.removeLead(id);
  }

  @override
  void dispose() {
    _leadsSubscription?.cancel();
    super.dispose();
  }
}
