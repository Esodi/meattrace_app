class UserAuditLog {
  final int id;
  final int? performedById;
  final String? performedByUsername;
  final int affectedUserId;
  final String affectedUserUsername;
  final int? processingUnitId;
  final String? processingUnitName;
  final int? shopId;
  final String? shopName;
  final String action;
  final String description;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final Map<String, dynamic>? metadata;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;

  UserAuditLog({
    required this.id,
    this.performedById,
    this.performedByUsername,
    required this.affectedUserId,
    required this.affectedUserUsername,
    this.processingUnitId,
    this.processingUnitName,
    this.shopId,
    this.shopName,
    required this.action,
    required this.description,
    this.oldValues,
    this.newValues,
    this.metadata,
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
  });

  factory UserAuditLog.fromJson(Map<String, dynamic> json) {
    return UserAuditLog(
      id: json['id'],
      performedById: json['performed_by_id'] ?? json['performed_by'],
      performedByUsername: json['performed_by_username'],
      affectedUserId: json['affected_user_id'] ?? json['affected_user'],
      affectedUserUsername: json['affected_user_username'],
      processingUnitId: json['processing_unit_id'] ?? json['processing_unit'],
      processingUnitName: json['processing_unit_name'],
      shopId: json['shop_id'] ?? json['shop'],
      shopName: json['shop_name'],
      action: json['action'],
      description: json['description'],
      oldValues: json['old_values'],
      newValues: json['new_values'],
      metadata: json['metadata'],
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'performed_by_id': performedById,
      'performed_by_username': performedByUsername,
      'affected_user_id': affectedUserId,
      'affected_user_username': affectedUserUsername,
      'processing_unit_id': processingUnitId,
      'processing_unit_name': processingUnitName,
      'shop_id': shopId,
      'shop_name': shopName,
      'action': action,
      'description': description,
      'old_values': oldValues,
      'new_values': newValues,
      'metadata': metadata,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Computed properties for display
  String get contextName {
    if (processingUnitName != null) return processingUnitName!;
    if (shopName != null) return shopName!;
    return 'System';
  }

  String get actionDisplay => action.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');

  String get performedByDisplay => performedByUsername ?? 'System';

  bool get isUserAction => performedById != null;

  bool get isSecurityEvent => action == 'security_event';

  bool get isLoginEvent => action == 'user_login' || action == 'user_logout';

  bool get isPermissionChange => action.contains('permission') || action.contains('role');

  // Helper method to get changed fields
  List<String> get changedFields {
    if (oldValues == null || newValues == null) return [];

    final changed = <String>[];
    final allKeys = {...oldValues!.keys, ...newValues!.keys};

    for (final key in allKeys) {
      final oldValue = oldValues![key];
      final newValue = newValues![key];
      if (oldValue != newValue) {
        changed.add(key);
      }
    }

    return changed;
  }
}

class UserAuditLogList {
  final List<UserAuditLog> logs;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;

  UserAuditLogList({
    required this.logs,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory UserAuditLogList.fromJson(Map<String, dynamic> json) {
    return UserAuditLogList(
      logs: (json['results'] as List? ?? json['logs'] as List? ?? [])
          .map((log) => UserAuditLog.fromJson(log))
          .toList(),
      totalCount: json['count'] ?? json['total_count'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      hasNext: json['next'] != null,
      hasPrevious: json['previous'] != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logs': logs.map((log) => log.toJson()).toList(),
      'total_count': totalCount,
      'page': page,
      'page_size': pageSize,
      'has_next': hasNext,
      'has_previous': hasPrevious,
    };
  }
}