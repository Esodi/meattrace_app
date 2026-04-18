import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/database_helper.dart';
import '../utils/initialization_helper.dart';

class ProductProvider with ChangeNotifier, WidgetsBindingObserver {
  final ProductService _productService = ProductService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Stream-based updates
  final BehaviorSubject<List<Product>> _productsStream = BehaviorSubject.seeded(
    [],
  );
  final BehaviorSubject<bool> _isLoadingStream = BehaviorSubject.seeded(false);
  final BehaviorSubject<String?> _errorStream = BehaviorSubject.seeded(null);

  // Background sync
  Timer? _backgroundSyncTimer;
  bool _isBackgroundSyncEnabled = true;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Stream getters
  Stream<List<Product>> get productsStream => _productsStream.stream;
  Stream<bool> get isLoadingStream => _isLoadingStream.stream;
  Stream<String?> get errorStream => _errorStream.stream;

  // Lazy initializer for background data loading
  late final LazyInitializer<void> _dataInitializer;

  ProductProvider() {
    _dataInitializer = LazyInitializer(() => _initPrefs());
    WidgetsBinding.instance.addObserver(this);
    // Start initialization in background immediately
    _startBackgroundInitialization();
    _startBackgroundSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause background polling whenever the app isn't in the foreground so
    // we don't burn battery/bandwidth syncing products the user can't see.
    if (state == AppLifecycleState.resumed) {
      if (_isBackgroundSyncEnabled && _backgroundSyncTimer == null) {
        _startBackgroundSync();
      }
    } else {
      _backgroundSyncTimer?.cancel();
      _backgroundSyncTimer = null;
    }
  }

  Future<void> _startBackgroundInitialization() async {
    try {
      await _dataInitializer.value;
    } catch (e) {
      // Handle initialization errors silently for now
      debugPrint('ProductProvider initialization error: $e');
    }
  }

  Future<void> _initPrefs() async {
    if (_isInitialized) return; // Already initialized

    _isLoading = true;

    try {
      _prefs = await InitializationHelper.initSharedPreferences();
      await _loadOfflineData();
    } catch (e) {
      debugPrint('Failed to initialize ProductProvider: $e');
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ensures data is initialized before proceeding
  Future<void> ensureInitialized() async {
    await _dataInitializer.value;
  }

  /// Loads cached products without notifying; caller is responsible for
  /// triggering a single notifyListeners once all state is settled.
  Future<void> _loadOfflineData() async {
    try {
      _products = await _dbHelper.getProducts();
    } catch (_) {
      if (_prefs != null) {
        final cached = _prefs!.getString('products');
        if (cached != null) {
          try {
            final data = json.decode(cached) as List;
            _products = data.map((json) => Product.fromMap(json)).toList();
          } catch (_) {}
        }
      }
    }
  }

  Future<void> _saveToDatabase() async {
    await _dbHelper.insertProducts(_products);
  }

  Future<void> fetchProducts({
    String? productType,
    int? animal,
    int? processingUnitId,
    String? search,
    bool? pendingReceipt,
    bool forceRefresh = false,
  }) async {
    // Schedule to next microtask so callers invoking during build don't trip
    // setState-during-build assertions.
    await Future.microtask(() {});

    _isLoading = true;
    _error = null;
    _isLoadingStream.add(true);
    notifyListeners();

    try {
      _products = await _productService.getProducts(
        productType: productType,
        animal: animal,
        processingUnit: processingUnitId,
        search: search,
        pendingReceipt: pendingReceipt,
      );
      await _saveToDatabase();
      _productsStream.add(_products);
    } catch (e) {
      _error = e.toString();
      await _loadOfflineData();
    } finally {
      _isLoading = false;
      _isLoadingStream.add(false);
      notifyListeners();
    }
  }

  Future<Product?> createProduct(Product product) async {
    try {
      debugPrint('🔄 [ProductProvider] Creating product via service...');
      final newProduct = await _productService.createProduct(product);
      debugPrint(
        '✅ [ProductProvider] Product created successfully, adding to local list',
      );
      _products.add(newProduct);
      await _saveToDatabase();
      _error = null; // Clear any previous errors
      notifyListeners();
      return newProduct;
    } catch (e) {
      debugPrint('❌ [ProductProvider] Product creation failed: $e');
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

  Future<Map<String, dynamic>> transferProducts(
    List<int> productIds,
    int shopId, {
    Map<int, double>? productWeights,
  }) async {
    try {
      final response = await _productService.transferProducts(
        productIds,
        shopId,
        productWeights: productWeights,
      );
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

  Future<Map<String, dynamic>> receiveProducts({
    List<Map<String, dynamic>>? receives,
    List<Map<String, dynamic>>? rejections,
  }) async {
    try {
      final response = await _productService.receiveProducts(
        receives: receives,
        rejections: rejections,
      );
      return response;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Product?> updateProduct(Product product, {bool partialUpdate = false, Map<String, dynamic>? partialData}) async {
    try {
      final updatedProduct = await _productService.updateProduct(product, partialUpdate: partialUpdate, partialData: partialData);
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
    WidgetsBinding.instance.removeObserver(this);
    _backgroundSyncTimer?.cancel();
    _productsStream.close();
    _isLoadingStream.close();
    _errorStream.close();
    super.dispose();
  }
}
