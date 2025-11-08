import 'package:flutter/foundation.dart';

// Task Priority Enum
enum TaskPriority { high, medium, low }

// Task Status Enum
enum TaskStatus { pending, inProgress, completed }

// Extension for TaskPriority
extension TaskPriorityExtension on TaskPriority {
  String get displayName {
    switch (this) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  int get color {
    switch (this) {
      case TaskPriority.high:
        return 0xFFEF4444; // Red
      case TaskPriority.medium:
        return 0xFFF59E0B; // Orange
      case TaskPriority.low:
        return 0xFF10B981; // Green
    }
  }
}

// Extension for TaskStatus
extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  int get color {
    switch (this) {
      case TaskStatus.pending:
        return 0xFFF59E0B; // Orange
      case TaskStatus.inProgress:
        return 0xFF3B82F6; // Blue
      case TaskStatus.completed:
        return 0xFF10B981; // Green
    }
  }
}

// Main Task Entity
@immutable
class TaskEntity {
  final String id;
  final String title;
  final String? description;

  // Linking to Project/Enquiry
  final String? linkedId; // projectId or enquiryId
  final String? parentId; // For subtasks
  final String? linkedType; // 'project' | 'enquiry' | null

  // Assignment
  final String? assignedTo; // User ID who this task is assigned to
  final String? assignedToName; // User Name (for display)
  final String? assignedBy; // User ID who assigned this task
  final DateTime? assignedAt; // When the task was assigned
  final String department; // Which department owns this task

  // Dates
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;

  // Status & Priority
  final TaskPriority priority;
  final TaskStatus status;

  // Additional Info
  final List<String> tags;
  final int timeSpentSec; // Tracked time in seconds
  final List<String> attachments; // File URLs/paths
  final String? createdBy; // User who created the task

  // Comments/Notes
  final String? notes;

  const TaskEntity({
    required this.id,
    required this.title,
    this.description,
    this.linkedId,
    this.parentId,
    this.linkedType,
    this.assignedTo,
    this.assignedToName,
    this.assignedBy,
    this.assignedAt,
    this.department = 'general',
    this.dueDate,
    required this.createdAt,
    this.completedAt,

    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.tags = const [],
    this.timeSpentSec = 0,
    this.attachments = const [],
    this.createdBy,
    this.notes,
  });

  TaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? linkedId,
    String? parentId,
    String? linkedType,
    String? assignedTo,
    String? assignedToName,
    String? assignedBy,
    DateTime? assignedAt,
    String? department,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? completedAt,

    TaskPriority? priority,
    TaskStatus? status,
    List<String>? tags,
    int? timeSpentSec,
    List<String>? attachments,
    String? createdBy,
    String? notes,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      linkedId: linkedId,
      parentId: parentId,
      linkedType: linkedType,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
      department: department ?? this.department,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,

      priority: priority ?? this.priority,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      timeSpentSec: timeSpentSec ?? this.timeSpentSec,
      attachments: attachments ?? this.attachments,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'linkedId': linkedId,
      'parentId': parentId,
      'linkedType': linkedType,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedBy': assignedBy,
      'assignedAt': assignedAt?.toIso8601String(),
      'department': department,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'priority': priority.index,
      'status': status.index,
      'tags': tags,
      'timeSpentSec': timeSpentSec,
      'attachments': attachments,
      'createdBy': createdBy,
      'notes': notes,
    };
  }

  factory TaskEntity.fromJson(Map<String, dynamic> json) {
    return TaskEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      parentId: json['parentId'] as String?,
      linkedId: json['linkedId'] as String?,
      linkedType: json['linkedType'] as String?,
      assignedTo: json['assignedTo'] as String?,
      assignedToName: json['assignedToName'] as String?,
      assignedBy: json['assignedBy'] as String?,
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'] as String)
          : null,
      department: json['department'] as String? ?? 'general',
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      priority: TaskPriority.values[(json['priority'] ?? 1) as int],
      status: TaskStatus.values[(json['status'] ?? 0) as int],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      timeSpentSec: json['timeSpentSec'] as int? ?? 0,
      attachments:
          (json['attachments'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdBy: json['createdBy'] as String?,
      notes: json['notes'] as String?,
    );
  }

  // Helper Methods

  // Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // Get formatted time spent
  String get formattedTimeSpent {
    if (timeSpentSec == 0) return '0m';

    final hours = timeSpentSec ~/ 3600;
    final minutes = (timeSpentSec % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // Check if task can be started (for permission checking)
  bool canBeStarted(String userId) {
    return assignedTo == userId && status == TaskStatus.pending;
  }

  // Check if task can be completed
  bool canBeCompleted(String userId) {
    return assignedTo == userId && status == TaskStatus.inProgress;
  }

  // Get days until due
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    return dueDate!.difference(now).inDays;
  }

  // Get status color
  int get statusColor => status.color;

  // Get priority color
  int get priorityColor => priority.color;
}
