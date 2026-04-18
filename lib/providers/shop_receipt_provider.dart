import 'package:flutter/material.dart';
import '../models/shop_receipt.dart';
import '../models/shop.dart';
import '../services/receipt_service.dart';
import '../services/shop_service.dart';
import '../services/database_helper.dart';

class ShopReceiptProvider with ChangeNotifier {
  final ReceiptService _receiptService = ReceiptService();
  final ShopService _shopService = ShopService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<ShopReceipt> _receipts = [];
  List<Shop> _shops = [];
  bool _isLoading = false;
  String? _error;

  List<ShopReceipt> get receipts => _receipts;
  List<Shop> get shops => _shops;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ShopReceiptProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([_loadOfflineData(), _loadShops()]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([_loadShops(), fetchReceiptsFromApi()]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadOfflineData() async {
    try {
      _receipts = await _dbHelper.getShopReceipts();
    } catch (e) {
      // Ignore database errors during initial load
      _error = 'Failed to load offline receipts: $e';
    }
  }

  Future<void> _loadShops() async {
    try {
      _shops = await _shopService.getShops();
    } catch (e) {
      _error = 'Failed to load shops: $e';
    }
  }

  Future<void> fetchReceiptsFromApi() async {
    try {
      final apiReceipts = await _receiptService.getReceipts(limit: 50);
      _receipts = apiReceipts;
      await _saveToDatabase();
    } catch (e) {
      _error = 'Failed to fetch receipts from API: $e';
    }
  }

  Future<void> _saveToDatabase() async {
    try {
      await _dbHelper.insertShopReceipts(_receipts);
    } catch (e) {
      _error = 'Failed to save receipts locally: $e';
    }
  }

  Future<bool> recordReceipt(ShopReceipt receipt) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdReceipt = await _receiptService.createReceipt(receipt);
      _receipts.insert(0, createdReceipt);
      await _saveToDatabase();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ShopReceipt>> fetchReceiptsByShop(int shopId) async {
    try {
      return await _receiptService.getReceipts(shop: shopId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      // Fallback to local filtering
      return _receipts.where((receipt) => receipt.shop == shopId).toList();
    }
  }

  Future<List<ShopReceipt>> fetchReceiptsByProduct(int productId) async {
    try {
      return await _receiptService.getReceipts(product: productId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      // Fallback to local filtering
      return _receipts
          .where((receipt) => receipt.product == productId)
          .toList();
    }
  }

  Future<bool> isProductAlreadyReceived(int productId, int shopId) async {
    try {
      // Check local data first for fast response
      final existingLocally = _receipts.any(
        (receipt) => receipt.product == productId && receipt.shop == shopId,
      );
      if (existingLocally) return true;

      // Check API
      final apiReceipts = await _receiptService.getReceipts(
        product: productId,
        shop: shopId,
        limit: 1,
      );

      return apiReceipts.isNotEmpty;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
