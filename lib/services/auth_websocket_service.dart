import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/constants.dart';

/// Custom error class for WebSocket authentication errors
class AuthWebSocketError extends Error {
  final String code;
  final String message;

  AuthWebSocketError(this.code, this.message);

  @override
  String toString() => 'AuthWebSocketError($code): $message';
}

/// Model for authentication progress messages
class AuthProgressMessage {
  final String type; // 'progress', 'complete', 'error', 'connected'
  final String? step;
  final String message;
  final String? status; // 'info', 'success', 'warning', 'error'
  final DateTime timestamp;
  final Map<String, dynamic>? details;
  final bool? success;
  final Map<String, dynamic>? user;
  final String? code;

  AuthProgressMessage({
    required this.type,
    this.step,
    required this.message,
    this.status,
    required this.timestamp,
    this.details,
    this.success,
    this.user,
    this.code,
  });

  factory AuthProgressMessage.fromJson(Map<String, dynamic> json) {
    return AuthProgressMessage(
      type: json['type'] ?? 'progress',
      step: json['step'],
      message: json['message'] ?? '',
      status: json['status'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      details: json['details'],
      success: json['success'],
      user: json['user'],
      code: json['code'],
    );
  }

  bool get isError => type == 'error' || status == 'error';
  bool get isSuccess => type == 'complete' && success == true;
  bool get isProgress => type == 'progress';
  bool get isComplete => type == 'complete';
}

/// Service for managing WebSocket connection to receive real-time authentication progress
class AuthWebSocketService {
  WebSocketChannel? _channel;
  StreamController<AuthProgressMessage>? _messageController;
  String? _sessionId;
  bool _isConnected = false;

  Stream<AuthProgressMessage>? get messageStream => _messageController?.stream;
  bool get isConnected => _isConnected;
  String? get sessionId => _sessionId;

  /// Connect to the authentication progress WebSocket
  /// Returns the session ID to be sent with auth requests
  Future<String> connect() async {
    // Generate a unique session ID
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    debugPrint('🔌 [AUTH_WS] Connecting to auth progress WebSocket with session: $_sessionId');
    
    // Create message stream controller
    _messageController = StreamController<AuthProgressMessage>.broadcast();
    
    try {
      // Build WebSocket URL
      final wsUrl = _buildWebSocketUrl(_sessionId!);
      debugPrint('🔗 [AUTH_WS] WebSocket URL: $wsUrl');
      
      // Connect to WebSocket
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Listen to incoming messages
      _channel!.stream.listen(
        (data) {
          try {
            final jsonData = jsonDecode(data);
            debugPrint('📨 [AUTH_WS] Received message: ${jsonData['type']} - ${jsonData['message']}');
            
            final message = AuthProgressMessage.fromJson(jsonData);
            _messageController?.add(message);
            
            // Auto-close connection on complete or error
            if (message.isComplete || message.isError) {
              debugPrint('🔚 [AUTH_WS] Auth flow completed, will close connection in 2s');
              Future.delayed(const Duration(seconds: 2), () => disconnect());
            }
          } catch (e) {
            debugPrint('❌ [AUTH_WS] Error parsing message: $e');
          }
        },
        onError: (error) {
          debugPrint('❌ [AUTH_WS] WebSocket error: $error');
          _isConnected = false;
          
          // Provide specific error handling for common WebSocket connection issues
          if (error.toString().contains('404') || error.toString().contains('Not Found')) {
            debugPrint('💡 [AUTH_WS] WebSocket endpoint not found - likely running in WSGI mode');
            debugPrint('💡 [AUTH_WS] Solution: Use `python runserver.py` instead of `python manage.py runserver`');
            
            // Send a formatted error message for server incompatibility
            _messageController?.addError(AuthWebSocketError('server_incompatible', 'WebSocket server not available - use ASGI server'));
          } else if (error.toString().contains('Connection refused')) {
            debugPrint('💡 [AUTH_WS] Connection refused - server may not be running');
            _messageController?.addError(AuthWebSocketError('connection_failed', 'Cannot connect to WebSocket server'));
          } else {
            _messageController?.addError(error);
          }
        },
        onDone: () {
          debugPrint('✅ [AUTH_WS] WebSocket connection closed');
          _isConnected = false;
        },
      );
      
      _isConnected = true;
      debugPrint('✅ [AUTH_WS] Connected successfully');
      
      return _sessionId!;
    } catch (e) {
      debugPrint('❌ [AUTH_WS] Failed to connect: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Disconnect from the WebSocket
  void disconnect() {
    debugPrint('🔌 [AUTH_WS] Disconnecting...');
    
    _channel?.sink.close();
    _messageController?.close();
    
    _channel = null;
    _messageController = null;
    _sessionId = null;
    _isConnected = false;
    
    debugPrint('✅ [AUTH_WS] Disconnected');
  }

  /// Send a ping message to keep connection alive
  void sendPing() {
    if (!_isConnected || _channel == null) return;
    
    try {
      _channel!.sink.add(jsonEncode({
        'type': 'ping',
        'timestamp': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      debugPrint('❌ [AUTH_WS] Error sending ping: $e');
    }
  }

  /// Build WebSocket URL for the auth progress endpoint
  String _buildWebSocketUrl(String sessionId) {
    // Convert HTTP URL to WebSocket URL
    var wsBaseUrl = Constants.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    
    // Remove /api/v2 suffix since WebSocket routes are at root level
    wsBaseUrl = wsBaseUrl.replaceFirst('/api/v2', '');
    
    // Remove trailing slash if present
    if (wsBaseUrl.endsWith('/')) {
      wsBaseUrl = wsBaseUrl.substring(0, wsBaseUrl.length - 1);
    }
    
    // Build the full WebSocket URL
    // Format: ws://localhost:8000/ws/auth/progress/{session_id}/
    return '$wsBaseUrl/ws/auth/progress/$sessionId/';
  }
}
