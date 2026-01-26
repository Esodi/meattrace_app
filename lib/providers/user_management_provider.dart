import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/user_management_service.dart';

enum UserStatus { active, suspended, invited }

enum UserRole { abbatoir, processingUnit, shop, admin }

class UserManagementProvider with ChangeNotifier {
  final UserManagementService _service = UserManagementService();

  final List<User> _users = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  UserStatus? _statusFilter;
  UserRole? _roleFilter;
  int _currentPage = 1;
  bool _hasMorePages = true;
  final int _pageSize = 20;

  // Getters
  List<User> get users => _filteredUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  UserStatus? get statusFilter => _statusFilter;
  UserRole? get roleFilter => _roleFilter;
  bool get hasMorePages => _hasMorePages;
  int get currentPage => _currentPage;

  List<User> get _filteredUsers {
    return _users.where((user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!user.displayName.toLowerCase().contains(query) &&
            !user.email.toLowerCase().contains(query) &&
            !user.username.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Status filter
      if (_statusFilter != null) {
        final userStatus = _getUserStatus(user);
        if (userStatus != _statusFilter) {
          return false;
        }
      }

      // Role filter
      if (_roleFilter != null) {
        final userRole = _getUserRole(user);
        if (userRole != _roleFilter) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  UserStatus _getUserStatus(User user) {
    if (!user.isActive) return UserStatus.suspended;
    // For now, assume all active users are active
    // In future, might need to check invitation status
    return UserStatus.active;
  }

  UserRole _getUserRole(User user) {
    switch (user.role.toLowerCase()) {
      case 'abbatoir':
        return UserRole.abbatoir;
      case 'processingunit':
      case 'processing_unit':
        return UserRole.processingUnit;
      case 'shop':
        return UserRole.shop;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.abbatoir;
    }
  }

  // Actions
  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _users.clear();
      _hasMorePages = true;
    }

    if (!_hasMorePages || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newUsers = await _service.getUsers(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (newUsers.length < _pageSize) {
        _hasMorePages = false;
      }

      _users.addAll(newUsers);
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchUsers(String query) async {
    _searchQuery = query;
    await loadUsers(refresh: true);
  }

  void setStatusFilter(UserStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setRoleFilter(UserRole? role) {
    _roleFilter = role;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _roleFilter = null;
    notifyListeners();
  }

  Future<bool> inviteUser({
    required String email,
    required String role,
    String? message,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.inviteUser(
        email: email,
        role: role,
        message: message,
      );

      if (success) {
        await loadUsers(refresh: true); // Refresh to show new user
      }

      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> suspendUser(int userId, String reason) async {
    try {
      final success = await _service.suspendUser(userId, reason);
      if (success) {
        await loadUsers(refresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> reactivateUser(int userId) async {
    try {
      final success = await _service.reactivateUser(userId);
      if (success) {
        await loadUsers(refresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> removeUser(int userId) async {
    try {
      final success = await _service.removeUser(userId);
      if (success) {
        _users.removeWhere((user) => user.id == userId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateUserRole(int userId, String newRole) async {
    try {
      final success = await _service.updateUserRole(userId, newRole);
      if (success) {
        await loadUsers(refresh: true);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
