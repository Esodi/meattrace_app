
/// Activity Type Enum
enum ActivityType {
  registration,
  transfer,
  slaughter,
  healthUpdate,
  weightUpdate,
  vaccination,
  other,
}

/// Activity Model
/// Represents a abbatoir activity log entry
class Activity {
  final int? id;
  final ActivityType type;
  final String title;
  final String? description;
  final DateTime timestamp;
  final String? entityId; // Animal ID or batch ID
  final String? entityType; // 'animal', 'batch', etc.
  final Map<String, dynamic>? metadata;
  final String? targetRoute; // Route to navigate when tapped
  final int? userId;
  final String? username;

  Activity({
    this.id,
    required this.type,
    required this.title,
    this.description,
    required this.timestamp,
    this.entityId,
    this.entityType,
    this.metadata,
    this.targetRoute,
    this.userId,
    this.username,
  });

  /// Create Activity from JSON
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as int?,
      type: _activityTypeFromString(json['activity_type'] as String? ?? 'other'),
      title: json['title'] as String? ?? 'Activity',
      description: json['description'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      entityId: json['entity_id'] as String?,
      entityType: json['entity_type'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      targetRoute: json['target_route'] as String?,
      userId: json['user'] as int?, // Django returns user ID in 'user' field
      username: json['user_username'] as String?, // Django might include username
    );
  }

  /// Convert Activity to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_type': _activityTypeToString(type),
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'entity_id': entityId,
      'entity_type': entityType,
      'metadata': metadata,
      'target_route': targetRoute,
      'user': userId, // Django expects user ID in 'user' field
    };
  }

  /// Copy with method
  Activity copyWith({
    int? id,
    ActivityType? type,
    String? title,
    String? description,
    DateTime? timestamp,
    String? entityId,
    String? entityType,
    Map<String, dynamic>? metadata,
    String? targetRoute,
    int? userId,
    String? username,
  }) {
    return Activity(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      metadata: metadata ?? this.metadata,
      targetRoute: targetRoute ?? this.targetRoute,
      userId: userId ?? this.userId,
      username: username ?? this.username,
    );
  }

  /// Convert string to ActivityType
  static ActivityType _activityTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'registration':
      case 'register':
        return ActivityType.registration;
      case 'transfer':
        return ActivityType.transfer;
      case 'slaughter':
        return ActivityType.slaughter;
      case 'health_update':
      case 'health':
        return ActivityType.healthUpdate;
      case 'weight_update':
      case 'weight':
        return ActivityType.weightUpdate;
      case 'vaccination':
        return ActivityType.vaccination;
      default:
        return ActivityType.other;
    }
  }

  /// Convert ActivityType to string
  static String _activityTypeToString(ActivityType type) {
    switch (type) {
      case ActivityType.registration:
        return 'registration';
      case ActivityType.transfer:
        return 'transfer';
      case ActivityType.slaughter:
        return 'slaughter';
      case ActivityType.healthUpdate:
        return 'health_update';
      case ActivityType.weightUpdate:
        return 'weight_update';
      case ActivityType.vaccination:
        return 'vaccination';
      case ActivityType.other:
        return 'other';
    }
  }

  @override
  String toString() {
    return 'Activity(id: $id, type: $type, title: $title, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Activity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Factory methods for creating common activity types
extension ActivityFactory on Activity {
  /// Create registration activity
  static Activity registration({
    required String animalId,
    required String animalTag,
    required DateTime timestamp,
  }) {
    return Activity(
      type: ActivityType.registration,
      title: 'Animal $animalTag registered',
      timestamp: timestamp,
      entityId: animalId,
      entityType: 'animal',
      targetRoute: '/animals/$animalId',
    );
  }

  /// Create transfer activity
  static Activity transfer({
    required int count,
    required String processorName,
    required DateTime timestamp,
    String? batchId,
  }) {
    return Activity(
      type: ActivityType.transfer,
      title: '$count animal${count > 1 ? 's' : ''} transferred to $processorName',
      timestamp: timestamp,
      entityId: batchId,
      entityType: 'transfer',
      metadata: {'count': count, 'processor': processorName},
      targetRoute: '/abbatoir/livestock-history',
    );
  }

  /// Create slaughter activity
  static Activity slaughter({
    required String animalId,
    required String animalTag,
    required DateTime timestamp,
  }) {
    return Activity(
      type: ActivityType.slaughter,
      title: 'Animal $animalTag marked for slaughter',
      timestamp: timestamp,
      entityId: animalId,
      entityType: 'animal',
      targetRoute: '/animals/$animalId',
    );
  }

  /// Create health update activity
  static Activity healthUpdate({
    required String animalId,
    required String animalTag,
    required String newStatus,
    required DateTime timestamp,
  }) {
    return Activity(
      type: ActivityType.healthUpdate,
      title: 'Health status updated for $animalTag to $newStatus',
      timestamp: timestamp,
      entityId: animalId,
      entityType: 'animal',
      metadata: {'status': newStatus},
      targetRoute: '/animals/$animalId',
    );
  }

  /// Create weight update activity
  static Activity weightUpdate({
    required String animalId,
    required String animalTag,
    required double weight,
    required DateTime timestamp,
  }) {
    return Activity(
      type: ActivityType.weightUpdate,
      title: 'Weight recorded for $animalTag: ${weight}kg',
      timestamp: timestamp,
      entityId: animalId,
      entityType: 'animal',
      metadata: {'weight': weight},
      targetRoute: '/animals/$animalId',
    );
  }

  /// Create vaccination activity
  static Activity vaccination({
    required String animalId,
    required String animalTag,
    required String vaccineName,
    required DateTime timestamp,
  }) {
    return Activity(
      type: ActivityType.vaccination,
      title: '$animalTag vaccinated with $vaccineName',
      timestamp: timestamp,
      entityId: animalId,
      entityType: 'animal',
      metadata: {'vaccine': vaccineName},
      targetRoute: '/animals/$animalId',
    );
  }
}
