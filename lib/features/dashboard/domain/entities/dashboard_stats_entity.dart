class DashboardStatsEntity {
  final int leads;
  final int projects;
  final int tasks;
  final DateTime updatedAt;

  const DashboardStatsEntity({
    required this.leads,
    required this.projects,
    required this.tasks,
    required this.updatedAt,
  });

  factory DashboardStatsEntity.empty() => DashboardStatsEntity(
    leads: 0,
    projects: 0,
    tasks: 0,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  DashboardStatsEntity copyWith({
    int? leads,
    int? projects,
    int? tasks,
    DateTime? updatedAt,
  }) {
    return DashboardStatsEntity(
      leads: leads ?? this.leads,
      projects: projects ?? this.projects,
      tasks: tasks ?? this.tasks,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'DashboardStatsEntity(leads: $leads, projects: $projects, tasks: $tasks, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardStatsEntity &&
        other.leads == leads &&
        other.projects == projects &&
        other.tasks == tasks &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      leads.hashCode ^ projects.hashCode ^ tasks.hashCode ^ updatedAt.hashCode;
}
