import 'package:dio/dio.dart';
import '../models/meat_trace.dart';
import '../models/product.dart';
import '../models/animal.dart';
import '../models/production_stats.dart';
import '../models/order.dart';
import 'dio_client.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final DioClient _dioClient = DioClient();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Generic HTTP methods for flexibility
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dioClient.dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dioClient.dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dioClient.dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await _dioClient.dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dioClient.dio.delete(path);
  }

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

  Future<String> regenerateProductQrCode(String productId) async {
    try {
      final response = await _dioClient.dio.post('/products/$productId/regenerate_qr/');
      return response.data['qr_code_url'];
    } on DioException catch (e) {
      throw Exception('Failed to regenerate QR code: ${e.message}');
    }
  }

  Future<Product> fetchProduct(String productId) async {
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

  Future<Map<String, dynamic>> fetchProcessingPipeline() async {
    try {
      final response = await _dioClient.dio.get('/processing-pipeline/');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to fetch processing pipeline: ${e.message}');
    }
  }

  Future<List<Order>> fetchOrders() async {
    try {
      final response = await _dioClient.dio.get('/orders/');
      final data = response.data;
      if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List;
        return results.map((json) => Order.fromJson(json)).toList();
      } else if (data is List) {
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      print('🔍 [ApiService] DioException in fetchOrders: ${e.message}');
      print('🔍 [ApiService] Response status: ${e.response?.statusCode}');
      print('🔍 [ApiService] Response data: ${e.response?.data}');
      // Handle null message case
      final errorMessage = e.message ?? 'Unknown network error';
      throw Exception('Failed to fetch orders: $errorMessage');
    } catch (e) {
      print('🔍 [ApiService] General exception in fetchOrders: $e');
      throw Exception('Failed to fetch orders: $e');
    }
  }
}








