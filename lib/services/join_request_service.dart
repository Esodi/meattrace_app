import 'package:dio/dio.dart';
import '../models/join_request.dart';
import 'dio_client.dart';

class JoinRequestService {
  static final JoinRequestService _instance = JoinRequestService._internal();
  final DioClient _dioClient = DioClient();

  factory JoinRequestService() {
    return _instance;
  }

  JoinRequestService._internal();

  Future<List<JoinRequest>> fetchUserJoinRequests() async {
    try {
      final response = await _dioClient.dio.get('/join-requests/');
      final data = response.data;
      if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List;
        return results.map((json) => JoinRequest.fromJson(json)).toList();
      } else if (data is List) {
        return data.map((json) => JoinRequest.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch join requests: ${e.message}');
    }
  }

  Future<List<JoinRequest>> fetchUnitJoinRequests(String unitType, int unitId) async {
    try {
      final response = await _dioClient.dio.get('/$unitType/$unitId/join-requests/');
      final data = response.data;
      if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List;
        return results.map((json) => JoinRequest.fromJson(json)).toList();
      } else if (data is List) {
        return data.map((json) => JoinRequest.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch unit join requests: ${e.message}');
    }
  }

  Future<JoinRequest> createJoinRequest(String unitType, int unitId, String requestedRole, {
    String? message,
    String? qualifications,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/$unitType/$unitId/join-request/',
        data: {
          'requested_role': requestedRole,
          'message': message,
          'qualifications': qualifications,
        },
      );
      return JoinRequest.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create join request: ${e.message}');
    }
  }

  Future<JoinRequest> reviewJoinRequest(int requestId, String status, String? responseMessage) async {
    try {
      final response = await _dioClient.dio.patch(
        '/join-requests/$requestId/',
        data: {
          'status': status,
          'response_message': responseMessage,
        },
      );
      return JoinRequest.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to review join request: ${e.message}');
    }
  }

  Future<JoinRequest> getJoinRequest(int requestId) async {
    try {
      final response = await _dioClient.dio.get('/join-requests/$requestId/');
      return JoinRequest.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to get join request: ${e.message}');
    }
  }

  Future<JoinRequest> submitJoinRequest(JoinRequest joinRequest) async {
    String unitType;
    int unitId;

    if (joinRequest.requestType == 'processing_unit') {
      unitType = 'processing-units';
      unitId = joinRequest.processingUnit!;
    } else if (joinRequest.requestType == 'shop') {
      unitType = 'shops';
      unitId = joinRequest.shop!;
    } else {
      throw Exception('Invalid request type: ${joinRequest.requestType}');
    }

    return createJoinRequest(unitType, unitId, joinRequest.requestedRole,
        message: joinRequest.message, qualifications: joinRequest.qualifications);
  }

  Future<void> cancelJoinRequest(int requestId) async {
    try {
      await _dioClient.dio.delete('/join-requests/$requestId/');
    } on DioException catch (e) {
      throw Exception('Failed to cancel join request: ${e.message}');
    }
  }

  Future<JoinRequest?> getCurrentUserJoinRequest() async {
    try {
      final requests = await fetchUserJoinRequests();
      // Return the first pending or rejected request
      if (requests.isEmpty) return null;
      
      for (var request in requests) {
        if (request.status == 'pending' || request.status == 'rejected') {
          return request;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}