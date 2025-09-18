import 'package:dio/dio.dart';
import '../models/product_category.dart';
import 'dio_client.dart';

class ProductCategoryService {
  static final ProductCategoryService _instance =
      ProductCategoryService._internal();
  final DioClient _dioClient = DioClient();

  factory ProductCategoryService() {
    return _instance;
  }

  ProductCategoryService._internal();

  Future<List<ProductCategory>> fetchAllCategories() async {
    try {
      final response = await _dioClient.dio.get('/categories/');
      final data = response.data;
      if (data is List) {
        return data.map((json) => ProductCategory.fromJson(json)).toList();
      } else if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List;
        return results.map((json) => ProductCategory.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch categories: ${e.message}');
    }
  }

  Future<ProductCategory> addCategory(ProductCategory category) async {
    try {
      final response = await _dioClient.dio.post(
        '/categories/',
        data: category.toJson()..remove('id'),
      );
      return ProductCategory.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to add category: ${e.message}');
    }
  }
}
