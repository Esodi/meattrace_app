import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/shop_receipt.dart';
import '../models/shop.dart';
import '../services/shop_receipt_service.dart';
import '../services/database_helper.dart';

class ShopReceiptProvider with ChangeNotifier {
  final ShopReceiptService _receiptService = ShopReceiptService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<ShopReceipt> _receipts = [];
  List<Shop> _shops = [];
  bool _isLoading = false;
  String? _error;
  SharedPreferences? _prefs;

  List<ShopReceipt> get receipts => _receipts;
  List<Shop> get shops => _shops;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ShopReceiptProvider() {
    _initPrefs();
    _loadShops();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    try {
      _receipts = await _dbHelper.getShopReceipts();
      notifyListeners();
    } catch (e) {
      // If database fails, try shared preferences as fallback
      if (_prefs != null) {
        final cached = _prefs!.getString('shop_receipts');
        if (cached != null) {
          try {
            final data = json.decode(cached) as List;
            _receipts = data.map((json) => ShopReceipt.fromJson(json)).toList();
            notifyListeners();
          } catch (e) {
            // Ignore invalid cache
          }
        }
      }
    }
  }

  Future<void> _loadShops() async {
    // Mock shops - in real app, fetch from API
    _shops = [
      Shop(id: 1, name: 'Main Shop', location: 'Downtown'),
      Shop(id: 2, name: 'Branch Shop', location: 'Suburb'),
    ];
    notifyListeners();
  }

  Future<void> _saveToDatabase() async {
    await _dbHelper.insertShopReceipts(_receipts);
  }

  Future<bool> recordReceipt(ShopReceipt receipt) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _receiptService.recordReceipt(receipt);
      _receipts.add(receipt);
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
      // Mock API call - in real app, implement in service
      return _receipts.where((receipt) => receipt.shop == shopId).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<ShopReceipt>> fetchReceiptsByProduct(int productId) async {
    try {
      // Mock API call - in real app, implement in service
      return _receipts
          .where((receipt) => receipt.product == productId)
          .toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<bool> isProductAlreadyReceived(int productId, int shopId) async {
    try {
      // Check local data first
      final existing = _receipts
          .where(
            (receipt) => receipt.product == productId && receipt.shop == shopId,
          )
          .toList();
      if (existing.isNotEmpty) return true;

      // In real app, also check API
      return false;
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








