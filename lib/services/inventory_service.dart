import 'package:dio/dio.dart';
import '../models/inventory.dart';
import 'dio_client.dart';
import '../utils/constants.dart';

class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  final DioClient _dioClient = DioClient();

  factory InventoryService() {
    return _instance;
  }

  InventoryService._internal();

  Future<List<Inventory>> getInventory({
    int? shopId,
    int? productId,
    String? search,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (shopId != null) queryParams['shop'] = shopId;
      if (productId != null) queryParams['product'] = productId;
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await _dioClient.dio.get(
        Constants.inventoryEndpoint,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data.map((json) => Inventory.fromMap(json)).toList();
      } else if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List;
        return results.map((json) => Inventory.fromMap(json)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch inventory: ${e.message}');
    }
  }

  Future<Inventory> getInventoryItem(int id) async {
    try {
      final response = await _dioClient.dio.get('${Constants.inventoryEndpoint}$id/');
      return Inventory.fromMap(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Inventory item not found');
      }
      throw Exception('Failed to fetch inventory item: ${e.message}');
    }
  }

  Future<Inventory> createInventoryItem(Inventory inventory) async {
    try {
      final response = await _dioClient.dio.post(
        Constants.inventoryEndpoint,
        data: inventory.toMapForCreate(),
      );
      return Inventory.fromMap(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create inventory item: ${e.message}');
    }
  }

  Future<Inventory> updateInventoryItem(Inventory inventory) async {
    try {
      print('🔍 [InventoryService] Making PUT request to ${Constants.inventoryEndpoint}${inventory.id}/ with data: ${inventory.toMap()}');
      final response = await _dioClient.dio.put(
        '${Constants.inventoryEndpoint}${inventory.id}/',
        data: inventory.toMap(),
      );
      print('🔍 [InventoryService] PUT response status: ${response.statusCode}, data: ${response.data}');
      return Inventory.fromMap(response.data);
    } on DioException catch (e) {
      print('🔍 [InventoryService] PUT request failed: ${e.message}, response: ${e.response?.data}');
      throw Exception('Failed to update inventory item: ${e.message}');
    }
  }

  Future<void> deleteInventoryItem(int id) async {
    try {
      await _dioClient.dio.delete('${Constants.inventoryEndpoint}$id/');
    } on DioException catch (e) {
      throw Exception('Failed to delete inventory item: ${e.message}');
    }
  }

  Future<List<Inventory>> getLowStockItems() async {
    try {
      final response = await _dioClient.dio.get('${Constants.inventoryEndpoint}low_stock/');
      final data = response.data;
      if (data is List) {
        return data.map((json) => Inventory.fromMap(json)).toList();
      } else if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List;
        return results.map((json) => Inventory.fromMap(json)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch low stock items: ${e.message}');
    }
  }

  Future<Inventory> adjustStock(int inventoryId, double adjustment, String reason) async {
    try {
      final response = await _dioClient.dio.patch(
        '${Constants.inventoryEndpoint}$inventoryId/adjust_stock/',
        data: {
          'adjustment': adjustment,
          'reason': reason,
        },
      );
      return Inventory.fromMap(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to adjust stock: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final inventory = await getInventory();
      final lowStockItems = await getLowStockItems();

      double totalValue = 0.0;
      int totalItems = inventory.length;
      int lowStockCount = lowStockItems.length;

      for (var item in inventory) {
        if (item.productDetails != null) {
          totalValue += item.weight * item.productDetails!.price;
        }
      }

      return {
        'total_items': totalItems,
        'total_value': totalValue,
        'low_stock_count': lowStockCount,
        'low_stock_items': lowStockItems,
        'healthy_stock_count': totalItems - lowStockCount,
      };
    } catch (e) {
      throw Exception('Failed to get inventory stats: $e');
    }
  }
}






