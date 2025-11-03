import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Immutable model for dashboard summary counts.
@immutable
class DashboardStats {
  final int leads;
  final int projects;
  final int tasks;
  final DateTime updatedAt;

  const DashboardStats({
    required this.leads,
    required this.projects,
    required this.tasks,
    required this.updatedAt,
  });

  factory DashboardStats.empty() => DashboardStats(
    leads: 0,
    projects: 0,
    tasks: 0,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  DashboardStats copyWith({
    int? leads,
    int? projects,
    int? tasks,
    DateTime? updatedAt,
  }) {
    return DashboardStats(
      leads: leads ?? this.leads,
      projects: projects ?? this.projects,
      tasks: tasks ?? this.tasks,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'leads': leads,
      'projects': projects,
      'tasks': tasks,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      leads: _toInt(map['leads']),
      projects: _toInt(map['projects']),
      tasks: _toInt(map['tasks']),
      updatedAt: _toDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  String toJson() => toMap().toString();

  @override
  String toString() =>
      'DashboardStats(leads: $leads, projects: $projects, tasks: $tasks, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardStats &&
        other.leads == leads &&
        other.projects == projects &&
        other.tasks == tasks &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      leads.hashCode ^ projects.hashCode ^ tasks.hashCode ^ updatedAt.hashCode;

  // Helpers
  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is int) {
      // supports millis epoch
      return DateTime.fromMillisecondsSinceEpoch(v);
    }
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
