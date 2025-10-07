import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/inventory.dart';
import '../services/inventory_service.dart';
import '../services/database_helper.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryService _inventoryService = InventoryService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Inventory> _inventory = [];
  bool _isLoading = false;
  String? _error;
  SharedPreferences? _prefs;

  List<Inventory> get inventory => _inventory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Inventory> get lowStockItems =>
      _inventory.where((item) => item.isLowStock).toList();

  int get totalItems => _inventory.length;
  int get lowStockCount => lowStockItems.length;
  int get healthyStockCount => totalItems - lowStockCount;

  double get totalValue {
    double value = 0.0;
    for (var item in _inventory) {
      if (item.productDetails != null) {
        value += item.quantity * item.productDetails!.price;
      }
    }
    return value;
  }

  InventoryProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    try {
      _inventory = await _dbHelper.getInventory();
      notifyListeners();
    } catch (e) {
      // If database fails, try shared preferences as fallback
      if (_prefs != null) {
        final cached = _prefs!.getString('inventory');
        if (cached != null) {
          try {
            final data = json.decode(cached) as List;
            _inventory = data.map((json) => Inventory.fromMap(json)).toList();
            notifyListeners();
          } catch (e) {
            // Ignore invalid cache
          }
        }
      }
    }
  }

  Future<void> _saveToDatabase() async {
    await _dbHelper.insertInventory(_inventory);
  }

  Future<void> fetchInventory({
    int? shopId,
    int? productId,
    String? search,
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _inventory = await _inventoryService.getInventory(
        shopId: shopId,
        productId: productId,
        search: search,
      );
      await _saveToDatabase();
    } catch (e) {
      _error = e.toString();
      // Load offline data if API fails
      await _loadOfflineData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Inventory?> getInventoryItem(int id) async {
    try {
      return await _inventoryService.getInventoryItem(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Inventory?> createInventoryItem(Inventory inventory) async {
    try {
      final newItem = await _inventoryService.createInventoryItem(inventory);
      _inventory.add(newItem);
      await _saveToDatabase();
      _error = null;
      notifyListeners();
      return newItem;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateInventoryItem(Inventory inventory) async {
    try {
      print('🔍 [InventoryProvider] Updating inventory item: id=${inventory.id}, product=${inventory.product}, quantity=${inventory.quantity}');
      final updatedItem = await _inventoryService.updateInventoryItem(inventory);
      print('🔍 [InventoryProvider] API update successful, returned quantity: ${updatedItem.quantity}');
      final index = _inventory.indexWhere((item) => item.id == inventory.id);
      if (index != -1) {
        _inventory[index] = updatedItem;
        await _saveToDatabase();
        print('🔍 [InventoryProvider] Local inventory updated successfully');
      } else {
        print('🔍 [InventoryProvider] Warning: inventory item not found in local list');
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      print('🔍 [InventoryProvider] Error updating inventory item: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteInventoryItem(int id) async {
    try {
      await _inventoryService.deleteInventoryItem(id);
      _inventory.removeWhere((item) => item.id == id);
      await _saveToDatabase();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<Inventory>> fetchLowStockItems() async {
    try {
      return await _inventoryService.getLowStockItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> adjustStock(int inventoryId, double adjustment, String reason) async {
    try {
      final updatedItem = await _inventoryService.adjustStock(inventoryId, adjustment, reason);
      final index = _inventory.indexWhere((item) => item.id == inventoryId);
      if (index != -1) {
        _inventory[index] = updatedItem;
        await _saveToDatabase();
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      return await _inventoryService.getInventoryStats();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper methods for filtering
  List<Inventory> getItemsByProduct(int productId) {
    return _inventory.where((item) => item.product == productId).toList();
  }

  List<Inventory> getItemsByShop(int shopId) {
    return _inventory.where((item) => item.shop == shopId).toList();
  }

  Inventory? getItemById(int id) {
    try {
      return _inventory.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
}







