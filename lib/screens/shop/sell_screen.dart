import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/sale_service.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/custom_text_field.dart';
import '../../widgets/printer/receipt_printer.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SaleService _saleService = SaleService();
  
  // Cart items: Map<productId, CartItem>
  final Map<int, CartItem> _cart = {};
  
  // Customer info
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  
  // Payment method (lowercase to match backend)
  String _paymentMethod = 'cash';
  
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }
  
  double get _cartTotal {
    return _cart.values.fold(0.0, (sum, item) => sum + item.subtotal);
  }
  
  int get _cartItemCount {
    return _cart.values.fold(0, (sum, item) => sum + item.quantity.toInt());
  }
  
  void _addToCart(Product product, double quantity) {
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }
    
    if (quantity > product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${product.quantity} kg available in stock'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() {
      if (_cart.containsKey(product.id)) {
        final existingItem = _cart[product.id]!;
        final newQuantity = existingItem.quantity + quantity;
        
        if (newQuantity > product.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot add more. Only ${product.quantity} kg available'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        
        _cart[product.id!] = CartItem(
          product: product,
          quantity: newQuantity,
          unitPrice: product.price,
          subtotal: newQuantity * product.price,
        );
      } else {
        _cart[product.id!] = CartItem(
          product: product,
          quantity: quantity,
          unitPrice: product.price,
          subtotal: quantity * product.price,
        );
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => _tabController.animateTo(1),
        ),
      ),
    );
    
    // Don't auto-switch to cart tab - let user continue adding products
    // User can manually switch to cart tab when ready
  }
  
  void _removeFromCart(int productId) {
    setState(() {
      _cart.remove(productId);
    });
  }
  
  void _updateCartItemQuantity(int productId, double newQuantity) {
    if (newQuantity <= 0) {
      _removeFromCart(productId);
      return;
    }
    
    final item = _cart[productId];
    if (item == null) return;
    
    if (newQuantity > item.product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${item.product.quantity} kg available'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() {
      _cart[productId] = CartItem(
        product: item.product,
        quantity: newQuantity,
        unitPrice: item.unitPrice,
        subtotal: newQuantity * item.unitPrice,
      );
    });
  }
  
  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }
  
  Future<void> _completeSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty. Add products to continue.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    
    // Show customer info and payment dialog
    final confirmed = await _showCheckoutDialog();
    if (confirmed != true) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = authProvider.user?.shopId;
      final userId = authProvider.user?.id;
      
      if (shopId == null || userId == null) {
        throw Exception('Shop or user information not available');
      }
      
      // Prepare sale data
      final saleData = {
        'shop': shopId,
        'sold_by': userId,
        'customer_name': _customerNameController.text.trim().isEmpty 
            ? null 
            : _customerNameController.text.trim(),
        'customer_phone': _customerPhoneController.text.trim().isEmpty 
            ? null 
            : _customerPhoneController.text.trim(),
        'payment_method': _paymentMethod,
        'total_amount': _cartTotal,
        'items': _cart.values.map((item) => {
          'product': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'subtotal': item.subtotal,
        }).toList(),
      };
      
      // Create sale
      final sale = await _saleService.createSale(saleData);
      
      setState(() => _isProcessing = false);

      // Show success dialog with print option
      if (mounted) {
        final shouldPrint = await _showSuccessDialog(sale);

        // Clear cart and customer info
        _clearCart();
        _customerNameController.clear();
        _customerPhoneController.clear();

        // Force refresh products from backend (not cache)
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        await productProvider.fetchProducts();

        // Add another small delay to ensure UI updates
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Print receipt if user chose to
        if (shouldPrint == true && mounted) {
          await ReceiptPrinter.printSaleReceipt(context, sale);
        }
        
        // Navigate back
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete sale: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
  
  Future<bool?> _showCheckoutDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          'Complete Sale',
          style: AppTypography.headlineMedium(),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Information (Optional)',
                style: AppTypography.titleMedium(),
              ),
              const SizedBox(height: AppTheme.space12),
              CustomTextField(
                controller: _customerNameController,
                label: 'Customer Name',
                hint: 'Enter customer name',
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: AppTheme.space12),
              CustomTextField(
                controller: _customerPhoneController,
                label: 'Phone Number',
                hint: 'Enter phone number',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              const SizedBox(height: AppTheme.space24),
              Text(
                'Payment Method',
                style: AppTypography.titleMedium(),
              ),
              const SizedBox(height: AppTheme.space12),
              CustomDropdownField<String>(
                value: _paymentMethod,
                items: [
                  {'value': 'cash', 'label': 'Cash'},
                  {'value': 'card', 'label': 'Card'},
                  {'value': 'mobile_money', 'label': 'Mobile Money'},
                ].map((method) {
                  return DropdownMenuItem(
                    value: method['value'],
                    child: Text(method['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _paymentMethod = value);
                  }
                },
              ),
              const SizedBox(height: AppTheme.space24),
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppColors.shopPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: AppTypography.titleMedium(),
                    ),
                    Text(
                      'TZS ${_cartTotal.toStringAsFixed(2)}',
                      style: AppTypography.headlineMedium().copyWith(
                        color: AppColors.shopPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          CustomButton(
            variant: ButtonVariant.secondary,
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CustomButton(
            label: 'Confirm Sale',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
  
  Future<bool?> _showSuccessDialog(Sale sale) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 32,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                'Sale Completed!',
                style: AppTypography.headlineMedium(),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sale #${sale.id ?? 'N/A'} has been completed successfully.',
              style: AppTypography.bodyMedium(),
            ),
            const SizedBox(height: AppTheme.space16),
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppColors.shopPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount:',
                        style: AppTypography.bodyMedium(),
                      ),
                      Text(
                        'TZS ${sale.totalAmount.toStringAsFixed(2)}',
                        style: AppTypography.titleLarge().copyWith(
                          color: AppColors.shopPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment:',
                        style: AppTypography.bodyMedium(),
                      ),
                      Text(
                        sale.paymentMethod,
                        style: AppTypography.bodyMedium().copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (sale.customerName != null) ...[
                    const SizedBox(height: AppTheme.space8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Customer:',
                          style: AppTypography.bodyMedium(),
                        ),
                        Text(
                          sale.customerName!,
                          style: AppTypography.bodyMedium().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.print,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      'Would you like to print a receipt for this sale?',
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CustomButton(
            variant: ButtonVariant.secondary,
            label: 'Skip',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CustomButton(
            label: 'Print Receipt',
            icon: Icons.print,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Sell Products',
          style: AppTypography.headlineMedium(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.shopPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.shopPrimary,
          tabs: [
            Tab(
              icon: const Icon(Icons.inventory_2),
              text: 'Select Products',
            ),
            Tab(
              icon: Badge(
                label: _cartItemCount > 0 ? Text('$_cartItemCount') : null,
                child: const Icon(Icons.shopping_cart),
              ),
              text: 'Cart',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildCartTab(),
        ],
      ),
      bottomNavigationBar: _cart.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: AppTypography.bodyMedium().copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'TZS ${_cartTotal.toStringAsFixed(2)}',
                            style: AppTypography.headlineMedium().copyWith(
                              color: AppColors.shopPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.space16),
                    Expanded(
                      child: CustomButton(
                        label: 'Complete Sale',
                        icon: Icons.check_circle,
                        onPressed: _isProcessing ? null : _completeSale,
                        loading: _isProcessing,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
  
  Widget _buildProductsTab() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.shopPrimary,
            ),
          );
        }
        
        final authProvider = Provider.of<AuthProvider>(context);
        final currentShopId = authProvider.user?.shopId;
        
        // Filter products available in this shop with stock
        final availableProducts = productProvider.products
            .where((p) => p.receivedBy == currentShopId && p.quantity > 0)
            .toList();
        
        if (availableProducts.isEmpty) {
          return Center(
            child: EmptyStateCard(
              icon: Icons.inventory_2,
              message: 'No Products Available',
              subtitle: 'No products in stock to sell.',
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.space16),
          itemCount: availableProducts.length,
          itemBuilder: (context, index) {
            final product = availableProducts[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }
  
  Widget _buildProductCard(Product product) {
    final quantityController = TextEditingController(text: '1.0');
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.shopPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: AppColors.shopPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.titleMedium().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Batch: ${product.batchNumber ?? 'N/A'}',
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space8,
                            vertical: AppTheme.space4,
                          ),
                          decoration: BoxDecoration(
                            color: product.quantity > 10
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            '${product.quantity} kg available',
                            style: AppTypography.labelSmall().copyWith(
                              color: product.quantity > 10
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'TZS ${product.price.toStringAsFixed(2)}/kg',
                      style: AppTypography.titleMedium().copyWith(
                        color: AppColors.shopPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                child: NumberTextField(
                  controller: quantityController,
                  label: 'Qty (kg)',
                  allowDecimals: true,
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              CustomButton(
                icon: Icons.add_shopping_cart,
                label: 'Add',
                size: ButtonSize.small,
                onPressed: () {
                  final quantity = double.tryParse(quantityController.text) ?? 0;
                  _addToCart(product, quantity);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCartTab() {
    if (_cart.isEmpty) {
      return Center(
        child: EmptyStateCard(
          icon: Icons.shopping_cart_outlined,
          message: 'Cart is Empty',
          subtitle: 'Add products from the inventory to start selling.',
          action: CustomButton(
            label: 'Browse Products',
            onPressed: () => _tabController.animateTo(0),
          ),
        ),
      );
    }
    
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.space16),
            itemCount: _cart.length,
            itemBuilder: (context, index) {
              final item = _cart.values.elementAt(index);
              return _buildCartItemCard(item);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: CustomButton(
              label: 'Clear Cart',
              icon: Icons.delete_outline,
              variant: ButtonVariant.secondary,
              customColor: AppColors.error,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text('Are you sure you want to clear all items from the cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _clearCart();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCartItemCard(CartItem item) {
    final quantityController = TextEditingController(
      text: item.quantity.toStringAsFixed(1),
    );
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: AppTypography.titleMedium().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Batch: ${item.product.batchNumber ?? 'N/A'}',
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () => _removeFromCart(item.product.id!),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unit Price',
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'TZS ${item.unitPrice.toStringAsFixed(2)}/kg',
                      style: AppTypography.bodyMedium(),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                child: NumberTextField(
                  controller: quantityController,
                  label: 'Qty (kg)',
                  allowDecimals: true,
                  onChanged: (value) {
                    final newQuantity = double.tryParse(value) ?? 0;
                    _updateCartItemQuantity(item.product.id!, newQuantity);
                  },
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Subtotal',
                    style: AppTypography.bodySmall().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'TZS ${item.subtotal.toStringAsFixed(2)}',
                    style: AppTypography.titleMedium().copyWith(
                      color: AppColors.shopPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CartItem {
  final Product product;
  final double quantity;
  final double unitPrice;
  final double subtotal;
  
  CartItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });
}