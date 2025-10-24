import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../models/shop.dart';
import '../utils/constants.dart';
import 'dio_client.dart';

class ShopService {
  static final ShopService _instance = ShopService._internal();
  final DioClient _dioClient = DioClient();

  factory ShopService() {
    return _instance;
  }

  ShopService._internal();

  Future<Shop> createShop(Shop shop) async {
    developer.log('ShopService: Starting createShop for "${shop.name}"');
    developer.log('ShopService: Endpoint: ${Constants.shopsEndpoint}');
    developer.log('ShopService: Request data: ${shop.toJsonForCreate()}');

    try {
      final response = await _dioClient.dio.post(
        Constants.shopsEndpoint,
        data: shop.toJsonForCreate(),
      );

      developer.log('ShopService: Response status: ${response.statusCode}');
      developer.log('ShopService: Response data: ${response.data}');

      final createdShop = Shop.fromJson(response.data);
      developer.log('ShopService: Successfully created shop with ID: ${createdShop.id}');

      return createdShop;
    } catch (e) {
      developer.log('ShopService: Error creating shop: $e');
      developer.log('ShopService: Error type: ${e.runtimeType}');
      if (e is DioException) {
        developer.log('ShopService: DioException details:');
        developer.log('  - Status code: ${e.response?.statusCode}');
        developer.log('  - Response data: ${e.response?.data}');
        developer.log('  - Request URL: ${e.requestOptions.uri}');
        developer.log('  - Request method: ${e.requestOptions.method}');
        developer.log('  - Request headers: ${e.requestOptions.headers}');
      }
      throw Exception('Failed to create shop: $e');
    }
  }

  Future<List<Shop>> getShops() async {
    try {
      final response = await _dioClient.dio.get(
        Constants.shopsEndpoint,
      );

      final data = response.data;
      if (data is Map && data.containsKey('results')) {
        return List<Shop>.from(
          data['results'].map((json) => Shop.fromJson(json))
        );
      } else if (data is List) {
        return List<Shop>.from(
          data.map((json) => Shop.fromJson(json))
        );
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Failed to fetch shops: $e');
    }
  }

  /// Fetch shops for registration (public endpoint, no auth required)
  Future<List<Shop>> getPublicShops() async {
    try {
      final url = '${Constants.baseUrl}/api/v2/public/shops/';
      developer.log('[SHOP_SERVICE] Fetching public shops from: $url');
      
      // Create a temporary Dio instance without authentication
      // Don't set baseUrl to avoid double path issue
      final publicDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',  // Force JSON response, not HTML
          },
        ),
      );

      final response = await publicDio.get(url);

      developer.log('[SHOP_SERVICE] Public response status: ${response.statusCode}');
      developer.log('[SHOP_SERVICE] Public response data type: ${response.data.runtimeType}');
      
      // Check if we got HTML instead of JSON
      if (response.data is String) {
        developer.log('[SHOP_SERVICE] ERROR: Received HTML response instead of JSON');
        developer.log('[SHOP_SERVICE] Response preview: ${(response.data as String).substring(0, 200)}...');
        throw Exception('Server returned HTML instead of JSON. The endpoint may not exist.');
      }
      
      developer.log('[SHOP_SERVICE] Public response data: ${response.data}');

      final data = response.data;
      List<Shop> shops = [];

      if (data is Map && data.containsKey('results')) {
        shops = List<Shop>.from(
          data['results'].map((json) => Shop.fromJson(json))
        );
      } else if (data is List) {
        shops = List<Shop>.from(
          data.map((json) => Shop.fromJson(json))
        );
      } else {
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }

      developer.log('[SHOP_SERVICE] Successfully fetched ${shops.length} public shops');
      return shops;
    } on DioException catch (e) {
      developer.log('[SHOP_SERVICE] Public fetch failed: ${e.type} - ${e.message}');
      if (e.response != null) {
        developer.log('[SHOP_SERVICE] Response status: ${e.response?.statusCode}');
        developer.log('[SHOP_SERVICE] Response data type: ${e.response?.data.runtimeType}');
        if (e.response?.data is String) {
          developer.log('[SHOP_SERVICE] HTML Response (first 500 chars): ${(e.response?.data as String).substring(0, 500)}');
        } else {
          developer.log('[SHOP_SERVICE] Response data: ${e.response?.data}');
        }
      }
      throw Exception('Failed to fetch public shops: ${e.message}');
    } catch (e) {
      developer.log('[SHOP_SERVICE] Unexpected error: $e');
      rethrow;
    }
  }

  Future<Shop> getShop(int id) async {
    try {
      final response = await _dioClient.dio.get('${Constants.shopsEndpoint}$id/');
      return Shop.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        throw Exception('Shop not found');
      }
      throw Exception('Failed to fetch shop: $e');
    }
  }

  Future<Shop> updateShop(Shop shop) async {
    try {
      final response = await _dioClient.dio.put(
        '${Constants.shopsEndpoint}${shop.id}/',
        data: shop.toJson(),
      );
      return Shop.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update shop: $e');
    }
  }

  Future<void> deleteShop(int id) async {
    try {
      await _dioClient.dio.delete('${Constants.shopsEndpoint}$id/');
    } catch (e) {
      throw Exception('Failed to delete shop: $e');
    }
  }
}