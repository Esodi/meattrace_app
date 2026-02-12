import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../services/sale_service.dart';

class SaleProvider with ChangeNotifier {
  final SaleService _saleService = SaleService();

  List<Sale> _sales = [];
  Sale? _currentSale;
  bool _isLoading = false;
  String? _error;

  List<Sale> get sales => _sales;
  Sale? get currentSale => _currentSale;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all sales
  Future<void> fetchSales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sales = await _saleService.getSales();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Fetch single sale
  Future<void> fetchSale(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSale = await _saleService.getSale(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Create sale
  Future<Sale> createSale(Sale sale) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newSale = await _saleService.createSale(sale.toJson());
      _sales.insert(0, newSale);
      _isLoading = false;
      notifyListeners();
      return newSale;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Delete sale
  Future<void> deleteSale(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _saleService.deleteSale(id);
      _sales.removeWhere((sale) => sale.id == id);
      if (_currentSale?.id == id) {
        _currentSale = null;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
