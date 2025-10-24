import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notification_api_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationApiService _notificationService = NotificationApiService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead && !n.isExpired).toList();

  List<NotificationModel> get readNotifications =>
      _notifications.where((n) => n.isRead && !n.isExpired).toList();

  // Initialize notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadNotifications(),
        _loadUnreadCount(),
      ]);
      _error = null;
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load notifications
  Future<void> _loadNotifications({int? limit, bool? unreadOnly}) async {
    try {
      _notifications = await _notificationService.fetchNotifications(
        limit: limit,
        unreadOnly: unreadOnly,
      );
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  // Load unread count
  Future<void> _loadUnreadCount() async {
    try {
      _unreadCount = await _notificationService.getUnreadCount();
    } catch (e) {
      // Don't throw here, just set to 0
      _unreadCount = 0;
    }
  }

  // Refresh notifications
  Future<void> refreshNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadNotifications(),
        _loadUnreadCount(),
      ]);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final updatedNotification = await _notificationService.markAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = updatedNotification;
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();

      // Update local state
      for (var i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
      _unreadCount = 0;
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final wasUnread = !_notifications[index].isRead;
        _notifications.removeAt(index);
        if (wasUnread) {
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        }
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Add new notification (for real-time updates)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
    }
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get notification preferences
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      return await _notificationService.getNotificationPreferences();
    } catch (e) {
      throw Exception('Failed to get notification preferences: $e');
    }
  }

  // Update notification preferences
  Future<bool> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    try {
      await _notificationService.updateNotificationPreferences(preferences);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}