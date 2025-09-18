import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProductProvider() {
    _initPrefs();
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
      final newProduct = await _productService.createProduct(product);
      _products.add(newProduct);
      await _saveToDatabase();
      notifyListeners();
      return newProduct;
    } catch (e) {
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
}
