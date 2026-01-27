import 'package:flutter/foundation.dart';
import '../models/external_vendor.dart';
import '../services/database_helper.dart';

class ExternalVendorProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<ExternalVendor> _vendors = [];
  bool _isLoading = false;
  String? _error;

  List<ExternalVendor> get vendors => _vendors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchVendors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vendors = await _dbHelper.getExternalVendors();
      debugPrint(
        '📦 [ExternalVendorProvider] Fetched ${_vendors.length} vendors',
      );
    } catch (e) {
      debugPrint('❌ [ExternalVendorProvider] Error fetching vendors: $e');
      _error = 'Failed to load external vendors: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ExternalVendor?> addVendor(ExternalVendor vendor) async {
    try {
      final id = await _dbHelper.insertExternalVendor(vendor);
      final newVendor = vendor.copyWith(id: id);
      _vendors.add(newVendor);
      // Sort by name after adding
      _vendors.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      return newVendor;
    } catch (e) {
      debugPrint('❌ [ExternalVendorProvider] Error adding vendor: $e');
      _error = 'Failed to add vendor: $e';
      notifyListeners();
      return null;
    }
  }

  // Helper method to find a vendor by ID
  ExternalVendor? getVendorById(int id) {
    try {
      return _vendors.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  // Filter vendors by category
  List<ExternalVendor> getVendorsByCategory(ExternalVendorCategory category) {
    return _vendors.where((v) => v.category == category).toList();
  }
}
