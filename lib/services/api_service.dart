import 'package:dio/dio.dart';
import '../models/meat_trace.dart';
import '../models/product.dart';
import '../models/production_stats.dart';
import 'dio_client.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final DioClient _dioClient = DioClient();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  Future<List<MeatTrace>> fetchMeatTraces({
    String? search,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null) queryParams['search'] = search;
      if (status != null) queryParams['status'] = status;

      final response = await _dioClient.dio.get(
        '/meattrace/',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List;
        return results.map((json) => MeatTrace.fromJson(json)).toList();
      } else if (data is List) {
        return data.map((json) => MeatTrace.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch meat traces: ${e.message}');
    }
  }

  Future<MeatTrace> createMeatTrace(MeatTrace meatTrace) async {
    try {
      final response = await _dioClient.dio.post(
        '/meattrace/',
        data: meatTrace.toJson()..remove('id'),
      );
      return MeatTrace.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create meat trace: ${e.message}');
    }
  }

  Future<MeatTrace> updateMeatTrace(MeatTrace meatTrace) async {
    try {
      final response = await _dioClient.dio.put(
        '/meattrace/${meatTrace.id}/',
        data: meatTrace.toJson(),
      );
      return MeatTrace.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update meat trace: ${e.message}');
    }
  }

  Future<void> deleteMeatTrace(int id) async {
    try {
      await _dioClient.dio.delete('/meattrace/$id/');
    } on DioException catch (e) {
      throw Exception('Failed to delete meat trace: ${e.message}');
    }
  }

  Future<Product> fetchProduct(int productId) async {
    try {
      final response = await _dioClient.dio.get('/products/$productId/');
      return Product.fromMap(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Product not found');
      }
      throw Exception('Failed to fetch product: ${e.message}');
    }
  }

  Future<ProductionStats> fetchProductionStats() async {
    try {
      final response = await _dioClient.dio.get('/production-stats/');
      return ProductionStats.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch production stats: ${e.message}');
    }
  }
}
