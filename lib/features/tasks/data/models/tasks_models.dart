import 'package:flutter/foundation.dart';

enum TaskPriority { high, medium, low }

enum TaskStatus { pending, inProgress, completed , }

@immutable
class SubTask {
  final String id;
  final String title;
  final bool isDone;

  const SubTask({required this.id, required this.title, this.isDone = false});

  SubTask copyWith({String? id, String? title, bool? isDone}) => SubTask(
    id: id ?? this.id,
    title: title ?? this.title,
    isDone: isDone ?? this.isDone,
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'isDone': isDone};

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
    id: json['id'] as String,
    title: json['title'] as String,
    isDone: json['isDone'] as bool? ?? false,
  );
}

@immutable
class Task {
  final String id;
  final String title;
  final String? description;
  final String? linkedId; // projectId or enquiryId
  final String? linkedType; // 'project' | 'enquiry' | null
  final String? assignee;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final List<String> tags;

  final DateTime createdAt;

  final List<SubTask> subtasks;
  final int timeSpentSec; // tracked time in seconds

  Task({
    required this.id,
    required this.title,
    this.description,
    this.linkedId,
    this.linkedType,
    this.assignee,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.tags = const [],
    DateTime? createdAt,

    this.subtasks = const [],
    this.timeSpentSec = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? linkedId,
    String? linkedType,
    String? assignee,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    List<String>? tags,
    DateTime? createdAt,

    List<SubTask>? subtasks,
    int? timeSpentSec,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      linkedId: linkedId ?? this.linkedId,
      linkedType: linkedType ?? this.linkedType,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,

      subtasks: subtasks ?? this.subtasks,
      timeSpentSec: timeSpentSec ?? this.timeSpentSec,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'linkedId': linkedId,
      'linkedType': linkedType,
      'assignee': assignee,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.index,
      'status': status.index,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),

      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'timeSpentSec': timeSpentSec,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      linkedId: json['linkedId'] as String?,
      linkedType: json['linkedType'] as String?,
      assignee: json['assignee'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      priority: TaskPriority.values[(json['priority'] ?? 1) as int],
      status: TaskStatus.values[(json['status'] ?? 0) as int],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt:
          DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now(),

      subtasks:
          (json['subtasks'] as List<dynamic>?)
              ?.map((e) => SubTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      timeSpentSec: json['timeSpentSec'] as int? ?? 0,
    );
  }
}
