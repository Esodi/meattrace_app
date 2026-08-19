import '../models/notification.dart';
import '../services/dio_client.dart';
import 'api_exception.dart';

/// API service for managing user notifications
class NotificationApiService {
  final DioClient _dioClient = DioClient();

  /// Fetch notifications from the server
  Future<List<NotificationModel>> fetchNotifications({
    int? limit,
    bool? unreadOnly,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (unreadOnly != null) queryParams['unread_only'] = unreadOnly;

      final response = await _dioClient.dio.get(
        '/notifications/',
        queryParameters: queryParams,
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch notifications: $e',
      );
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dioClient.dio.get('/notifications/unread-count/');
      return response.data['count'] ?? 0;
    } catch (e) {
      throw ApiException(
        message: 'Failed to get unread count: $e',
      );
    }
  }

  /// Mark a notification as read
  Future<NotificationModel> markAsRead(int notificationId) async {
    try {
      final response = await _dioClient.dio.patch(
        '/notifications/$notificationId/mark-read/',
      );
      return NotificationModel.fromJson(response.data);
    } catch (e) {
      throw ApiException(
        message: 'Failed to mark notification as read: $e',
      );
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _dioClient.dio.post('/notifications/mark-all-read/');
    } catch (e) {
      throw ApiException(
        message: 'Failed to mark all notifications as read: $e',
      );
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _dioClient.dio.delete('/notifications/$notificationId/');
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete notification: $e',
      );
    }
  }

  /// Get notification preferences
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final response = await _dioClient.dio.get('/notifications/preferences/');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ApiException(
        message: 'Failed to get notification preferences: $e',
      );
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(
      Map<String, dynamic> preferences) async {
    try {
      await _dioClient.dio.patch(
        '/notifications/preferences/',
        data: preferences,
      );
    } catch (e) {
      throw ApiException(
        message: 'Failed to update notification preferences: $e',
      );
    }
  }

  /// Delete all read notifications
  Future<void> deleteAllRead() async {
    try {
      await _dioClient.dio.delete('/notifications/delete-all-read/');
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete read notifications: $e',
      );
    }
  }
}