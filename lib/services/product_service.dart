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
      int? processingUnit,
      String? search,
      String? ordering,
      bool? pendingReceipt,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (productType != null) queryParams['product_type'] = productType;
      if (animal != null) queryParams['animal'] = animal;
      if (processingUnit != null) queryParams['processing_unit'] = processingUnit;
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (pendingReceipt != null && pendingReceipt) queryParams['pending_receipt'] = 'true';

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
      Response response;
      if (product.quantity == 0) {
        // Partial update for price only (used in inventory management)
        response = await _dioClient.dio.patch(
          '${Constants.productsEndpoint}${product.id}/',
          data: {'price': product.price},
        );
      } else {
        // Full update
        response = await _dioClient.dio.put(
          '${Constants.productsEndpoint}${product.id}/',
          data: product.toMap(),
        );
      }
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

  Future<Map<String, dynamic>> transferProducts(
    List<int> productIds, 
    int shopId, 
    {Map<int, double>? productQuantities}
  ) async {
    try {
      // Prepare transfer data with quantities
      List<Map<String, dynamic>> transfers = productIds.map((productId) {
        final Map<String, dynamic> transfer = {'product_id': productId};
        if (productQuantities != null && productQuantities.containsKey(productId)) {
          transfer['quantity'] = productQuantities[productId]!;
        }
        return transfer;
      }).toList();

      final response = await _dioClient.dio.post(
        '${Constants.productsEndpoint}transfer/',
        data: {
          'transfers': transfers,
          'shop_id': shopId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to transfer products: ${e.message}');
    }
  }

  Future<List<Product>> getTransferredProducts() async {
    try {
      final response = await _dioClient.dio.get('${Constants.productsEndpoint}transferred_products/');
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
      throw Exception('Failed to fetch transferred products: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> receiveProducts({
    List<Map<String, dynamic>>? receives,
    List<Map<String, dynamic>>? rejections,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '${Constants.productsEndpoint}receive_products/',
        data: {
          if (receives != null && receives.isNotEmpty) 'receives': receives,
          if (rejections != null && rejections.isNotEmpty) 'rejections': rejections,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to receive products: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getShops() async {
    try {
      final response = await _dioClient.dio.get(Constants.shopsEndpoint);
      final data = response.data;
      
      print('[PRODUCT_SERVICE] getShops response type: ${data.runtimeType}');
      print('[PRODUCT_SERVICE] getShops response data: $data');
      
      // Handle both List and Map with 'results' key
      if (data is List) {
        print('[PRODUCT_SERVICE] Response is List, converting to List<Map>');
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('results')) {
        print('[PRODUCT_SERVICE] Response is Map with results key');
        return List<Map<String, dynamic>>.from(data['results']);
      } else {
        print('[PRODUCT_SERVICE] Unexpected response format: $data');
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      print('[PRODUCT_SERVICE] Error fetching shops: ${e.message}');
      throw Exception('Failed to fetch shops: ${e.message}');
    }
  }

  Future<String> regenerateQrCode(String productId) async {
    try {
      final response = await _dioClient.dio.post(
        '${Constants.productsEndpoint}$productId/regenerate_qr/',
      );
      final qrCodeUrl = response.data['qr_code_url'];
      if (qrCodeUrl == null || qrCodeUrl is! String) {
        throw Exception('Invalid QR code URL in response');
      }
      return qrCodeUrl;
    } on DioException catch (e) {
      throw Exception('Failed to regenerate QR code: ${e.message}');
    }
  }
}








