import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/order.dart';
import '../models/inventory.dart';
import '../services/order_service.dart';
import '../services/database_helper.dart';

class CartItem {
  final InventoryProduct product;
  final Inventory inventory;
  double quantity;

  CartItem({
    required this.product,
    required this.inventory,
    required this.quantity,
  });

  double get subtotal => quantity * product.price;

  CartItem copyWith({double? quantity}) {
    return CartItem(
      product: product,
      inventory: inventory,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toMap(),
      'inventory': {
        'id': inventory.id,
        'shop': inventory.shop,
        'product': inventory.product,
        'quantity': inventory.quantity,
        'min_stock_level': inventory.minStockLevel,
        'last_updated': inventory.lastUpdated.toIso8601String(),
      },
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: InventoryProduct.fromMap(json['product']),
      inventory: Inventory(
        id: json['inventory']['id'],
        shop: json['inventory']['shop'],
        product: json['inventory']['product'],
        quantity: json['inventory']['quantity'].toDouble(),
        minStockLevel: json['inventory']['min_stock_level'].toDouble(),
        lastUpdated: DateTime.parse(json['inventory']['last_updated']),
      ),
      quantity: json['quantity'].toDouble(),
    );
  }
}

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Order> _orders = [];
  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String? _error;
  SharedPreferences? _prefs;

  List<Order> get orders => _orders;
  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get cartTotal => _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  int get cartItemCount => _cartItems.length;

  OrderProvider() {
    _initPrefs();
    _loadCartFromStorage();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _loadCartFromStorage() async {
    try {
      if (_prefs != null) {
        final cartData = _prefs!.getString('cart_items');
        if (cartData != null) {
          final cartJson = json.decode(cartData) as List;
          _cartItems = cartJson.map((item) => CartItem.fromJson(item)).toList();
          notifyListeners();
        }
      }
    } catch (e) {
      // Ignore invalid cart data
      _cartItems = [];
    }
  }

  Future<void> _saveCartToStorage() async {
    if (_prefs != null) {
      final cartJson = _cartItems.map((item) => item.toJson()).toList();
      await _prefs!.setString('cart_items', json.encode(cartJson));
    }
  }

  Future<void> fetchOrders({int? shopId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _orderService.fetchOrders(shopId: shopId);
      await _saveOrdersToDatabase();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      // Try to load from database as fallback
      try {
        _orders = await _dbHelper.getOrders();
        notifyListeners();
      } catch (dbError) {
        // Database also failed, keep error
      }
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveOrdersToDatabase() async {
    await _dbHelper.insertOrders(_orders);
  }

  Future<Order?> createOrder(Order order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdOrder = await _orderService.createOrder(order);
      print('🔍 [OrderProvider] Created order ID: ${createdOrder.id}');
      _orders.insert(0, createdOrder);
      await _saveOrdersToDatabase();

      // Clear cart after successful order
      _cartItems.clear();
      await _saveCartToStorage();

      notifyListeners();
      return createdOrder;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addToCart(InventoryProduct product, Inventory inventory, double quantity) {
    // Check if item already in cart
    final existingIndex = _cartItems.indexWhere(
      (item) => item.product.id == product.id
    );

    if (existingIndex >= 0) {
      // Update quantity
      final newQuantity = _cartItems[existingIndex].quantity + quantity;
      if (newQuantity <= inventory.quantity) {
        _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(quantity: newQuantity);
      }
    } else {
      // Add new item
      if (quantity <= inventory.quantity) {
        _cartItems.add(CartItem(
          product: product,
          inventory: inventory,
          quantity: quantity,
        ));
      }
    }

    _saveCartToStorage();
    notifyListeners();
  }

  void updateCartItemQuantity(int productId, double quantity) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else if (quantity <= _cartItems[index].inventory.quantity) {
        _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      }
      _saveCartToStorage();
      notifyListeners();
    }
  }

  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    _saveCartToStorage();
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _saveCartToStorage();
    notifyListeners();
  }

  bool canAddToCart(InventoryProduct product, double quantity, Inventory inventory) {
    final existingItem = _cartItems.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => CartItem(product: product, inventory: inventory, quantity: 0),
    );

    final totalQuantity = existingItem.quantity + quantity;
    return totalQuantity <= inventory.quantity;
  }

  List<OrderItem> convertCartToOrderItems(int orderId) {
    return _cartItems.map((cartItem) {
      return OrderItem(
        order: orderId,
        product: cartItem.inventory.product, // Use inventory product ID
        quantity: cartItem.quantity,
        unitPrice: cartItem.product.price,
        subtotal: cartItem.subtotal,
      );
    }).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}







