class ProcessingUnitUser {
  final int id;
  final int userId;
  final String username;
  final String email;
  final int processingUnitId;
  final String processingUnitName;
  final String role;
  final String permissions;
  final Map<String, dynamic>? granularPermissions;
  final int? invitedById;
  final String? invitedByUsername;
  final DateTime invitedAt;
  final DateTime? joinedAt;
  final bool isActive;
  final bool isSuspended;
  final String? suspensionReason;
  final DateTime? suspensionDate;
  final DateTime? lastActive;

  ProcessingUnitUser({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
    required this.processingUnitId,
    required this.processingUnitName,
    required this.role,
    required this.permissions,
    this.granularPermissions,
    this.invitedById,
    this.invitedByUsername,
    required this.invitedAt,
    this.joinedAt,
    required this.isActive,
    required this.isSuspended,
    this.suspensionReason,
    this.suspensionDate,
    this.lastActive,
  });

  factory ProcessingUnitUser.fromJson(Map<String, dynamic> json) {
    return ProcessingUnitUser(
      id: json['id'],
      userId: json['user_id'] ?? json['user'],
      username: json['username'],
      email: json['email'],
      processingUnitId: json['processing_unit_id'] ?? json['processing_unit'],
      processingUnitName: json['processing_unit_name'],
      role: json['role'],
      permissions: json['permissions'],
      granularPermissions: json['granular_permissions'],
      invitedById: json['invited_by_id'] ?? json['invited_by'],
      invitedByUsername: json['invited_by_username'],
      invitedAt: DateTime.parse(json['invited_at']),
      joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at']) : null,
      isActive: json['is_active'] ?? true,
      isSuspended: json['is_suspended'] ?? false,
      suspensionReason: json['suspension_reason'],
      suspensionDate: json['suspension_date'] != null ? DateTime.parse(json['suspension_date']) : null,
      lastActive: json['last_active'] != null ? DateTime.parse(json['last_active']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'email': email,
      'processing_unit_id': processingUnitId,
      'processing_unit_name': processingUnitName,
      'role': role,
      'permissions': permissions,
      'granular_permissions': granularPermissions,
      'invited_by_id': invitedById,
      'invited_by_username': invitedByUsername,
      'invited_at': invitedAt.toIso8601String(),
      'joined_at': joinedAt?.toIso8601String(),
      'is_active': isActive,
      'is_suspended': isSuspended,
      'suspension_reason': suspensionReason,
      'suspension_date': suspensionDate?.toIso8601String(),
      'last_active': lastActive?.toIso8601String(),
    };
  }

  // Computed properties for easy access
  bool get canRead => permissions == 'read' || permissions == 'write' || permissions == 'admin';
  bool get canWrite => permissions == 'write' || permissions == 'admin';
  bool get isAdmin => permissions == 'admin';

  bool get isOwner => role == 'owner';
  bool get isManager => role == 'manager';
  bool get isSupervisor => role == 'supervisor';
  bool get isWorker => role == 'worker';
  bool get isQualityControl => role == 'quality_control';

  String get status {
    if (isSuspended) return 'Suspended';
    if (!isActive) return 'Inactive';
    if (joinedAt == null) return 'Invited';
    return 'Active';
  }

  String get displayRole => role.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
}