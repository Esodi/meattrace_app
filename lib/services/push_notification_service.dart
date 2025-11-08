import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification.dart';
import '../providers/notification_provider.dart';
import '../services/dio_client.dart';
import 'api_exception.dart';

/// Push notification service for handling Firebase Cloud Messaging
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final DioClient _dioClient = DioClient();

  NotificationProvider? _notificationProvider;
  bool _isInitialized = false;

  /// Initialize Firebase and local notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Request permission for iOS
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Configure message handlers
      await _configureMessageHandlers();

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _sendTokenToServer(token);
      }

      // Listen for token updates
      _firebaseMessaging.onTokenRefresh.listen(_sendTokenToServer);

      _isInitialized = true;
      debugPrint('PushNotificationService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize PushNotificationService: $e');
      rethrow;
    }
  }

  /// Set the notification provider for real-time updates
  void setNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Configure Firebase message handlers
  Future<void> _configureMessageHandlers() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle messages when app is terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleTerminatedMessage(initialMessage);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.notification?.title}');

    // Show local notification
    _showLocalNotification(message);

    // Add to notification provider if available
    if (_notificationProvider != null && message.data.isNotEmpty) {
      try {
        final notification = _parseNotificationFromData(message.data);
        _notificationProvider!.addNotification(notification);
      } catch (e) {
        debugPrint('Failed to parse notification from data: $e');
      }
    }
  }

  /// Handle background messages
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('App opened from background message: ${message.notification?.title}');
    _handleNotificationAction(message);
  }

  /// Handle terminated messages
  void _handleTerminatedMessage(RemoteMessage message) {
    debugPrint('App opened from terminated state: ${message.notification?.title}');
    _handleNotificationAction(message);
  }

  /// Handle notification tap action
  void _handleNotificationAction(RemoteMessage message) {
    // Navigate based on notification data
    final actionUrl = message.data['action_url'];
    if (actionUrl != null) {
      // TODO: Navigate to the action URL
      debugPrint('Navigate to: $actionUrl');
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final actionUrl = data['action_url'];
        if (actionUrl != null) {
          // TODO: Navigate to the action URL
          debugPrint('Navigate to: $actionUrl');
        }
      } catch (e) {
        debugPrint('Failed to parse notification payload: $e');
      }
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'meat_trace_channel',
      'MeatTrace Notifications',
      channelDescription: 'Notifications for MeatTrace app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      notification.title ?? 'MeatTrace',
      notification.body ?? '',
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Parse notification from message data
  NotificationModel _parseNotificationFromData(Map<String, dynamic> data) {
    return NotificationModel(
      id: int.parse(data['id'] ?? '0'),
      notificationType: data['notification_type'] ?? 'info',
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      data: data['data'],
      isRead: false,
      createdAt: DateTime.now(),
      actionUrl: data['action_url'],
      actionText: data['action_text'],
    );
  }

  /// Send FCM token to server
  Future<void> _sendTokenToServer(String token) async {
    try {
      await _dioClient.dio.post(
        '/notifications/register-device/',
        data: {
          'fcm_token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        },
      );
      debugPrint('FCM token sent to server successfully');
    } catch (e) {
      debugPrint('Failed to send FCM token to server: $e');
      throw ApiException(message: 'Failed to register device for notifications');
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Failed to delete FCM token: $e');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}