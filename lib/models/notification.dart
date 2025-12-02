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
  
  // Enhanced notification fields
  final String priority;  // low, medium, high, urgent
  final bool isDismissed;
  final DateTime? dismissedAt;
  final String actionType;  // none, view, approve, reject, respond, appeal
  final bool isArchived;
  final DateTime? archivedAt;
  final String? groupKey;
  final bool isBatchNotification;

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
    this.priority = 'medium',
    this.isDismissed = false,
    this.dismissedAt,
    this.actionType = 'none',
    this.isArchived = false,
    this.archivedAt,
    this.groupKey,
    this.isBatchNotification = false,
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
      priority: json['priority'] ?? 'medium',
      isDismissed: json['is_dismissed'] ?? false,
      dismissedAt: json['dismissed_at'] != null ? DateTime.parse(json['dismissed_at']) : null,
      actionType: json['action_type'] ?? 'none',
      isArchived: json['is_archived'] ?? false,
      archivedAt: json['archived_at'] != null ? DateTime.parse(json['archived_at']) : null,
      groupKey: json['group_key'],
      isBatchNotification: json['is_batch_notification'] ?? false,
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
      'priority': priority,
      'is_dismissed': isDismissed,
      'dismissed_at': dismissedAt?.toIso8601String(),
      'action_type': actionType,
      'is_archived': isArchived,
      'archived_at': archivedAt?.toIso8601String(),
      'group_key': groupKey,
      'is_batch_notification': isBatchNotification,
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
    String? priority,
    bool? isDismissed,
    DateTime? dismissedAt,
    String? actionType,
    bool? isArchived,
    DateTime? archivedAt,
    String? groupKey,
    bool? isBatchNotification,
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
      priority: priority ?? this.priority,
      isDismissed: isDismissed ?? this.isDismissed,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      actionType: actionType ?? this.actionType,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      groupKey: groupKey ?? this.groupKey,
      isBatchNotification: isBatchNotification ?? this.isBatchNotification,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  bool get isUrgent => priority == 'urgent';
  bool get isHighPriority => priority == 'high' || priority == 'urgent';

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