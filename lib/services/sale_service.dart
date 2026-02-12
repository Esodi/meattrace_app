import 'package:dio/dio.dart';
import '../models/sale.dart';
import '../models/category_sales_summary.dart';
import 'dio_client.dart';
import '../utils/constants.dart';

class SaleService {
  static final SaleService _instance = SaleService._internal();
  final DioClient _dioClient = DioClient();

  factory SaleService() {
    return _instance;
  }

  SaleService._internal();

  /// Fetch sales with optional filters including date range and product name
  Future<List<Sale>> getSales({
    int? shop,
    String? ordering,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? productName,
    int? productId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (shop != null) queryParams['shop'] = shop;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }
      if (productName != null) queryParams['product_name'] = productName;
      if (productId != null) queryParams['product_id'] = productId;

      final response = await _dioClient.dio.get(
        '${Constants.baseUrl}/sales/',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data.map((json) => Sale.fromJson(json)).toList();
      } else if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List;
        return results.map((json) => Sale.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch sales: ${e.message}');
    }
  }

  /// Get single sale details
  Future<Sale> getSale(int id) async {
    try {
      final response = await _dioClient.dio.get(
        '${Constants.baseUrl}/sales/$id/',
      );
      return Sale.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Sale not found');
      }
      throw Exception('Failed to fetch sale: ${e.message}');
    }
  }

  /// Get aggregated sales summary for a product name/category
  Future<CategorySalesSummary> getCategorySalesSummary(
    String productName,
  ) async {
    try {
      final encodedName = Uri.encodeComponent(productName);
      final response = await _dioClient.dio.get(
        '${Constants.baseUrl}/sales/category-summary/$encodedName/',
      );
      return CategorySalesSummary.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Product not found');
      }
      throw Exception('Failed to fetch category summary: ${e.message}');
    }
  }

  /// Get public sale receipt by UUID (no auth required)
  Future<Map<String, dynamic>> getPublicReceipt(String receiptUuid) async {
    try {
      // Use a separate Dio instance without auth headers for public endpoint
      final publicDio = Dio(
        BaseOptions(
          baseUrl: Constants.baseUrl.replaceAll('/api/v2', ''),
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final response = await publicDio.get(
        '/api/v2/public/sale-receipt/$receiptUuid/',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Receipt not found');
      }
      throw Exception('Failed to fetch receipt: ${e.message}');
    }
  }

  /// Create new sale with items
  Future<Sale> createSale(Map<String, dynamic> saleData) async {
    try {
      print('🔄 [SaleService] Creating sale...');
      print('📤 [SaleService] Sending data: $saleData');

      final response = await _dioClient.dio.post(
        '${Constants.baseUrl}/sales/',
        data: saleData,
      );

      print(
        '✅ [SaleService] Sale created successfully: ${response.statusCode}',
      );
      print('📄 [SaleService] Response data: ${response.data}');
      return Sale.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ [SaleService] Sale creation failed');
      print('📊 [SaleService] Status Code: ${e.response?.statusCode}');
      print('📄 [SaleService] Response Data: ${e.response?.data}');
      print('🔍 [SaleService] Error Message: ${e.message}');

      // Create detailed error message
      String errorMessage = 'Failed to create sale';

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

  /// Delete a sale
  Future<void> deleteSale(int id) async {
    try {
      await _dioClient.dio.delete('${Constants.baseUrl}/sales/$id/');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Sale not found');
      }
      throw Exception('Failed to delete sale: ${e.message}');
    }
  }
}
