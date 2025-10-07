import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/database_helper.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  SharedPreferences? _prefs;

  // Stream-based updates
  final BehaviorSubject<List<Product>> _productsStream = BehaviorSubject.seeded([]);
  final BehaviorSubject<bool> _isLoadingStream = BehaviorSubject.seeded(false);
  final BehaviorSubject<String?> _errorStream = BehaviorSubject.seeded(null);

  // Background sync
  Timer? _backgroundSyncTimer;
  bool _isBackgroundSyncEnabled = true;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Stream getters
  Stream<List<Product>> get productsStream => _productsStream.stream;
  Stream<bool> get isLoadingStream => _isLoadingStream.stream;
  Stream<String?> get errorStream => _errorStream.stream;

  ProductProvider() {
    _initPrefs();
    _startBackgroundSync();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    try {
      _products = await _dbHelper.getProducts();
      notifyListeners();
    } catch (e) {
      // If database fails, try shared preferences as fallback
      if (_prefs != null) {
        final cached = _prefs!.getString('products');
        if (cached != null) {
          try {
            final data = json.decode(cached) as List;
            _products = data.map((json) => Product.fromMap(json)).toList();
            notifyListeners();
          } catch (e) {
            // Ignore invalid cache
          }
        }
      }
    }
  }

  Future<void> _saveToDatabase() async {
    await _dbHelper.insertProducts(_products);
  }

  Future<void> fetchProducts({String? productType, int? animal, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productService.getProducts(
        productType: productType,
        animal: animal,
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

  Future<Product?> createProduct(Product product) async {
    try {
      print('🔄 [ProductProvider] Creating product via service...');
      final newProduct = await _productService.createProduct(product);
      print('✅ [ProductProvider] Product created successfully, adding to local list');
      _products.add(newProduct);
      await _saveToDatabase();
      _error = null; // Clear any previous errors
      notifyListeners();
      return newProduct;
    } catch (e) {
      print('❌ [ProductProvider] Product creation failed: $e');
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Product?> getProduct(int id) async {
    try {
      return await _productService.getProduct(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _productService.deleteProduct(id);
      _products.removeWhere((product) => product.id == id);
      await _saveToDatabase();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // For backward compatibility
  Future<Product?> fetchProductByQR(String qrCode) async {
    // This would need to be implemented based on QR code format
    // For now, return null
    return null;
  }

  // For backward compatibility
  Future<void> fetchAllProducts() async {
    await fetchProducts();
  }

  // For backward compatibility
  Future<Product?> addProduct(Product product) async {
    return await createProduct(product);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> transferProducts(List<int> productIds, int shopId) async {
    try {
      final response = await _productService.transferProducts(productIds, shopId);
      // Refresh products list after transfer
      await fetchProducts();
      return response;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Product>> fetchTransferredProducts() async {
    try {
      return await _productService.getTransferredProducts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> receiveProducts(List<int> productIds) async {
    try {
      final response = await _productService.receiveProducts(productIds);
      return response;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Product?> updateProduct(Product product) async {
    try {
      final updatedProduct = await _productService.updateProduct(product);
      // Update the product in the local list
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
        await _saveToDatabase();
      }
      _error = null;
      notifyListeners();
      return updatedProduct;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getShops() async {
    try {
      return await _productService.getShops();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _startBackgroundSync() {
    if (!_isBackgroundSyncEnabled) return;
    _backgroundSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      // Run sync in background without blocking UI
      _performBackgroundSync();
    });
  }

  Future<void> _performBackgroundSync() async {
    try {
      // Fetch latest data in background
      final latestProducts = await _productService.getProducts();
      if (latestProducts.isNotEmpty && latestProducts != _products) {
        _products = latestProducts;
        await _saveToDatabase();
        _productsStream.add(_products);
        notifyListeners();
      }
    } catch (e) {
      // Silent fail for background sync
    }
  }

  void stopBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _isBackgroundSyncEnabled = false;
  }

  void startBackgroundSync() {
    _isBackgroundSyncEnabled = true;
    _startBackgroundSync();
  }

  @override
  void dispose() {
    _backgroundSyncTimer?.cancel();
    _productsStream.close();
    _isLoadingStream.close();
    _errorStream.close();
    super.dispose();
  }
}








