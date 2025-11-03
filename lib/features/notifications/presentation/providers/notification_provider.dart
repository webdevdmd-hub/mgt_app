import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_entity.dart';

// Notifications State
class NotificationsState {
  final List<NotificationEntity> notifications;
  final bool isLoading;
  final String? error;

  NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationEntity>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifications Provider
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(NotificationsState()) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate API call - Replace with actual API
      await Future.delayed(const Duration(seconds: 1));

      final mockNotifications = _getMockNotifications();

      state = state.copyWith(
        notifications: mockNotifications,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final updatedNotifications = state.notifications.map((notification) {
      if (notification.id == notificationId) {
        return NotificationEntity(
          id: notification.id,
          to: notification.to,
          message: notification.message,
          type: notification.type,
          link: notification.link,
          isRead: true,
          createdAt: notification.createdAt,
        );
      }
      return notification;
    }).toList();

    state = state.copyWith(notifications: updatedNotifications);
  }

  Future<void> markAllAsRead() async {
    final updatedNotifications = state.notifications.map((notification) {
      return NotificationEntity(
        id: notification.id,
        to: notification.to,
        message: notification.message,
        type: notification.type,
        link: notification.link,
        isRead: true,
        createdAt: notification.createdAt,
      );
    }).toList();

    state = state.copyWith(notifications: updatedNotifications);
  }

  Future<void> deleteNotification(String notificationId) async {
    final updatedNotifications = state.notifications
        .where((notification) => notification.id != notificationId)
        .toList();

    state = state.copyWith(notifications: updatedNotifications);
  }

  List<NotificationEntity> _getMockNotifications() {
    return [
      NotificationEntity(
        id: 'n1',
        to: 'user_1',
        message: 'New enquiry received from Al Barsha Office Project',
        type: 'enquiry',
        link: '/enquiries/1',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationEntity(
        id: 'n2',
        to: 'user_1',
        message: 'Quotation approved for Marina Mall Project',
        type: 'quotation',
        link: '/projects/2',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      NotificationEntity(
        id: 'n3',
        to: 'user_1',
        message: 'Production completed for JBR Residence',
        type: 'production',
        link: '/projects/3',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      NotificationEntity(
        id: 'n4',
        to: 'user_1',
        message: 'Task assigned: Prepare material list',
        type: 'task',
        link: '/tasks/4',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}

// Unread Notifications Count Provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).notifications;
  return notifications.where((n) => !n.isRead).length;
});