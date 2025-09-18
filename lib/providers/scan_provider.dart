import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/scan_history_service.dart';

class ScanProvider with ChangeNotifier {
  Product? _currentProduct;
  bool _isLoading = false;
  String? _error;

  Product? get currentProduct => _currentProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProduct(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiService = ApiService();
      final product = await apiService.fetchProduct(int.parse(productId));
      _currentProduct = product;

      // Update scan history with product name
      final scanHistoryService = ScanHistoryService();
      await scanHistoryService.addScan(productId, productName: product.name);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearProduct() {
    _currentProduct = null;
    notifyListeners();
  }
}
