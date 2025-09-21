import 'package:dio/dio.dart';
import '../models/product.dart';
import 'dio_client.dart';
import '../utils/constants.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  final DioClient _dioClient = DioClient();

  factory ProductService() {
    return _instance;
  }

  ProductService._internal();

  Future<List<Product>> getProducts({
    String? productType,
    int? animal,
    String? search,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (productType != null) queryParams['product_type'] = productType;
      if (animal != null) queryParams['animal'] = animal;
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await _dioClient.dio.get(
        Constants.productsEndpoint,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data.map((json) => Product.fromMap(json)).toList();
      } else if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List;
        return results.map((json) => Product.fromMap(json)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch products: ${e.message}');
    }
  }

  Future<Product> getProduct(int id) async {
    try {
      final response = await _dioClient.dio.get('${Constants.productsEndpoint}$id/');
      return Product.fromMap(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Product not found');
      }
      throw Exception('Failed to fetch product: ${e.message}');
    }
  }

  Future<Product> createProduct(Product product) async {
    try {
      print('🔄 [ProductService] Creating product...');
      print('📤 [ProductService] Sending data: ${product.toMapForCreate()}');

      final response = await _dioClient.dio.post(
        Constants.productsEndpoint,
        data: product.toMapForCreate(),
      );

      print('✅ [ProductService] Product created successfully: ${response.statusCode}');
      print('📄 [ProductService] Response data: ${response.data}');
      return Product.fromMap(response.data);
    } on DioException catch (e) {
      print('❌ [ProductService] Product creation failed');
      print('📊 [ProductService] Status Code: ${e.response?.statusCode}');
      print('📄 [ProductService] Response Data: ${e.response?.data}');
      print('🔍 [ProductService] Error Message: ${e.message}');

      // Create detailed error message
      String errorMessage = 'Failed to create product';

      if (e.response?.statusCode == 400) {
        errorMessage += ' (Validation Error)';
        if (e.response?.data is Map) {
          final errorData = e.response!.data as Map;
          if (errorData.containsKey('detail')) {
            errorMessage += ': ${errorData['detail']}';
          } else {
            // Handle field-specific errors
            final fieldErrors = <String>[];
            errorData.forEach((field, errors) {
              if (errors is List) {
                fieldErrors.add('$field: ${errors.join(', ')}');
              } else {
                fieldErrors.add('$field: $errors');
              }
            });
            if (fieldErrors.isNotEmpty) {
              errorMessage += ': ${fieldErrors.join('; ')}';
            }
          }
        }
      } else if (e.response?.statusCode == 401) {
        errorMessage += ' (Authentication Failed)';
      } else if (e.response?.statusCode == 403) {
        errorMessage += ' (Permission Denied)';
      } else if (e.response?.statusCode == 404) {
        errorMessage += ' (Endpoint Not Found)';
      } else if (e.response?.statusCode == 500) {
        errorMessage += ' (Server Error)';
      }

      throw Exception(errorMessage);
    }
  }

  Future<Product> updateProduct(Product product) async {
    try {
      final response = await _dioClient.dio.put(
        '${Constants.productsEndpoint}${product.id}/',
        data: product.toMap(),
      );
      return Product.fromMap(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update product: ${e.message}');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _dioClient.dio.delete('${Constants.productsEndpoint}$id/');
    } on DioException catch (e) {
      throw Exception('Failed to delete product: ${e.message}');
    }
  }
}
