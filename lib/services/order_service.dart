import 'package:dio/dio.dart';
import '../models/order.dart';
import 'dio_client.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  final DioClient _dioClient = DioClient();

  factory OrderService() {
    return _instance;
  }

  OrderService._internal();

  Future<List<Order>> fetchOrders({int? shopId, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (shopId != null) queryParams['shop'] = shopId.toString();
      if (status != null) queryParams['status'] = status;

      final response = await _dioClient.dio.get(
        '/orders/',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List;
        return results.map((json) => Order.fromJson(json)).toList();
      } else if (data is List) {
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      print('🔍 [OrderService] DioException in fetchOrders: ${e.message}');
      print('🔍 [OrderService] Response status: ${e.response?.statusCode}');
      print('🔍 [OrderService] Response data: ${e.response?.data}');
      final errorMessage = e.message ?? 'Unknown network error';
      throw Exception('Failed to fetch orders: $errorMessage');
    } catch (e) {
      print('🔍 [OrderService] General exception in fetchOrders: $e');
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<Order> createOrder(Order order) async {
    try {
      final orderData = order.toJson()..remove('id')..remove('items');
      // Add items as items_data for backend processing
      if (order.items.isNotEmpty) {
        orderData['items_data'] = order.items.map((item) => item.toMapForCreate()).toList();
      }

      print('🔍 [OrderService] Sending order data: $orderData');

      final response = await _dioClient.dio.post(
        '/orders/',
        data: orderData,
      );

      print('🔍 [OrderService] Response status: ${response.statusCode}');
      print('🔍 [OrderService] Response data: ${response.data}');

      return Order.fromJson(response.data);
    } on DioException catch (e) {
      print('🔍 [OrderService] DioException: ${e.message}');
      print('🔍 [OrderService] Response: ${e.response?.data}');
      throw Exception('Failed to create order: ${e.message}');
    } catch (e) {
      print('🔍 [OrderService] General exception: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  Future<Order> getOrder(int orderId) async {
    try {
      final response = await _dioClient.dio.get('/orders/$orderId/');
      return Order.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to get order: ${e.message}');
    }
  }

  Future<Order> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await _dioClient.dio.patch(
        '/orders/$orderId/',
        data: {'status': status},
      );

      return Order.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update order status: ${e.message}');
    }
  }

  Future<List<Order>> fetchCustomerOrders(int customerId) async {
    try {
      final response = await _dioClient.dio.get(
        '/orders/',
        queryParameters: {'customer': customerId.toString()},
      );

      final data = response.data as List;
      return data.map((json) => Order.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch customer orders: ${e.message}');
    }
  }
}







