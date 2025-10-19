class NotificationModel {
  final int id;
  final String notificationType;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final String? actionUrl;
  final String? actionText;
  final DateTime createdAt;
  final DateTime? expiresAt;

  NotificationModel({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    this.readAt,
    this.actionUrl,
    this.actionText,
    required this.createdAt,
    this.expiresAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      notificationType: json['notification_type'],
      title: json['title'],
      message: json['message'],
      data: json['data'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      actionUrl: json['action_url'],
      actionText: json['action_text'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notification_type': notificationType,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'action_url': actionUrl,
      'action_text': actionText,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    int? id,
    String? notificationType,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    String? actionUrl,
    String? actionText,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      actionUrl: actionUrl ?? this.actionUrl,
      actionText: actionText ?? this.actionText,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}