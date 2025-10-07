import 'package:dio/dio.dart';
import 'dio_client.dart';

class ApiTestService {
  static final ApiTestService _instance = ApiTestService._internal();
  final DioClient _dioClient = DioClient();

  factory ApiTestService() {
    return _instance;
  }

  ApiTestService._internal();

  /// Test basic connectivity to the API server
  Future<bool> testConnectivity() async {
    try {
      final response = await _dioClient.dio.get('/health/');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('API connectivity test failed: ${e.message}');
      return false;
    }
  }

  /// Test fetching meat traces endpoint
  Future<bool> testMeatTracesEndpoint() async {
    try {
      final response = await _dioClient.dio.get('/meattrace/');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Meat traces endpoint test failed: ${e.message}');
      return false;
    }
  }

  /// Test fetching animals endpoint
  Future<bool> testAnimalsEndpoint() async {
    try {
      final response = await _dioClient.dio.get('/animals/');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Animals endpoint test failed: ${e.message}');
      return false;
    }
  }

  /// Test fetching products endpoint
  Future<bool> testProductsEndpoint() async {
    try {
      final response = await _dioClient.dio.get('/products/');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Products endpoint test failed: ${e.message}');
      return false;
    }
  }

  /// Test fetching categories endpoint
  Future<bool> testCategoriesEndpoint() async {
    try {
      final response = await _dioClient.dio.get('/categories/');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Categories endpoint test failed: ${e.message}');
      return false;
    }
  }

  /// Run all API tests
  Future<Map<String, bool>> runAllTests() async {
    final results = <String, bool>{};
    
    print('Running API connectivity tests...');
    
    results['connectivity'] = await testConnectivity();
    results['meattrace'] = await testMeatTracesEndpoint();
    results['animals'] = await testAnimalsEndpoint();
    results['products'] = await testProductsEndpoint();
    results['categories'] = await testCategoriesEndpoint();
    
    print('API Test Results:');
    results.forEach((test, passed) {
      print('  $test: ${passed ? "PASSED" : "FAILED"}');
    });
    
    return results;
  }

  /// Get API server info
  Future<Map<String, dynamic>?> getServerInfo() async {
    try {
      final response = await _dioClient.dio.get('/info/');
      return response.data;
    } on DioException catch (e) {
      print('Failed to get server info: ${e.message}');
      return null;
    }
  }
}







