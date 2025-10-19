import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class UserContextProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  Map<String, dynamic> _permissions = {};
  Map<String, dynamic> _userContext = {};

  User? get currentUser => _currentUser;
  Map<String, dynamic> get permissions => _permissions;
  Map<String, dynamic> get userContext => _userContext;

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role.toLowerCase() == 'admin';
  bool get isFarmer => _currentUser?.role.toLowerCase() == 'farmer';
  bool get isProcessingUnit => _currentUser?.role.toLowerCase() == 'processingunit' || _currentUser?.role.toLowerCase() == 'processing_unit';
  bool get isShop => _currentUser?.role.toLowerCase() == 'shop';

  // Permission checks
  bool hasPermission(String permission, {int? processingUnitId}) {
    if (_currentUser == null) return false;
    return _authService.hasPermission(_currentUser!, permission, processingUnitId: processingUnitId);
  }

  bool canManageUsers({int? processingUnitId}) {
    if (_currentUser == null) return false;
    return _authService.canManageUsers(_currentUser!, processingUnitId: processingUnitId);
  }

  bool isOwnerOrManager({int? processingUnitId}) {
    if (_currentUser == null) return false;
    return _authService.isOwnerOrManager(_currentUser!, processingUnitId: processingUnitId);
  }

  // Context management
  void setCurrentUser(User user) {
    _currentUser = user;
    _updatePermissions();
    _updateUserContext();
    notifyListeners();
  }

  void clearCurrentUser() {
    _currentUser = null;
    _permissions.clear();
    _userContext.clear();
    notifyListeners();
  }

  void updateUserContext(String key, dynamic value) {
    _userContext[key] = value;
    notifyListeners();
  }

  void removeUserContext(String key) {
    _userContext.remove(key);
    notifyListeners();
  }

  void clearUserContext() {
    _userContext.clear();
    notifyListeners();
  }

  // Get current processing unit context
  int? getCurrentProcessingUnitId() {
    return _userContext['currentProcessingUnitId'] as int?;
  }

  void setCurrentProcessingUnitId(int? processingUnitId) {
    updateUserContext('currentProcessingUnitId', processingUnitId);
  }

  // Get user memberships for current processing unit
  ProcessingUnitMembership? getCurrentMembership() {
    final processingUnitId = getCurrentProcessingUnitId();
    if (processingUnitId == null || _currentUser?.processingUnitMemberships == null) {
      return null;
    }

    return _currentUser!.processingUnitMemberships!.firstWhere(
      (membership) => membership.processingUnitId == processingUnitId && membership.isActive,
      orElse: () => ProcessingUnitMembership(
        id: -1,
        processingUnitId: -1,
        processingUnitName: '',
        role: '',
        permissions: '',
        isActive: false,
        isSuspended: false,
        invitedAt: DateTime.now(),
      ),
    );
  }

  // Check if user has specific role in current processing unit
  bool hasRoleInCurrentUnit(String role) {
    final membership = getCurrentMembership();
    return membership != null && membership.role.toLowerCase() == role.toLowerCase();
  }

  // Check if user has admin permissions in current processing unit
  bool isAdminInCurrentUnit() {
    final membership = getCurrentMembership();
    return membership != null && membership.isAdmin;
  }

  // Get available processing units for user
  List<ProcessingUnitMembership> getAvailableProcessingUnits() {
    if (_currentUser?.processingUnitMemberships == null) {
      return [];
    }

    return _currentUser!.processingUnitMemberships!
        .where((membership) => membership.isActive && !membership.isSuspended)
        .toList();
  }

  // Private methods
  void _updatePermissions() {
    if (_currentUser == null) {
      _permissions.clear();
      return;
    }

    _permissions = {
      'isAdmin': isAdmin,
      'isFarmer': isFarmer,
      'isProcessingUnit': isProcessingUnit,
      'isShop': isShop,
      'canRead': hasPermission('read'),
      'canWrite': hasPermission('write'),
      'canManageUsers': canManageUsers(),
      'isOwnerOrManager': isOwnerOrManager(),
    };

    // Add processing unit specific permissions
    final memberships = _currentUser!.processingUnitMemberships ?? [];
    for (final membership in memberships) {
      if (membership.isActive && !membership.isSuspended) {
        _permissions['unit_${membership.processingUnitId}'] = {
          'canRead': membership.canRead,
          'canWrite': membership.canWrite,
          'isAdmin': membership.isAdmin,
          'role': membership.role,
          'permissions': membership.permissions,
        };
      }
    }
  }

  void _updateUserContext() {
    if (_currentUser == null) {
      _userContext.clear();
      return;
    }

    _userContext = {
      'userId': _currentUser!.id,
      'username': _currentUser!.username,
      'email': _currentUser!.email,
      'role': _currentUser!.role,
      'processingUnitId': _currentUser!.processingUnitId,
      'processingUnitName': _currentUser!.processingUnitName,
      'shopId': _currentUser!.shopId,
      'shopName': _currentUser!.shopName,
      'isActive': _currentUser!.isActive,
      'dateJoined': _currentUser!.dateJoined?.toIso8601String(),
      'lastLogin': _currentUser!.lastLogin?.toIso8601String(),
    };

    // Add membership information
    if (_currentUser!.processingUnitMemberships != null) {
      _userContext['processingUnitMemberships'] = _currentUser!.processingUnitMemberships!
          .map((membership) => {
                'id': membership.id,
                'processingUnitId': membership.processingUnitId,
                'processingUnitName': membership.processingUnitName,
                'role': membership.role,
                'permissions': membership.permissions,
                'isActive': membership.isActive,
                'isSuspended': membership.isSuspended,
                'isAdmin': membership.isAdmin,
                'canRead': membership.canRead,
                'canWrite': membership.canWrite,
              })
          .toList();
    }
  }
}