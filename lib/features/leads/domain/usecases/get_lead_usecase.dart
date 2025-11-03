import 'package:mgt_app/features/leads/domain/entities/leads_entity.dart';
import 'package:mgt_app/features/leads/domain/repositories/lead_repository.dart';

class GetLeadUseCase {
  final LeadRepository repository;

  GetLeadUseCase(this.repository);

  Future<LeadEntity?> call(String id) {
    return repository.getLead(id);
  }
}
