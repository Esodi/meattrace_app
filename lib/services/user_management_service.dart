import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import 'dio_client.dart';
import '../utils/constants.dart';

class UserManagementService {
  static final UserManagementService _instance = UserManagementService._internal();
  final DioClient _dioClient = DioClient();

  factory UserManagementService() {
    return _instance;
  }

  UserManagementService._internal();

  Future<List<User>> getUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? role,
  }) async {
    try {
      debugPrint('🔍 Fetching users: page=$page, search=$search');

      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (status != null) {
        queryParams['status'] = status;
      }

      if (role != null) {
        queryParams['role'] = role;
      }

      final response = await _dioClient.dio.get(
        Constants.usersEndpoint,
        queryParameters: queryParams,
      );

      debugPrint('✅ Users fetched successfully: ${response.data.length} users');

      final List<dynamic> usersJson = response.data['results'] ?? response.data;
      return usersJson.map((json) => User.fromJson(json)).toList();
    } on DioException catch (e) {
      debugPrint('❌ Failed to fetch users: ${e.message}');
      throw Exception('Failed to load users: ${e.message}');
    }
  }

  Future<bool> inviteUser({
    required String email,
    required String role,
    String? message,
  }) async {
    try {
      debugPrint('📧 Inviting user: $email with role: $role');

      final response = await _dioClient.dio.post(
        Constants.userInvitationEndpoint,
        data: {
          'email': email,
          'role': role,
          if (message != null) 'message': message,
        },
      );

      debugPrint('✅ User invitation sent successfully');
      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('❌ Failed to invite user: ${e.message}');
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('email')) {
          throw Exception(errorData['email'][0]);
        }
      }
      throw Exception('Failed to invite user: ${e.message}');
    }
  }

  Future<bool> suspendUser(int userId, String reason) async {
    try {
      debugPrint('🚫 Suspending user: $userId, reason: $reason');

      final response = await _dioClient.dio.post(
        '${Constants.usersEndpoint}$userId/suspend/',
        data: {
          'reason': reason,
        },
      );

      debugPrint('✅ User suspended successfully');
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('❌ Failed to suspend user: ${e.message}');
      throw Exception('Failed to suspend user: ${e.message}');
    }
  }

  Future<bool> reactivateUser(int userId) async {
    try {
      debugPrint('✅ Reactivating user: $userId');

      final response = await _dioClient.dio.post(
        '${Constants.usersEndpoint}$userId/reactivate/',
      );

      debugPrint('✅ User reactivated successfully');
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('❌ Failed to reactivate user: ${e.message}');
      throw Exception('Failed to reactivate user: ${e.message}');
    }
  }

  Future<bool> removeUser(int userId) async {
    try {
      debugPrint('🗑️ Removing user: $userId');

      final response = await _dioClient.dio.delete(
        '${Constants.usersEndpoint}$userId/',
      );

      debugPrint('✅ User removed successfully');
      return response.statusCode == 204;
    } on DioException catch (e) {
      debugPrint('❌ Failed to remove user: ${e.message}');
      throw Exception('Failed to remove user: ${e.message}');
    }
  }

  Future<bool> updateUserRole(int userId, String newRole) async {
    try {
      debugPrint('🔄 Updating user role: $userId to $newRole');

      final response = await _dioClient.dio.patch(
        '${Constants.usersEndpoint}$userId/',
        data: {
          'role': newRole,
        },
      );

      debugPrint('✅ User role updated successfully');
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('❌ Failed to update user role: ${e.message}');
      throw Exception('Failed to update user role: ${e.message}');
    }
  }

  Future<User> getUserDetails(int userId) async {
    try {
      debugPrint('👤 Fetching user details: $userId');

      final response = await _dioClient.dio.get(
        '${Constants.usersEndpoint}$userId/',
      );

      debugPrint('✅ User details fetched successfully');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ Failed to fetch user details: ${e.message}');
      throw Exception('Failed to load user details: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserAuditLogs({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? action,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      debugPrint('📋 Fetching audit logs for user: $userId');

      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (userId != null) {
        queryParams['user_id'] = userId;
      }

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }

      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      if (action != null) {
        queryParams['action'] = action;
      }

      final response = await _dioClient.dio.get(
        Constants.userAuditLogsEndpoint,
        queryParameters: queryParams,
      );

      debugPrint('✅ Audit logs fetched successfully');
      return List<Map<String, dynamic>>.from(response.data['results'] ?? response.data);
    } on DioException catch (e) {
      debugPrint('❌ Failed to fetch audit logs: ${e.message}');
      throw Exception('Failed to load audit logs: ${e.message}');
    }
  }
}