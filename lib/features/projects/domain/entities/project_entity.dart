import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

@immutable
class ProjectEntity {
  final String id; // unique id
  final String name;
  final String clientName;
  final String leadId; // link to originating lead (optional)
  final String description;
  final String status; // e.g., "Ongoing", "Completed", "On Hold", etc.
  final DateTime startDate;
  final DateTime? endDate;
  final double? budget;
  final String? assignedTeam;
  final String? projectManager;
  final String? remarks;
  final String? createdBy;

  ProjectEntity({
    String? id,
    required this.name,
    required this.clientName,
    required this.leadId,
    required this.description,
    required this.status,
    required this.startDate,
    this.endDate,
    this.budget,
    this.assignedTeam,
    this.projectManager,
    this.remarks,
    this.createdBy,
  }) : id = id ?? const Uuid().v4();

  ProjectEntity copyWith({
    String? id,
    String? name,
    String? clientName,
    String? leadId,
    String? description,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    String? assignedTeam,
    String? projectManager,
    String? remarks,
    String? createdBy,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      leadId: leadId ?? this.leadId,
      description: description ?? this.description,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      assignedTeam: assignedTeam ?? this.assignedTeam,
      projectManager: projectManager ?? this.projectManager,
      remarks: remarks ?? this.remarks,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory ProjectEntity.fromJson(Map<String, dynamic> json) {
    return ProjectEntity(
      id: json['id'] as String?,
      name: json['name'] as String,
      clientName: json['clientName'] as String,
      leadId: json['leadId'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'Ongoing',
      startDate: _parseDate(json['startDate']) ?? DateTime.now(),
      endDate: _parseDate(json['endDate']),
      budget: (json['budget'] is num)
          ? (json['budget'] as num).toDouble()
          : null,
      assignedTeam: json['assignedTeam'] as String?,
      projectManager: json['projectManager'] as String?,
      remarks: json['remarks'] as String?,
      createdBy: json['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'clientName': clientName,
      'leadId': leadId,
      'description': description,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'budget': budget,
      'assignedTeam': assignedTeam,
      'projectManager': projectManager,
      'remarks': remarks,
      'createdBy': createdBy,
    };
  }

  bool get isCompleted => status.toLowerCase() == 'completed';

  @override
  String toString() => 'ProjectEntity($name, $status)';
}

// Keep domain free of Firestore types; parse common representations
DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  try {
    final toDate = (v as dynamic).toDate?.call();
    if (toDate is DateTime) return toDate;
  } catch (_) {}
  return null;
}
