import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';
import '../models/notification.dart';
import '../providers/notification_provider.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  WebSocketChannel? _channel;
  NotificationProvider? _notificationProvider;
  bool _isConnected = false;

  factory WebSocketService() {
    return _instance;
  }

  WebSocketService._internal();

  void initialize(NotificationProvider notificationProvider) {
    _notificationProvider = notificationProvider;
  }

  Future<void> connect(String userId) async {
    if (_isConnected) return;

    try {
      // Connect to WebSocket endpoint
      // This would need to be configured with your actual WebSocket URL
      final wsUrl = 'ws://localhost:8000/ws/notifications/$userId/';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _onMessageReceived,
        onDone: _onConnectionClosed,
        onError: _onConnectionError,
      );

      _isConnected = true;
    } catch (e) {
      print('WebSocket connection failed: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      _channel = null;
    }
    _isConnected = false;
  }

  void _onMessageReceived(dynamic message) {
    try {
      final data = jsonDecode(message);
      final notificationType = data['type'];

      switch (notificationType) {
        case 'notification':
          final notification = NotificationModel.fromJson(data['notification']);
          _notificationProvider?.addNotification(notification);
          break;
        case 'notification_update':
          // Handle notification updates (mark as read, etc.)
          _handleNotificationUpdate(data);
          break;
        case 'unread_count_update':
          // Update unread count
          final unreadCount = data['unread_count'] ?? 0;
          // This would need to be implemented in the provider
          break;
      }
    } catch (e) {
      print('Error processing WebSocket message: $e');
    }
  }

  void _handleNotificationUpdate(Map<String, dynamic> data) {
    final notificationId = data['notification_id'];
    final action = data['action'];

    switch (action) {
      case 'marked_read':
        // Update local notification state
        break;
      case 'deleted':
        // Remove from local state
        break;
    }
  }

  void _onConnectionClosed() {
    print('WebSocket connection closed');
    _isConnected = false;
    // Implement reconnection logic here
    _scheduleReconnection();
  }

  void _onConnectionError(dynamic error) {
    print('WebSocket connection error: $error');
    _isConnected = false;
    _scheduleReconnection();
  }

  void _scheduleReconnection() {
    // Implement exponential backoff reconnection
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected) {
        // Attempt to reconnect
        // This would need the user ID from somewhere
        print('Attempting to reconnect WebSocket...');
      }
    });
  }

  bool get isConnected => _isConnected;

  // Send messages to server if needed
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }
}