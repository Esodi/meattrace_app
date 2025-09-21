import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product_category.dart';
import '../services/product_category_service.dart';
import '../services/database_helper.dart';

class ProductCategoryProvider with ChangeNotifier {
  final ProductCategoryService _categoryService = ProductCategoryService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<ProductCategory> _categories = [];
  bool _isLoading = false;
  String? _error;
  SharedPreferences? _prefs;

  List<ProductCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProductCategoryProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    try {
      _categories = await _dbHelper.getCategories();
      notifyListeners();
    } catch (e) {
      // If database fails, try shared preferences as fallback
      if (_prefs != null) {
        final cached = _prefs!.getString('product_categories');
        if (cached != null) {
          try {
            final data = json.decode(cached) as List;
            _categories = data
                .map((json) => ProductCategory.fromJson(json))
                .toList();
            notifyListeners();
          } catch (e) {
            // Ignore invalid cache
          }
        }
      }
    }
  }

  Future<void> _saveToDatabase() async {
    await _dbHelper.insertCategories(_categories);
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryService.fetchAllCategories();
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

  Future<void> addCategory(ProductCategory category) async {
    try {
      final newCategory = await _categoryService.addCategory(category);
      _categories.add(newCategory);
      await _saveToDatabase();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCategory(ProductCategory category) async {
    try {
      final updatedCategory = await _categoryService.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = updatedCategory;
        await _saveToDatabase();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _categoryService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      await _saveToDatabase();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
