import 'dart:convert';

enum SyncMethod { POST, PUT, DELETE, PATCH }

class SyncQueueItem {
  final int? id;
  final String endpoint;
  final SyncMethod method;
  final Map<String, dynamic> body;
  final Map<String, String>? filePaths;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  SyncQueueItem({
    this.id,
    required this.endpoint,
    required this.method,
    required this.body,
    this.filePaths,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'endpoint': endpoint,
      'method': method.name,
      'body': json.encode(body),
      'file_paths': filePaths != null ? json.encode(filePaths) : null,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'],
      endpoint: map['endpoint'],
      method: SyncMethod.values.firstWhere(
        (e) => e.name == map['method'],
        orElse: () => SyncMethod.POST,
      ),
      body: json.decode(map['body']),
      filePaths: map['file_paths'] != null
          ? Map<String, String>.from(json.decode(map['file_paths']))
          : null,
      createdAt: DateTime.parse(map['created_at']),
      retryCount: map['retry_count'] ?? 0,
      lastError: map['last_error'],
    );
  }
}
