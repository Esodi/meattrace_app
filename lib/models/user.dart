class User {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool isActive;
  final DateTime? dateJoined;
  final DateTime? lastLogin;

  // Profile information
  final String role;
  final int? processingUnitId;
  final String? processingUnitName;
  final int? shopId;
  final String? shopName;

  // Processing unit membership info (aggregated from ProcessingUnitUser)
  final List<ProcessingUnitMembership>? processingUnitMemberships;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.isActive = true,
    this.dateJoined,
    this.lastLogin,
    required this.role,
    this.processingUnitId,
    this.processingUnitName,
    this.shopId,
    this.shopName,
    this.processingUnitMemberships,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<ProcessingUnitMembership>? memberships;
    if (json['processing_unit_memberships'] != null) {
      memberships = (json['processing_unit_memberships'] as List)
          .map((m) => ProcessingUnitMembership.fromJson(m))
          .toList();
    }

    // Handle nested structure returned by backend (user/profile keys)
    final userData = json['user'] ?? json;
    final profileData = json['profile'] ?? json;

    return User(
      id: int.parse(userData['id'].toString()),
      username: userData['username'],
      email: userData['email'],
      firstName: userData['first_name'],
      lastName: userData['last_name'],
      isActive: userData['is_active'] ?? true,
      dateJoined: userData['date_joined'] != null ? DateTime.parse(userData['date_joined']) : null,
      lastLogin: userData['last_login'] != null ? DateTime.parse(userData['last_login']) : null,
      role: profileData['role'] ?? 'Farmer',
      processingUnitId: profileData['processing_unit'] is int ? profileData['processing_unit'] : null,
      processingUnitName: profileData['processing_unit'] is String ? profileData['processing_unit'] : null,
      shopId: profileData['shop'] is int ? profileData['shop'] : null,
      shopName: profileData['shop'] is String ? profileData['shop'] : null,
      processingUnitMemberships: memberships,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'is_active': isActive,
      'date_joined': dateJoined?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'role': role,
      'processing_unit_id': processingUnitId,
      'processing_unit_name': processingUnitName,
      'shop_id': shopId,
      'shop_name': shopName,
      'processing_unit_memberships': processingUnitMemberships?.map((m) => m.toJson()).toList(),
    };
  }

  String get displayName => firstName != null && lastName != null
      ? '$firstName $lastName'
      : username;

  bool get isFarmer => role == 'Farmer';
  bool get isProcessingUnit => role == 'ProcessingUnit';
  bool get isShop => role == 'Shop';
}

class ProcessingUnitMembership {
  final int id;
  final int processingUnitId;
  final String processingUnitName;
  final String role;
  final String permissions;
  final Map<String, dynamic>? granularPermissions;
  final bool isActive;
  final bool isSuspended;
  final String? suspensionReason;
  final DateTime? suspensionDate;
  final DateTime? lastActive;
  final DateTime invitedAt;
  final DateTime? joinedAt;

  ProcessingUnitMembership({
    required this.id,
    required this.processingUnitId,
    required this.processingUnitName,
    required this.role,
    required this.permissions,
    this.granularPermissions,
    required this.isActive,
    required this.isSuspended,
    this.suspensionReason,
    this.suspensionDate,
    this.lastActive,
    required this.invitedAt,
    this.joinedAt,
  });

  factory ProcessingUnitMembership.fromJson(Map<String, dynamic> json) {
    return ProcessingUnitMembership(
      id: json['id'],
      processingUnitId: json['processing_unit_id'] ?? json['processing_unit'],
      processingUnitName: json['processing_unit_name'],
      role: json['role'],
      permissions: json['permissions'],
      granularPermissions: json['granular_permissions'],
      isActive: json['is_active'] ?? true,
      isSuspended: json['is_suspended'] ?? false,
      suspensionReason: json['suspension_reason'],
      suspensionDate: json['suspension_date'] != null ? DateTime.parse(json['suspension_date']) : null,
      lastActive: json['last_active'] != null ? DateTime.parse(json['last_active']) : null,
      invitedAt: DateTime.parse(json['invited_at']),
      joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'processing_unit_id': processingUnitId,
      'processing_unit_name': processingUnitName,
      'role': role,
      'permissions': permissions,
      'granular_permissions': granularPermissions,
      'is_active': isActive,
      'is_suspended': isSuspended,
      'suspension_reason': suspensionReason,
      'suspension_date': suspensionDate?.toIso8601String(),
      'last_active': lastActive?.toIso8601String(),
      'invited_at': invitedAt.toIso8601String(),
      'joined_at': joinedAt?.toIso8601String(),
    };
  }

  bool get canRead => permissions == 'read' || permissions == 'write' || permissions == 'admin';
  bool get canWrite => permissions == 'write' || permissions == 'admin';
  bool get isAdmin => permissions == 'admin';
}







