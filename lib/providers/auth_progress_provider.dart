import 'package:flutter/foundation.dart';
import '../services/auth_websocket_service.dart';

/// Provider to manage authentication progress state
class AuthProgressProvider with ChangeNotifier {
  final AuthWebSocketService _wsService = AuthWebSocketService();
  
  final List<AuthProgressMessage> _messages = [];
  bool _isConnected = false;
  String? _sessionId;
  
  List<AuthProgressMessage> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isConnected;
  String? get sessionId => _sessionId;
  bool get hasMessages => _messages.isNotEmpty;
  
  AuthProgressMessage? get latestMessage => 
      _messages.isNotEmpty ? _messages.last : null;
  
  /// Start listening for authentication progress updates
  Future<String> startListening() async {
    try {
      debugPrint('🎧 [AUTH_PROGRESS] Starting to listen for auth updates...');
      
      // Clear previous messages
      _messages.clear();
      
      // Connect to WebSocket
      _sessionId = await _wsService.connect();
      _isConnected = true;
      notifyListeners();
      
      debugPrint('✅ [AUTH_PROGRESS] Session ID: $_sessionId');
      
      // Listen to messages
      _wsService.messageStream?.listen(
        (message) {
          debugPrint('📨 [AUTH_PROGRESS] New message: ${message.type} - ${message.message}');
          _messages.add(message);
          notifyListeners();
        },
        onError: (error) {
          debugPrint('❌ [AUTH_PROGRESS] Error: $error');
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          debugPrint('✅ [AUTH_PROGRESS] Connection closed');
          _isConnected = false;
          notifyListeners();
        },
      );
      
      return _sessionId!;
    } catch (e) {
      debugPrint('❌ [AUTH_PROGRESS] Failed to start listening: $e');
      _isConnected = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Stop listening and disconnect
  void stopListening() {
    debugPrint('🛑 [AUTH_PROGRESS] Stopping listener...');
    _wsService.disconnect();
    _isConnected = false;
    notifyListeners();
  }
  
  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }
}
