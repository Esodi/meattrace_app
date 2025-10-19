import 'package:dio/dio.dart';
import '../models/notification.dart';
import 'dio_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final DioClient _dioClient = DioClient();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<List<NotificationModel>> fetchNotifications({
    int? limit,
    bool? unreadOnly,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (unreadOnly != null && unreadOnly) queryParams['is_read'] = false;

      final response = await _dioClient.dio.get(
        '/notifications/',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List;
        return results.map((json) => NotificationModel.fromJson(json)).toList();
      } else if (data is List) {
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch notifications: ${e.message}');
    }
  }

  Future<NotificationModel> markAsRead(int notificationId) async {
    try {
      final response = await _dioClient.dio.patch(
        '/notifications/$notificationId/',
        data: {'is_read': true},
      );
      return NotificationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to mark notification as read: ${e.message}');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dioClient.dio.post('/notifications/mark_all_read/');
    } on DioException catch (e) {
      throw Exception('Failed to mark all notifications as read: ${e.message}');
    }
  }

  Future<NotificationModel> deleteNotification(int notificationId) async {
    try {
      final response = await _dioClient.dio.delete('/notifications/$notificationId/');
      return NotificationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to delete notification: ${e.message}');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dioClient.dio.get('/notifications/unread_count/');
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      throw Exception('Failed to get unread count: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    try {
      final response = await _dioClient.dio.patch(
        '/user/notification-preferences/',
        data: preferences,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to update notification preferences: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final response = await _dioClient.dio.get('/user/notification-preferences/');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to get notification preferences: ${e.message}');
    }
  }
}