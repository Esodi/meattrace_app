import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/processing_unit.dart';
import '../utils/constants.dart';
import 'dio_client.dart';
import 'api_exception.dart';

class ProcessingUnitService {
  static final ProcessingUnitService _instance = ProcessingUnitService._internal();
  final DioClient _dioClient = DioClient();

  factory ProcessingUnitService() {
    return _instance;
  }

  ProcessingUnitService._internal();

  Future<ProcessingUnit> createProcessingUnit(ProcessingUnit processingUnit) async {
    developer.log('ProcessingUnitService: Starting createProcessingUnit for "${processingUnit.name}"');
    developer.log('ProcessingUnitService: Endpoint: ${Constants.processingUnitsEndpoint}');
    developer.log('ProcessingUnitService: Request data: ${processingUnit.toJsonForCreate()}');

    try {
      final response = await _dioClient.dio.post(
        Constants.processingUnitsEndpoint,
        data: processingUnit.toJsonForCreate(),
      );

      developer.log('ProcessingUnitService: Response status: ${response.statusCode}');
      developer.log('ProcessingUnitService: Response data: ${response.data}');

      final createdUnit = ProcessingUnit.fromJson(response.data);
      developer.log('ProcessingUnitService: Successfully created processing unit with ID: ${createdUnit.id}');

      return createdUnit;
    } on DioException catch (e) {
      developer.log('ProcessingUnitService: Error creating processing unit: $e');
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<ProcessingUnit>> getProcessingUnits() async {
    try {
      debugPrint('[PROCESSING_UNIT_SERVICE] Fetching processing units from: ${Constants.processingUnitsEndpoint}');
      final response = await _dioClient.dio.get(
        Constants.processingUnitsEndpoint,
      );

      debugPrint('[PROCESSING_UNIT_SERVICE] Response status: ${response.statusCode}');
      debugPrint('[PROCESSING_UNIT_SERVICE] Response data type: ${response.data.runtimeType}');
      debugPrint('[PROCESSING_UNIT_SERVICE] Response data: ${response.data}');

      final data = response.data;
      List<ProcessingUnit> units = [];

      if (data is Map && data.containsKey('results')) {
        debugPrint('[PROCESSING_UNIT_SERVICE] Response is Map with results key');
        units = List<ProcessingUnit>.from(
          data['results'].map((json) => ProcessingUnit.fromJson(json))
        );
      } else if (data is List) {
        debugPrint('[PROCESSING_UNIT_SERVICE] Response is List');
        units = List<ProcessingUnit>.from(
          data.map((json) => ProcessingUnit.fromJson(json))
        );
      } else {
        debugPrint('[PROCESSING_UNIT_SERVICE] Unexpected response format: ${data.runtimeType}');
        throw Exception('Unexpected response format');
      }

      debugPrint('[PROCESSING_UNIT_SERVICE] Successfully parsed ${units.length} processing units');
      for (var unit in units) {
        debugPrint('[PROCESSING_UNIT_SERVICE] Unit: ${unit.name} (ID: ${unit.id})');
      }

      return units;
    } on DioException catch (e) {
      debugPrint('[PROCESSING_UNIT_SERVICE] DioException: ${e.type} - ${e.message}');
      if (e.response != null) {
        debugPrint('[PROCESSING_UNIT_SERVICE] Response status: ${e.response?.statusCode}');
        debugPrint('[PROCESSING_UNIT_SERVICE] Response data: ${e.response?.data}');
      }
      throw ApiException.fromDioException(e);
    }
  }

  /// Fetch processing units for registration (public endpoint, no auth required)
  Future<List<ProcessingUnit>> getPublicProcessingUnits() async {
    try {
      final url = '${Constants.baseUrl}/public/processing-units/';
      debugPrint('[PROCESSING_UNIT_SERVICE] Fetching public processing units from: $url');
      
      // Create a temporary Dio instance without authentication
      // Don't set baseUrl to avoid double path issue
      final publicDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',  // Force JSON response, not HTML
          },
        ),
      );

      final response = await publicDio.get(url);

      debugPrint('[PROCESSING_UNIT_SERVICE] Public response status: ${response.statusCode}');
      debugPrint('[PROCESSING_UNIT_SERVICE] Public response data type: ${response.data.runtimeType}');
      
      // Check if we got HTML instead of JSON
      if (response.data is String) {
        debugPrint('[PROCESSING_UNIT_SERVICE] ERROR: Received HTML response instead of JSON');
        debugPrint('[PROCESSING_UNIT_SERVICE] Response preview: ${(response.data as String).substring(0, 200)}...');
        throw Exception('Server returned HTML instead of JSON. The endpoint may not exist.');
      }
      
      debugPrint('[PROCESSING_UNIT_SERVICE] Public response data: ${response.data}');

      final data = response.data;
      List<ProcessingUnit> units = [];

      if (data is Map && data.containsKey('results')) {
        units = List<ProcessingUnit>.from(
          data['results'].map((json) => ProcessingUnit.fromJson(json))
        );
      } else if (data is List) {
        units = List<ProcessingUnit>.from(
          data.map((json) => ProcessingUnit.fromJson(json))
        );
      } else {
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }

      debugPrint('[PROCESSING_UNIT_SERVICE] Successfully fetched ${units.length} public processing units');
      return units;
    } on DioException catch (e) {
      debugPrint('[PROCESSING_UNIT_SERVICE] Public fetch failed: ${e.type} - ${e.message}');
      if (e.response != null) {
        debugPrint('[PROCESSING_UNIT_SERVICE] Response status: ${e.response?.statusCode}');
        debugPrint('[PROCESSING_UNIT_SERVICE] Response data type: ${e.response?.data.runtimeType}');
        if (e.response?.data is String) {
          debugPrint('[PROCESSING_UNIT_SERVICE] HTML Response (first 500 chars): ${(e.response?.data as String).substring(0, 500)}');
        } else {
          debugPrint('[PROCESSING_UNIT_SERVICE] Response data: ${e.response?.data}');
        }
      }
      throw ApiException.fromDioException(e);
    } catch (e) {
      debugPrint('[PROCESSING_UNIT_SERVICE] Unexpected error: $e');
      rethrow;
    }
  }

  Future<ProcessingUnit> getProcessingUnit(int id) async {
    try {
      final response = await _dioClient.dio.get('${Constants.processingUnitsEndpoint}$id/');
      return ProcessingUnit.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProcessingUnit> updateProcessingUnit(ProcessingUnit processingUnit) async {
    try {
      final response = await _dioClient.dio.put(
        '${Constants.processingUnitsEndpoint}${processingUnit.id}/',
        data: processingUnit.toJson(),
      );
      return ProcessingUnit.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteProcessingUnit(int id) async {
    try {
      await _dioClient.dio.delete('${Constants.processingUnitsEndpoint}$id/');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}