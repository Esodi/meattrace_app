import 'package:dio/dio.dart';
import '../models/yield_trend_data.dart';
import '../utils/constants.dart';
import 'dio_client.dart';

class YieldTrendsService {
  static final YieldTrendsService _instance = YieldTrendsService._internal();
  final DioClient _dioClient = DioClient();

  factory YieldTrendsService() {
    return _instance;
  }

  YieldTrendsService._internal();

  /// Get yield trends data for farmers
  /// Includes metrics like animal count, slaughter rates, transfer rates
  Future<YieldTrendData> getFarmerYieldTrends({
    String period = '7d', // 7d, 30d, 90d, 1y
    String? species,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'period': period,
        'role': 'farmer',
      };
      if (species != null) queryParams['species'] = species;

      final response = await _dioClient.dio.get(
        '${Constants.baseUrl}/api/v2/yield-trends/',
        queryParameters: queryParams,
      );

      return YieldTrendData.fromMap(response.data);
    } catch (e) {
      // Return mock data if API fails
      return _getMockFarmerData(period);
    }
  }

  /// Get yield trends data for processors
  /// Includes metrics like processing throughput, product creation rates, transfer rates
  Future<YieldTrendData> getProcessorYieldTrends({
    String period = '7d',
    String? productType,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'period': period,
        'role': 'processor',
      };
      if (productType != null) queryParams['product_type'] = productType;

      final response = await _dioClient.dio.get(
        '${Constants.baseUrl}/api/v2/yield-trends/',
        queryParameters: queryParams,
      );

      return YieldTrendData.fromMap(response.data);
    } catch (e) {
      // Return mock data if API fails
      return _getMockProcessorData(period);
    }
  }

  /// Get yield trends data for shops
  /// Includes metrics like inventory levels, sales rates, order fulfillment
  Future<YieldTrendData> getShopYieldTrends({
    String period = '7d',
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'period': period,
        'role': 'shop',
      };
      if (category != null) queryParams['category'] = category;

      final response = await _dioClient.dio.get(
        '${Constants.baseUrl}/api/v2/yield-trends/',
        queryParameters: queryParams,
      );

      return YieldTrendData.fromMap(response.data);
    } catch (e) {
      // Return mock data if API fails
      return _getMockShopData(period);
    }
  }

  /// Get comparative yield trends across all roles
  Future<Map<String, YieldTrendData>> getComparativeYieldTrends({
    String period = '7d',
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '${Constants.baseUrl}/api/v2/yield-trends/comparative/',
        queryParameters: {'period': period},
      );

      final data = response.data as Map<String, dynamic>;
      return {
        'farmer': YieldTrendData.fromMap(data['farmer']),
        'processor': YieldTrendData.fromMap(data['processor']),
        'shop': YieldTrendData.fromMap(data['shop']),
      };
    } catch (e) {
      // Return mock data if API fails
      return {
        'farmer': _getMockFarmerData(period),
        'processor': _getMockProcessorData(period),
        'shop': _getMockShopData(period),
      };
    }
  }

  /// Mock data for farmers when API is unavailable
  YieldTrendData _getMockFarmerData(String period) {
    final now = DateTime.now();
    final days = _getPeriodDays(period);
    
    return YieldTrendData(
      period: period,
      role: 'farmer',
      primaryMetric: YieldMetric(
        name: 'Animal Count',
        values: List.generate(days, (i) => 45.0 + (i * 2.5) + (i % 3 * 5)),
        unit: 'animals',
        trend: 12.5,
        isPositive: true,
      ),
      secondaryMetrics: [
        YieldMetric(
          name: 'Slaughter Rate',
          values: List.generate(days, (i) => 8.0 + (i * 0.5) + (i % 2 * 2)),
          unit: '%',
          trend: 8.3,
          isPositive: true,
        ),
        YieldMetric(
          name: 'Transfer Rate',
          values: List.generate(days, (i) => 15.0 + (i * 1.2) + (i % 4 * 3)),
          unit: '%',
          trend: 15.7,
          isPositive: true,
        ),
        YieldMetric(
          name: 'Health Score',
          values: List.generate(days, (i) => 85.0 + (i * 0.8) + (i % 5 * 2)),
          unit: '%',
          trend: 5.2,
          isPositive: true,
        ),
      ],
      labels: _generateLabels(period, days),
      lastUpdated: now,
    );
  }

  /// Mock data for processors when API is unavailable
  YieldTrendData _getMockProcessorData(String period) {
    final now = DateTime.now();
    final days = _getPeriodDays(period);
    
    return YieldTrendData(
      period: period,
      role: 'processor',
      primaryMetric: YieldMetric(
        name: 'Processing Yield',
        values: List.generate(days, (i) => 65.0 + (i * 1.8) + (i % 3 * 4)),
        unit: '%',
        trend: 18.2,
        isPositive: true,
      ),
      secondaryMetrics: [
        YieldMetric(
          name: 'Throughput',
          values: List.generate(days, (i) => 25.0 + (i * 2.1) + (i % 2 * 3)),
          unit: 'units/day',
          trend: 22.4,
          isPositive: true,
        ),
        YieldMetric(
          name: 'Quality Score',
          values: List.generate(days, (i) => 92.0 + (i * 0.3) + (i % 4 * 1)),
          unit: '%',
          trend: 3.1,
          isPositive: true,
        ),
        YieldMetric(
          name: 'Waste Reduction',
          values: List.generate(days, (i) => 12.0 - (i * 0.2) + (i % 5 * 0.5)),
          unit: '%',
          trend: -8.5,
          isPositive: true,
        ),
      ],
      labels: _generateLabels(period, days),
      lastUpdated: now,
    );
  }

  /// Mock data for shops when API is unavailable
  YieldTrendData _getMockShopData(String period) {
    final now = DateTime.now();
    final days = _getPeriodDays(period);
    
    return YieldTrendData(
      period: period,
      role: 'shop',
      primaryMetric: YieldMetric(
        name: 'Sales Volume',
        values: List.generate(days, (i) => 120.0 + (i * 8.5) + (i % 3 * 15)),
        unit: 'units',
        trend: 25.3,
        isPositive: true,
      ),
      secondaryMetrics: [
        YieldMetric(
          name: 'Inventory Turnover',
          values: List.generate(days, (i) => 4.2 + (i * 0.15) + (i % 2 * 0.3)),
          unit: 'times/week',
          trend: 12.8,
          isPositive: true,
        ),
        YieldMetric(
          name: 'Order Fulfillment',
          values: List.generate(days, (i) => 88.0 + (i * 0.8) + (i % 4 * 2)),
          unit: '%',
          trend: 7.9,
          isPositive: true,
        ),
        YieldMetric(
          name: 'Customer Satisfaction',
          values: List.generate(days, (i) => 4.1 + (i * 0.02) + (i % 5 * 0.1)),
          unit: '/5',
          trend: 4.2,
          isPositive: true,
        ),
      ],
      labels: _generateLabels(period, days),
      lastUpdated: now,
    );
  }

  int _getPeriodDays(String period) {
    switch (period) {
      case '7d':
        return 7;
      case '30d':
        return 30;
      case '90d':
        return 90;
      case '1y':
        return 365;
      default:
        return 7;
    }
  }

  List<String> _generateLabels(String period, int days) {
    final now = DateTime.now();
    
    if (period == '7d') {
      return List.generate(days, (i) {
        final date = now.subtract(Duration(days: days - 1 - i));
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
      });
    } else if (period == '30d') {
      return List.generate(days, (i) {
        final date = now.subtract(Duration(days: days - 1 - i));
        return '${date.day}/${date.month}';
      });
    } else if (period == '90d') {
      // Show weekly labels for 90 days
      return List.generate(13, (i) {
        final date = now.subtract(Duration(days: (12 - i) * 7));
        return 'W${i + 1}';
      });
    } else if (period == '1y') {
      // Show monthly labels for 1 year
      return List.generate(12, (i) {
        final date = DateTime(now.year, now.month - (11 - i));
        return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
      });
    }
    
    return List.generate(days, (i) => 'Day ${i + 1}');
  }
}