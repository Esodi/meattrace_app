import 'package:flutter/material.dart';
import '../models/yield_trend_data.dart';
import '../services/yield_trends_service.dart';

class YieldTrendsProvider with ChangeNotifier {
  final YieldTrendsService _yieldTrendsService = YieldTrendsService();
  
  YieldTrendData? _farmerTrends;
  YieldTrendData? _processorTrends;
  YieldTrendData? _shopTrends;
  Map<String, YieldTrendData>? _comparativeTrends;
  
  bool _isLoading = false;
  String? _error;
  String _currentPeriod = '7d';

  // Getters
  YieldTrendData? get farmerTrends => _farmerTrends;
  YieldTrendData? get processorTrends => _processorTrends;
  YieldTrendData? get shopTrends => _shopTrends;
  Map<String, YieldTrendData>? get comparativeTrends => _comparativeTrends;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentPeriod => _currentPeriod;

  /// Fetch yield trends for farmers
  Future<void> fetchFarmerTrends({
    String period = '7d',
    String? species,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _farmerTrends != null && _farmerTrends!.period == period) {
      return; // Use cached data
    }

    _isLoading = true;
    _error = null;
    _currentPeriod = period;
    notifyListeners();

    try {
      _farmerTrends = await _yieldTrendsService.getFarmerYieldTrends(
        period: period,
        species: species,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch yield trends for processors
  Future<void> fetchProcessorTrends({
    String period = '7d',
    String? productType,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _processorTrends != null && _processorTrends!.period == period) {
      return; // Use cached data
    }

    _isLoading = true;
    _error = null;
    _currentPeriod = period;
    notifyListeners();

    try {
      _processorTrends = await _yieldTrendsService.getProcessorYieldTrends(
        period: period,
        productType: productType,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch yield trends for shops
  Future<void> fetchShopTrends({
    String period = '7d',
    String? category,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _shopTrends != null && _shopTrends!.period == period) {
      return; // Use cached data
    }

    _isLoading = true;
    _error = null;
    _currentPeriod = period;
    notifyListeners();

    try {
      _shopTrends = await _yieldTrendsService.getShopYieldTrends(
        period: period,
        category: category,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch comparative yield trends across all roles
  Future<void> fetchComparativeTrends({
    String period = '7d',
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _comparativeTrends != null && 
        _comparativeTrends!.values.first.period == period) {
      return; // Use cached data
    }

    _isLoading = true;
    _error = null;
    _currentPeriod = period;
    notifyListeners();

    try {
      _comparativeTrends = await _yieldTrendsService.getComparativeYieldTrends(
        period: period,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get trends for a specific role
  YieldTrendData? getTrendsForRole(String role) {
    switch (role.toLowerCase()) {
      case 'abbatoir':
        return _farmerTrends;
      case 'processingunit':
      case 'processor':
        return _processorTrends;
      case 'shop':
        return _shopTrends;
      default:
        return null;
    }
  }

  /// Refresh trends for a specific role
  Future<void> refreshTrendsForRole(String role, {String? filter}) async {
    switch (role.toLowerCase()) {
      case 'abbatoir':
        await fetchFarmerTrends(
          period: _currentPeriod,
          species: filter,
          forceRefresh: true,
        );
        break;
      case 'processingunit':
      case 'processor':
        await fetchProcessorTrends(
          period: _currentPeriod,
          productType: filter,
          forceRefresh: true,
        );
        break;
      case 'shop':
        await fetchShopTrends(
          period: _currentPeriod,
          category: filter,
          forceRefresh: true,
        );
        break;
    }
  }

  /// Change the time period for all trends
  Future<void> changePeriod(String newPeriod, String userRole) async {
    if (_currentPeriod == newPeriod) return;
    
    _currentPeriod = newPeriod;
    
    // Refresh trends for the current user role
    await refreshTrendsForRole(userRole);
  }

  /// Clear all cached data
  void clearCache() {
    _farmerTrends = null;
    _processorTrends = null;
    _shopTrends = null;
    _comparativeTrends = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get available time periods
  List<String> get availablePeriods => ['7d', '30d', '90d', '1y'];

  /// Get period display name
  String getPeriodDisplayName(String period) {
    switch (period) {
      case '7d':
        return '7 Days';
      case '30d':
        return '30 Days';
      case '90d':
        return '90 Days';
      case '1y':
        return '1 Year';
      default:
        return period;
    }
  }

  /// Check if data is stale (older than 5 minutes)
  bool isDataStale(YieldTrendData? data) {
    if (data == null) return true;
    final now = DateTime.now();
    final difference = now.difference(data.lastUpdated);
    return difference.inMinutes > 5;
  }

  /// Auto-refresh data if stale
  Future<void> autoRefreshIfStale(String userRole) async {
    final currentData = getTrendsForRole(userRole);
    if (isDataStale(currentData)) {
      await refreshTrendsForRole(userRole);
    }
  }
}