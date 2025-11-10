import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

/// Service to manage all local storage including cache clearing
class StorageService {
  static final StorageService _instance = StorageService._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  /// Clear ALL local storage data (use on logout or when switching users)
  Future<void> clearAllLocalData() async {
    try {
      debugPrint('🗑️ [STORAGE] Clearing all local storage data...');
      
      // 1. Clear SharedPreferences (except app settings)
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Keep only non-user-specific settings
      final keysToKeep = {
        'language',
        'theme_mode',
        'notifications_enabled',
        'auto_sync',
      };
      
      for (final key in keys) {
        if (!keysToKeep.contains(key)) {
          await prefs.remove(key);
          debugPrint('   ✓ Removed SharedPreferences key: $key');
        }
      }
      
      // 2. Clear local SQLite database
      await _dbHelper.clearAllData();
      debugPrint('   ✓ Cleared SQLite database');
      
      debugPrint('✅ [STORAGE] All local storage cleared successfully');
    } catch (e) {
      debugPrint('❌ [STORAGE] Error clearing local storage: $e');
      throw Exception('Failed to clear local storage: $e');
    }
  }

  /// Clear only user-specific data (animals, products, etc.) but keep tokens
  Future<void> clearUserData() async {
    try {
      debugPrint('🗑️ [STORAGE] Clearing user-specific data...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // List of user-data cache keys
      final userDataKeys = [
        'animals',
        'products',
        'inventory',
        'meat_traces',
        'product_categories',
        'cached_activities',
        'activities_last_fetch',
        'navigation_state_',  // Will remove all keys starting with this
      ];
      
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (userDataKeys.any((prefix) => key.startsWith(prefix))) {
          await prefs.remove(key);
          debugPrint('   ✓ Removed cache key: $key');
        }
      }
      
      // Clear database tables
      await _dbHelper.clearAnimals();
      await _dbHelper.clearProducts();
      await _dbHelper.clearInventory();
      
      debugPrint('✅ [STORAGE] User data cleared successfully');
    } catch (e) {
      debugPrint('❌ [STORAGE] Error clearing user data: $e');
    }
  }

  /// Clear specific cache types
  Future<void> clearCache(CacheType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      switch (type) {
        case CacheType.animals:
          await prefs.remove('animals');
          await _dbHelper.clearAnimals();
          debugPrint('✅ [STORAGE] Animals cache cleared');
          break;
          
        case CacheType.products:
          await prefs.remove('products');
          await _dbHelper.clearProducts();
          debugPrint('✅ [STORAGE] Products cache cleared');
          break;
          
        case CacheType.inventory:
          await prefs.remove('inventory');
          await _dbHelper.clearInventory();
          debugPrint('✅ [STORAGE] Inventory cache cleared');
          break;
          
        case CacheType.activities:
          await prefs.remove('cached_activities');
          await prefs.remove('activities_last_fetch');
          debugPrint('✅ [STORAGE] Activities cache cleared');
          break;
          
        case CacheType.all:
          await clearAllLocalData();
          break;
      }
    } catch (e) {
      debugPrint('❌ [STORAGE] Error clearing cache: $e');
    }
  }
}

enum CacheType {
  animals,
  products,
  inventory,
  activities,
  all,
}
