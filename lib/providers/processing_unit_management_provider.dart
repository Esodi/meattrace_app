import 'package:flutter/foundation.dart';
import '../models/processing_unit.dart';
import '../models/processing_unit_user.dart';
import '../models/join_request.dart';
import '../services/api_service.dart';

class ProcessingUnitManagementProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State
  ProcessingUnit? _currentUnit;
  List<ProcessingUnitUser> _members = [];
  List<JoinRequest> _joinRequests = [];
  List<ProcessingUnit> _availableUnits = [];
  bool _isLoading = false;
  String? _error;
  int? _currentUserId; // Track current user ID for permission checks
  bool _membersLoaded = false; // Track if members have been loaded at least once

  // Getters
  ProcessingUnit? get currentUnit => _currentUnit;
  List<ProcessingUnitUser> get members => _members;
  List<JoinRequest> get joinRequests => _joinRequests; // All join requests
  List<JoinRequest> get pendingJoinRequests => 
      _joinRequests.where((r) => r.status == 'pending').toList();
  List<ProcessingUnit> get availableUnits => _availableUnits;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get currentUserId => _currentUserId;
  bool get membersLoaded => _membersLoaded;

  // Setter for current user ID
  void setCurrentUserId(int userId) {
    _currentUserId = userId;
    debugPrint('✅ [PROVIDER] Current user ID set to: $_currentUserId');
    notifyListeners();
  }

  // Check if current user is owner/manager
  bool canManageUsers([int? userId]) {
    // Use provided userId or fall back to stored current user ID
    final userIdToCheck = userId ?? _currentUserId;
    
    if (userIdToCheck == null || _members.isEmpty) return false;
    
    // Use where().firstOrNull pattern to safely check if member exists
    final member = _members.where((m) => m.userId == userIdToCheck).firstOrNull;
    if (member == null) return false;
    
    return member.isOwner || member.isManager;
  }

  // Create new processing unit
  Future<bool> createProcessingUnit(ProcessingUnit unit) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use standard DRF POST endpoint for processing units
      final response = await _apiService.post(
        '/processing-units/',
        data: unit.toJsonForCreate(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _currentUnit = ProcessingUnit.fromJson(response.data);
        await loadUnitMembers(_currentUnit!.id!);
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to create processing unit';
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

  // Load available units for joining
  Future<void> loadAvailableUnits({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = search != null && search.isNotEmpty
          ? {'search': search}
          : null;

      final response = await _apiService.get(
        '/processing-units/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List 
            ? response.data 
            : response.data['results'] ?? [];
        _availableUnits = data.map((json) => ProcessingUnit.fromJson(json)).toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Request to join processing unit
  Future<bool> requestJoinUnit({
    required int unitId,
    required String requestedRole,
    String? message,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/processing-units/$unitId/join-request/',
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

  // Load processing unit members
  Future<void> loadUnitMembers(int unitId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/processing-units/$unitId/users/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List 
            ? response.data 
            : response.data['results'] ?? [];
        _members = data.map((json) => ProcessingUnitUser.fromJson(json)).toList();
        _membersLoaded = true; // Mark that members have been loaded
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load join requests (for owners/managers)
  Future<void> loadJoinRequests(int unitId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Add timestamp to prevent caching and ensure fresh data
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await _apiService.get('/processing-units/$unitId/join-requests/?_t=$timestamp');

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

  // Invite user to processing unit
  Future<bool> inviteUser({
    required int unitId,
    required String email,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/processing-units/$unitId/invite-user/',
        data: {
          'email': email,
          'role': role,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadUnitMembers(unitId);
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
    required int unitId,
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
        '/processing-units/$unitId/users/$memberId/',
        data: requestData,
      );

      if (response.statusCode == 200) {
        await loadUnitMembers(unitId);
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

  // Remove member from unit
  Future<bool> removeMember({
    required int unitId,
    required int memberId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.delete(
        '/processing-units/$unitId/users/$memberId/',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await loadUnitMembers(unitId);
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

  // Suspend member
  Future<bool> suspendMember({
    required int unitId,
    required int memberId,
    required String reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/processing-units/$unitId/users/$memberId/suspend/',
        data: {'reason': reason},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadUnitMembers(unitId);
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to suspend member';
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

  // Activate/Reactivate member
  Future<bool> activateMember({
    required int unitId,
    required int memberId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/processing-units/$unitId/users/$memberId/activate/',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadUnitMembers(unitId);
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to activate member';
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
        if (_currentUnit != null) {
          await loadUnitMembers(_currentUnit!.id!);
          await loadJoinRequests(_currentUnit!.id!);
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
        if (_currentUnit != null) {
          await loadJoinRequests(_currentUnit!.id!);
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

  // Update processing unit details
  Future<bool> updateUnit(int unitId, Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.patch(
        '/processing-units/$unitId/',
        data: updates,
      );

      if (response.statusCode == 200) {
        _currentUnit = ProcessingUnit.fromJson(response.data);
        return true;
      } else {
        _error = response.data['detail'] ?? 'Failed to update unit';
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
    _currentUnit = null;
    _members = [];
    _joinRequests = [];
    _availableUnits = [];
    _error = null;
    notifyListeners();
  }
}
