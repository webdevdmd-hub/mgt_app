import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/data/models/dashboard_stats_model.dart';
import '../../../dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../../dashboard/domain/entities/dashboard_stats_entity.dart';

// Repository provider (data source)
final dashboardRepositoryProvider = Provider<DashboardRepositoryImpl>(
  (ref) => DashboardRepositoryImpl(),
);

// Live dashboard summary stats as domain entity
final dashboardStatsProvider = StreamProvider.autoDispose<DashboardStatsEntity>(
  (ref) {
    final repo = ref.watch(dashboardRepositoryProvider);
    return repo.watchStats().map((DashboardStats m) {
      return DashboardStatsEntity(
        leads: m.leads,
        projects: m.projects,
        tasks: m.tasks,
        updatedAt: m.updatedAt,
      );
    });
  },
);

// Recent activities (leads + projects + tasks) or tasks-only
final recentActivitiesProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, bool>((ref, tasksOnly) {
      final repo = ref.watch(dashboardRepositoryProvider);
      return repo.watchRecentActivities(limit: 5, tasksOnly: tasksOnly);
    });

// Convenience: recent tasks only
final recentTasksOnlyProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final repo = ref.watch(dashboardRepositoryProvider);
      return repo.watchRecentActivities(limit: 5, tasksOnly: true);
    });
