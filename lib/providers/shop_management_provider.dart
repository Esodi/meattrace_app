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
  int? _currentUserId; // Track current user ID for permission checks

  // Getters
  Shop? get currentShop => _currentShop;
  List<ShopUser> get members => _members;
  List<JoinRequest> get joinRequests => _joinRequests; // All join requests
  List<JoinRequest> get pendingJoinRequests =>
      _joinRequests.where((r) => r.status == 'pending').toList();
  List<Shop> get availableShops => _availableShops;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get currentUserId => _currentUserId; // Expose for debugging

  // Set current user ID (should be called when user logs in)
  void setCurrentUserId(int userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  // Check if current user is owner/manager
  bool canManageUsers([int? userId]) {
    // Use provided userId or fall back to stored current user ID
    final userIdToCheck = userId ?? _currentUserId;

    if (userIdToCheck == null) {
      debugPrint('⚠️ [SHOP_PERMISSION_CHECK] Cannot manage users: no userId provided and no currentUserId set');
      return false;
    }

    if (_members.isEmpty) {
      debugPrint('⚠️ [SHOP_PERMISSION_CHECK] Cannot manage users: members list is empty (userId=$userIdToCheck)');
      // If we have a current shop and user ID but no members, try to load them
      if (_currentShop != null && !_isLoading) {
        debugPrint('🔄 [SHOP_PERMISSION_CHECK] Attempting to load members for permission check...');
        // Don't await here as this is a synchronous method
        loadShopMembers(_currentShop!.id!).then((_) {
          debugPrint('✅ [SHOP_PERMISSION_CHECK] Members loaded asynchronously');
        }).catchError((e) {
          debugPrint('❌ [SHOP_PERMISSION_CHECK] Failed to load members: $e');
        });
      }
      return false;
    }

    // Use where().firstOrNull pattern to safely check if member exists
    final member = _members.where((m) => m.userId == userIdToCheck).firstOrNull;
    if (member == null) {
      debugPrint('⚠️ [SHOP_PERMISSION_CHECK] User $userIdToCheck not found in members list (${_members.length} members)');
      
      // Fallback: Check if the user is the shop owner based on their profile data
      // This is crucial when members list hasn't loaded yet but we need to show UI elements
      if (userIdToCheck == _currentUserId) {
        // We can't easily access the User object here directly without passing it, 
        // but we can assume if they are accessing this screen and have the role, they might be the owner.
        // A safer check would be to pass the User object or check a flag.
        // For now, if members are empty, we'll return false to be safe, 
        // BUT we should rely on the UI layer (ShopUserManagementScreen) to handle the redirect 
        // if the user really shouldn't be there.
        
        // However, to fix the specific issue of "Access Denied" on UI elements while loading:
        // If we are in the process of loading, we might want to be optimistic or wait.
        return false;
      }
      return false;
    }

    final canManage = member.isOwner || member.isManager;
    debugPrint('✅ [SHOP_PERMISSION_CHECK] User $userIdToCheck canManage=$canManage (isOwner=${member.isOwner}, isManager=${member.isManager})');
    return canManage;
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
      debugPrint('🔄 [SHOP_PROVIDER] Loading members for shop $shopId...');
      final response = await _apiService.get('/shops/$shopId/members/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : response.data['results'] ?? [];
        _members = data.map((json) => ShopUser.fromJson(json)).toList();

        // Also load the shop details if we don't have them
        if (_currentShop == null || _currentShop!.id != shopId) {
          debugPrint('🔄 [SHOP_PROVIDER] Loading shop details for shop $shopId...');
          final shopResponse = await _apiService.get('/shops/$shopId/');
          if (shopResponse.statusCode == 200) {
            _currentShop = Shop.fromJson(shopResponse.data);
            debugPrint('✅ [SHOP_PROVIDER] Loaded shop details: ${_currentShop!.name}');
          }
        }

        debugPrint('✅ [SHOP_PROVIDER] Loaded ${_members.length} members into provider state');
        if (_members.isNotEmpty) {
          debugPrint('✅ [SHOP_PROVIDER] First member: userId=${_members.first.userId}, role=${_members.first.role}');
        }
      } else {
        debugPrint('❌ [SHOP_PROVIDER] Failed to load members: status=${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [SHOP_PROVIDER] Error loading members: $e');
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
      // Add timestamp to prevent caching and ensure fresh data
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await _apiService.get('/shops/$shopId/join-requests/?_t=$timestamp');

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
