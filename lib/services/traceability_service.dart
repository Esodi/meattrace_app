import 'package:dio/dio.dart';
import '../models/traceability_entry.dart';
import 'dio_client.dart';
import '../utils/constants.dart';

class TraceabilityService {
  static final TraceabilityService _instance = TraceabilityService._internal();
  final DioClient _dioClient = DioClient();

  factory TraceabilityService() {
    return _instance;
  }

  TraceabilityService._internal();

  /// Fetch traceability report for the processing unit
  Future<List<TraceabilityEntry>> getTraceabilityReport({
    String? species,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (species != null && species.isNotEmpty && species != 'all') {
        queryParams['species'] = species;
      }
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String();
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dioClient.dio.get(
        '${Constants.baseUrl}/processing-unit/traceability/',
        queryParameters: queryParams,
      );

      final data = response.data;
      List<dynamic> items = [];

      if (data is Map<String, dynamic>) {
        if (data.containsKey('traceability') &&
            data['traceability'] is Map &&
            data['traceability'].containsKey('items')) {
          items = data['traceability']['items'] as List;
        } else if (data.containsKey('results')) {
          items = data['results'] as List;
        }
      } else if (data is List) {
        items = data;
      }

      return items.map((json) => TraceabilityEntry.fromJson(json)).toList();
    } on DioException catch (e) {
      print('❌ [TraceabilityService] Error fetching report: ${e.message}');
      throw Exception('Failed to fetch traceability report: ${e.message}');
    }
  }
}
