import 'package:flutter/foundation.dart';
import '../models/shop.dart';
import '../models/shop_user.dart';
import '../models/join_request.dart';
import '../services/api_service.dart';

class ShopManagementProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State
  Shop? _currentShop;
  List<ShopUser> _members = [];
  List<JoinRequest> _joinRequests = [];
  List<Shop> _availableShops = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Shop? get currentShop => _currentShop;
  List<ShopUser> get members => _members;
  List<JoinRequest> get joinRequests => _joinRequests; // All join requests
  List<JoinRequest> get pendingJoinRequests => 
      _joinRequests.where((r) => r.status == 'pending').toList();
  List<Shop> get availableShops => _availableShops;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if current user is owner/manager
  bool canManageUsers([int? userId]) {
    if (userId == null || _members.isEmpty) return false;
    final member = _members.firstWhere(
      (m) => m.userId == userId,
      orElse: () => ShopUser(
        id: 0,
        userId: 0,
        username: '',
        email: '',
        shopId: 0,
        shopName: '',
        role: 'salesperson',
        permissions: 'read',
        invitedAt: DateTime.now(),
        isActive: false,
        isSuspended: false,
      ),
    );
    return member.isOwner || member.isManager;
  }

  // Create new shop
  Future<bool> createShop(Shop shop) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/shops/register/',
        data: shop.toJsonForCreate(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _currentShop = Shop.fromJson(response.data);
        await loadShopMembers(_currentShop!.id!);
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to create shop';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load available shops for joining
  Future<void> loadAvailableShops({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = search != null && search.isNotEmpty
          ? {'search': search}
          : null;

      final response = await _apiService.get(
        '/shops/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List 
            ? response.data 
            : response.data['results'] ?? [];
        _availableShops = data.map((json) => Shop.fromJson(json)).toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Request to join shop
  Future<bool> requestJoinShop({
    required int shopId,
    required String requestedRole,
    String? message,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/shops/$shopId/join-request/',
        data: {
          'requested_role': requestedRole,
          'message': message,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to send join request';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load shop members
  Future<void> loadShopMembers(int shopId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/shops/$shopId/members/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List 
            ? response.data 
            : response.data['results'] ?? [];
        _members = data.map((json) => ShopUser.fromJson(json)).toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load join requests (for owners/managers)
  Future<void> loadJoinRequests(int shopId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/shops/$shopId/join-requests/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List 
            ? response.data 
            : response.data['results'] ?? [];
        _joinRequests = data.map((json) => JoinRequest.fromJson(json)).toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Invite user to shop
  Future<bool> inviteUser({
    required int shopId,
    required String email,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/shops/$shopId/invite-user/',
        data: {
          'email': email,
          'role': role,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadShopMembers(shopId);
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to invite user';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update member role
  Future<bool> updateMemberRole({
    required int shopId,
    required int memberId,
    required String role,
    String? permission,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final requestData = <String, dynamic>{'role': role};
      if (permission != null) {
        requestData['permissions'] = permission;
      }

      final response = await _apiService.patch(
        '/shops/$shopId/members/$memberId/',
        data: requestData,
      );

      if (response.statusCode == 200) {
        await loadShopMembers(shopId);
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to update member role';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove member from shop
  Future<bool> removeMember({
    required int shopId,
    required int memberId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.delete(
        '/shops/$shopId/members/$memberId/',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await loadShopMembers(shopId);
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to remove member';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Approve join request
  Future<bool> approveJoinRequest(int requestId, {String? responseMessage}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.patch(
        '/join-requests/$requestId/',
        data: {
          'status': 'approved',
          'response_message': responseMessage,
        },
      );

      if (response.statusCode == 200) {
        if (_currentShop != null) {
          await loadShopMembers(_currentShop!.id!);
          await loadJoinRequests(_currentShop!.id!);
        }
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to approve request';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reject join request
  Future<bool> rejectJoinRequest(int requestId, {String? responseMessage}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.patch(
        '/join-requests/$requestId/',
        data: {
          'status': 'rejected',
          'response_message': responseMessage,
        },
      );

      if (response.statusCode == 200) {
        if (_currentShop != null) {
          await loadJoinRequests(_currentShop!.id!);
        }
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to reject request';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update shop details
  Future<bool> updateShop(int shopId, Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.patch(
        '/shops/$shopId/',
        data: updates,
      );

      if (response.statusCode == 200) {
        _currentShop = Shop.fromJson(response.data);
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to update shop';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _currentShop = null;
    _members = [];
    _joinRequests = [];
    _availableShops = [];
    _error = null;
    notifyListeners();
  }
}
