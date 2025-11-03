import '../entities/dashboard_stats_entity.dart';

/// Domain contract for dashboard data sources.
abstract class DashboardRepository {
  /// Stream live summary counts for the dashboard.
  Stream<DashboardStatsEntity> watchStats();

  /// Stream recent activities.
  /// When tasksOnly is true, only task activities are included.
  Stream<List<Map<String, dynamic>>> watchRecentActivities({
    int limit = 10,
    bool tasksOnly = false,
  });
}
