import 'package:dio/dio.dart';
import '../models/shop_receipt.dart';
import 'dio_client.dart';
import '../utils/constants.dart';

class ReceiptService {
  static final ReceiptService _instance = ReceiptService._internal();
  final DioClient _dioClient = DioClient();

  factory ReceiptService() {
    return _instance;
  }

  ReceiptService._internal();

  Future<List<ShopReceipt>> getReceipts({
    int? product,
    String? search,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (product != null) queryParams['product'] = product;
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await _dioClient.dio.get(
        Constants.receiptsEndpoint,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data.map((json) => ShopReceipt.fromJson(json)).toList();
      } else if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List;
        return results.map((json) => ShopReceipt.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch receipts: ${e.message}');
    }
  }

  Future<ShopReceipt> getReceipt(int id) async {
    try {
      final response = await _dioClient.dio.get('${Constants.receiptsEndpoint}$id/');
      return ShopReceipt.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Receipt not found');
      }
      throw Exception('Failed to fetch receipt: ${e.message}');
    }
  }

  Future<ShopReceipt> createReceipt(ShopReceipt receipt) async {
    try {
      final response = await _dioClient.dio.post(
        Constants.receiptsEndpoint,
        data: receipt.toJson()..remove('id'),
      );
      return ShopReceipt.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create receipt: ${e.message}');
    }
  }

  Future<ShopReceipt> updateReceipt(ShopReceipt receipt) async {
    try {
      final response = await _dioClient.dio.put(
        '${Constants.receiptsEndpoint}${receipt.id}/',
        data: receipt.toJson(),
      );
      return ShopReceipt.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update receipt: ${e.message}');
    }
  }

  Future<void> deleteReceipt(int id) async {
    try {
      await _dioClient.dio.delete('${Constants.receiptsEndpoint}$id/');
    } on DioException catch (e) {
      throw Exception('Failed to delete receipt: ${e.message}');
    }
  }
}