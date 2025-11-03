// File: lib/features/notifications/domain/entities/notification_entity.dart

class NotificationEntity {
  final String id;
  final String to; // User ID
  final String message;
  final String type; // 'enquiry', 'task', 'project', 'quotation', etc.
  final String? link; // Deep link to relevant screen
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // Additional data

  NotificationEntity({
    required this.id,
    required this.to,
    required this.message,
    required this.type,
    this.link,
    this.isRead = false,
    required this.createdAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'to': to,
      'message': message,
      'type': type,
      'link': link,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'] as String,
      to: json['to'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      link: json['link'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  NotificationEntity copyWith({
    String? id,
    String? to,
    String? message,
    String? type,
    String? link,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      to: to ?? this.to,
      message: message ?? this.message,
      type: type ?? this.type,
      link: link ?? this.link,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper to mark as read
  NotificationEntity markAsRead() {
    return copyWith(isRead: true);
  }

  // Helper to get icon based on type
  String getIcon() {
    switch (type.toLowerCase()) {
      case 'enquiry':
        return '📧';
      case 'task':
        return '✅';
      case 'project':
        return '📁';
      case 'quotation':
        return '📄';
      case 'invoice':
        return '💰';
      case 'delivery':
        return '🚚';
      case 'production':
        return '🏭';
      case 'user':
        return '👤';
      case 'system':
        return '⚙️';
      default:
        return '🔔';
    }
  }

  // Helper to get priority (for sorting)
  int getPriority() {
    switch (type.toLowerCase()) {
      case 'urgent':
      case 'error':
        return 3;
      case 'task':
      case 'quotation':
        return 2;
      case 'enquiry':
      case 'project':
        return 1;
      default:
        return 0;
    }
  }
}

// Notification Types Enum (optional, for type safety)
enum NotificationType {
  enquiry,
  task,
  project,
  quotation,
  invoice,
  delivery,
  production,
  marketing,
  user,
  system,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.enquiry:
        return 'enquiry';
      case NotificationType.task:
        return 'task';
      case NotificationType.project:
        return 'project';
      case NotificationType.quotation:
        return 'quotation';
      case NotificationType.invoice:
        return 'invoice';
      case NotificationType.delivery:
        return 'delivery';
      case NotificationType.production:
        return 'production';
      case NotificationType.marketing:
        return 'marketing';
      case NotificationType.user:
        return 'user';
      case NotificationType.system:
        return 'system';
    }
  }

  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'enquiry':
        return NotificationType.enquiry;
      case 'task':
        return NotificationType.task;
      case 'project':
        return NotificationType.project;
      case 'quotation':
        return NotificationType.quotation;
      case 'invoice':
        return NotificationType.invoice;
      case 'delivery':
        return NotificationType.delivery;
      case 'production':
        return NotificationType.production;
      case 'marketing':
        return NotificationType.marketing;
      case 'user':
        return NotificationType.user;
      default:
        return NotificationType.system;
    }
  }
}
