class ShopUser {
  final int id;
  final int userId;
  final String username;
  final String email;
  final int shopId;
  final String shopName;
  final String role; // 'owner', 'manager', 'salesperson', 'cashier', 'inventory_clerk'
  final String permissions; // 'read', 'write', 'admin'
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

  ShopUser({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
    required this.shopId,
    required this.shopName,
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

  factory ShopUser.fromJson(Map<String, dynamic> json) {
    return ShopUser(
      id: json['id'],
      userId: json['user_id'] ?? json['user'],
      username: json['username'],
      email: json['email'],
      shopId: json['shop_id'] ?? json['shop'],
      shopName: json['shop_name'],
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
      'shop_id': shopId,
      'shop_name': shopName,
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
  bool get isSalesperson => role == 'salesperson';
  bool get isCashier => role == 'cashier';
  bool get isInventoryClerk => role == 'inventory_clerk';

  String get status {
    if (isSuspended) return 'Suspended';
    if (!isActive) return 'Inactive';
    if (joinedAt == null) return 'Invited';
    return 'Active';
  }

  String get displayRole => role.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');

  // Role-specific permission checks
  bool get canViewProducts => canRead;
  bool get canEditProducts => isOwner || isManager;
  bool get canManageInventory => isOwner || isManager || isInventoryClerk;
  bool get canProcessOrders => canWrite && (isOwner || isManager || isSalesperson || isCashier);
  bool get canViewReports => isOwner || isManager || isInventoryClerk;
  bool get canManageUsers => isOwner || isManager;
  bool get canChangeShopSettings => isOwner;
}
