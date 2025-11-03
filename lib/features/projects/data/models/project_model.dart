import 'package:uuid/uuid.dart';

/// Each project is usually created from an approved lead.
class Project {
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

  Project({
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
  }) : id = id ?? const Uuid().v4();

  // ---------- Copy ----------
  Project copyWith({
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
  }) {
    return Project(
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
    );
  }

  // ---------- JSON Serialization ----------
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      clientName: json['clientName'] as String,
      leadId: json['leadId'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'Ongoing',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'] as String) : null,
      budget: (json['budget'] is num) ? (json['budget'] as num).toDouble() : null,
      assignedTeam: json['assignedTeam'] as String?,
      projectManager: json['projectManager'] as String?,
      remarks: json['remarks'] as String?,
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
    };
  }

  // ---------- Utilities ----------
  bool get isCompleted => status.toLowerCase() == 'completed';

  @override
  String toString() => 'Project($name, $status)';
}
