import 'package:flutter/foundation.dart';

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

  // Pending join request information
  final bool hasPendingJoinRequest;
  final String? pendingJoinRequestUnitName;
  final String? pendingJoinRequestShopName;
  final String? pendingJoinRequestRole;
  final DateTime? pendingJoinRequestDate;

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
    this.hasPendingJoinRequest = false,
    this.pendingJoinRequestUnitName,
    this.pendingJoinRequestShopName,
    this.pendingJoinRequestRole,
    this.pendingJoinRequestDate,
    this.hasRejectedJoinRequest = false,
    this.rejectionReason,
    this.rejectionDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
      debugPrint('🔍 [USER_FROM_JSON] Starting User.fromJson parsing');
      debugPrint('🔍 [USER_FROM_JSON] Raw JSON keys: ${json.keys}');
      debugPrint('🔍 [USER_FROM_JSON] Raw JSON: $json');

      List<ProcessingUnitMembership>? memberships;
      if (json['processing_unit_memberships'] != null) {
          debugPrint('🔍 [USER_FROM_JSON] Processing memberships...');
          memberships = (json['processing_unit_memberships'] as List)
              .map((m) => ProcessingUnitMembership.fromJson(m))
              .toList();
      }

      // Handle different response structures:
      // 1. Profile endpoint returns UserProfile data directly at root with user_username, user_email fields
      // 2. Auth endpoint may return nested 'user' object
      // 3. Other endpoints may return nested 'profile' object
      
      // Check if this is a UserProfile response (has user_username field)
      final isProfileResponse = json.containsKey('user_username');
      
      Map<String, dynamic> userData;
      Map<String, dynamic> profileData;
      
      if (isProfileResponse) {
          // Profile endpoint response - data is at root level
          debugPrint('🔍 [USER_FROM_JSON] Detected UserProfile response format');
          userData = json;
          profileData = json;
      } else if (json['user'] != null && json['user'] is Map) {
          // Nested user object
          debugPrint('🔍 [USER_FROM_JSON] Detected nested user object format');
          userData = json['user'] as Map<String, dynamic>;
          profileData = json['profile'] ?? json['user'];
      } else if (json['profile'] != null && json['profile'] is Map) {
          // Nested profile object
          debugPrint('🔍 [USER_FROM_JSON] Detected nested profile object format');
          userData = json['profile'] as Map<String, dynamic>;
          profileData = json['profile'] as Map<String, dynamic>;
      } else {
          // Direct user data (fallback)
          debugPrint('🔍 [USER_FROM_JSON] Using direct JSON format');
          userData = json;
          profileData = json;
      }

      debugPrint('🔍 [USER_FROM_JSON] userData keys: ${userData.keys}');
      debugPrint('🔍 [USER_FROM_JSON] profileData keys: ${profileData.keys}');

      // Check for null values that could cause String errors
      debugPrint('🔍 [USER_FROM_JSON] Checking critical fields:');
      debugPrint('🔍 [USER_FROM_JSON] userData["username"]: ${userData['username']} (type: ${userData['username']?.runtimeType})');
      debugPrint('🔍 [USER_FROM_JSON] userData["user_username"]: ${userData['user_username']} (type: ${userData['user_username']?.runtimeType})');
      debugPrint('🔍 [USER_FROM_JSON] userData["email"]: ${userData['email']} (type: ${userData['email']?.runtimeType})');
      debugPrint('🔍 [USER_FROM_JSON] userData["user_email"]: ${userData['user_email']} (type: ${userData['user_email']?.runtimeType})');
      debugPrint('🔍 [USER_FROM_JSON] profileData["role"]: ${profileData['role']} (type: ${profileData['role']?.runtimeType})');

      // Check processing unit data
      if (profileData['processing_unit'] != null) {
          debugPrint('🔍 [USER_FROM_JSON] processing_unit present: ${profileData['processing_unit']}');
          if (profileData['processing_unit'] is Map) {
              final puMap = profileData['processing_unit'] as Map;
              debugPrint('🔍 [USER_FROM_JSON] processing_unit["name"]: ${puMap['name']} (type: ${puMap['name']?.runtimeType})');
          }
      }

      // Check shop data
      if (profileData['shop'] != null) {
          debugPrint('🔍 [USER_FROM_JSON] shop present: ${profileData['shop']}');
          if (profileData['shop'] is Map) {
              final shopMap = profileData['shop'] as Map;
              debugPrint('🔍 [USER_FROM_JSON] shop["name"]: ${shopMap['name']} (type: ${shopMap['name']?.runtimeType})');
          }
      }

      // Parse processing unit - handle both nested object and flat ID formats
      int? processingUnitId;
      String? processingUnitName;
      
      if (profileData['processing_unit'] != null) {
          if (profileData['processing_unit'] is Map) {
              // Nested object format: {id: 1, name: "Unit Name"}
              processingUnitId = int.tryParse(profileData['processing_unit']['id'].toString());
              processingUnitName = profileData['processing_unit']['name']?.toString();
          } else {
              // Flat ID format: processing_unit: 1, processing_unit_name: "Unit Name"
              processingUnitId = int.tryParse(profileData['processing_unit'].toString());
              processingUnitName = profileData['processing_unit_name']?.toString();
          }
      }
      
      // Parse shop - handle both nested object and flat ID formats
      int? shopId;
      String? shopName;
      
      if (profileData['shop'] != null) {
          if (profileData['shop'] is Map) {
              // Nested object format: {id: 1, name: "Shop Name"}
              shopId = int.tryParse(profileData['shop']['id'].toString());
              shopName = profileData['shop']['name']?.toString();
          } else {
              // Flat ID format: shop: 1, shop_name: "Shop Name"
              shopId = int.tryParse(profileData['shop'].toString());
              shopName = profileData['shop_name']?.toString();
          }
      }

      return User(
        id: userData['id'],
        username: userData['username'] ?? userData['user_username'] ?? '',
        email: userData['email'] ?? userData['user_email'] ?? '',
        firstName: userData['first_name'],
        lastName: userData['last_name'],
        isActive: userData['is_active'] ?? true,
        dateJoined: userData['date_joined'] != null ? DateTime.parse(userData['date_joined']) : null,
        lastLogin: userData['last_login'] != null ? DateTime.parse(userData['last_login']) : null,
        role: profileData['role'] ?? 'worker',
        processingUnitId: processingUnitId,
        processingUnitName: processingUnitName,
        shopId: shopId,
        shopName: shopName,
        processingUnitMemberships: memberships,
        hasPendingJoinRequest: userData['has_pending_join_request'] ?? false,
        pendingJoinRequestUnitName: userData['pending_join_request'] != null ? userData['pending_join_request']['processing_unit_name'] : null,
        pendingJoinRequestShopName: userData['pending_join_request'] != null ? userData['pending_join_request']['shop_name'] : null,
        pendingJoinRequestRole: userData['pending_join_request'] != null ? userData['pending_join_request']['requested_role'] : null,
        pendingJoinRequestDate: userData['pending_join_request'] != null && userData['pending_join_request']['created_at'] != null 
            ? DateTime.parse(userData['pending_join_request']['created_at']) 
            : null,
        // Parse rejected request data
        hasRejectedJoinRequest: userData['has_rejected_join_request'] ?? false,
        rejectionReason: userData['rejected_join_request'] != null ? userData['rejected_join_request']['rejection_reason'] : null,
        rejectionDate: userData['rejected_join_request'] != null && userData['rejected_join_request']['updated_at'] != null
            ? DateTime.parse(userData['rejected_join_request']['updated_at'])
            : null,
      );
  }

  // Helper getters
  bool get isFarmer => role.toLowerCase() == 'abbatoir';
  bool get isProcessingUnit => role.toLowerCase().contains('processor') || role.toLowerCase().contains('processing');
  bool get isShop => role.toLowerCase().contains('shop');
  
  // Display name helper
  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      if (lastName != null && lastName!.isNotEmpty) {
        return '$firstName $lastName';
      }
      return firstName!;
    }
    return username;
  }

  // Rejection details
  final bool hasRejectedJoinRequest;
  final String? rejectionReason;
  final DateTime? rejectionDate;
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
    debugPrint('🔍 [MEMBERSHIP_FROM_JSON] Processing membership: $json');

    // Check for null String fields that could cause errors
    debugPrint('🔍 [MEMBERSHIP_FROM_JSON] processing_unit_name: ${json['processing_unit_name']} (type: ${json['processing_unit_name']?.runtimeType})');
    debugPrint('🔍 [MEMBERSHIP_FROM_JSON] role: ${json['role']} (type: ${json['role']?.runtimeType})');
    debugPrint('🔍 [MEMBERSHIP_FROM_JSON] permissions: ${json['permissions']} (type: ${json['permissions']?.runtimeType})');

    return ProcessingUnitMembership(
      id: json['id'],
      processingUnitId: json['processing_unit_id'] ?? json['processing_unit'],
      processingUnitName: json['processing_unit_name']?.toString() ?? 'Unknown Processing Unit',
      role: json['role']?.toString() ?? 'worker',
      permissions: json['permissions']?.toString() ?? 'read',
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







