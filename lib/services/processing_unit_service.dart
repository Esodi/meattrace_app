import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../models/processing_unit.dart';
import '../utils/constants.dart';
import 'dio_client.dart';

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
    } catch (e) {
      developer.log('ProcessingUnitService: Error creating processing unit: $e');
      developer.log('ProcessingUnitService: Error type: ${e.runtimeType}');
      if (e is DioException) {
        developer.log('ProcessingUnitService: DioException details:');
        developer.log('  - Status code: ${e.response?.statusCode}');
        developer.log('  - Response data: ${e.response?.data}');
        developer.log('  - Request URL: ${e.requestOptions.uri}');
        developer.log('  - Request method: ${e.requestOptions.method}');
        developer.log('  - Request headers: ${e.requestOptions.headers}');
      }
      throw Exception('Failed to create processing unit: $e');
    }
  }

  Future<List<ProcessingUnit>> getProcessingUnits() async {
    try {
      final response = await _dioClient.dio.get(
        Constants.processingUnitsEndpoint,
      );

      final data = response.data;
      if (data is Map && data.containsKey('results')) {
        return List<ProcessingUnit>.from(
          data['results'].map((json) => ProcessingUnit.fromJson(json))
        );
      } else if (data is List) {
        return List<ProcessingUnit>.from(
          data.map((json) => ProcessingUnit.fromJson(json))
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Failed to fetch processing units: $e');
    }
  }

  Future<ProcessingUnit> getProcessingUnit(int id) async {
    try {
      final response = await _dioClient.dio.get('${Constants.processingUnitsEndpoint}$id/');
      return ProcessingUnit.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        throw Exception('Processing unit not found');
      }
      throw Exception('Failed to fetch processing unit: $e');
    }
  }

  Future<ProcessingUnit> updateProcessingUnit(ProcessingUnit processingUnit) async {
    try {
      final response = await _dioClient.dio.put(
        '${Constants.processingUnitsEndpoint}${processingUnit.id}/',
        data: processingUnit.toJson(),
      );
      return ProcessingUnit.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update processing unit: $e');
    }
  }

  Future<void> deleteProcessingUnit(int id) async {
    try {
      await _dioClient.dio.delete('${Constants.processingUnitsEndpoint}$id/');
    } catch (e) {
      throw Exception('Failed to delete processing unit: $e');
    }
  }
}