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

class _SellScreenState extends State<SellScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SaleService _saleService = SaleService();

  // Cart items: Map<productId, CartItem>
  final Map<int, CartItem> _cart = {};

  // Track toggle state for weight vs quantity for each product
  // NOT USED ANYMORE - we now allow both quantity and weight
  // final Map<int, bool> _useWeight = {};

  // Controllers for quantity and weight per product (by product ID)
  final Map<int, TextEditingController> _qtyControllers = {};
  final Map<int, TextEditingController> _weightControllers = {};

  // Customer info
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();

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
    // Dispose all product controllers
    for (var controller in _qtyControllers.values) {
      controller.dispose();
    }
    for (var controller in _weightControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _cartTotal {
    return _cart.values.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  int get _cartItemCount {
    return _cart.length;
  }

  void _addToCart(Product product, double quantity, double weight) {
    // Validate at least one is specified
    if (quantity <= 0 && weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter quantity or weight'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Validate quantity against stock
    if (quantity > 0 && quantity > product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only ${product.quantity.toStringAsFixed(0)} units available in stock',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate weight against stock
    if (weight > 0 && product.weight != null && weight > product.weight!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only ${product.weight!.toStringAsFixed(1)} ${product.weightUnit} available in stock',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      // Calculate subtotal: qty * price + weight * price
      // If both are specified, we calculate based on the mode
      // For simplicity: if qty > 0, use qty * price; if weight > 0, add weight * price
      double subtotal = 0;
      if (quantity > 0) {
        subtotal += quantity * product.price;
      }
      if (weight > 0) {
        subtotal += weight * product.price;
      }

      if (_cart.containsKey(product.id)) {
        final existingItem = _cart[product.id]!;
        final newQuantity = existingItem.quantity + quantity;
        final newWeight = existingItem.weight + weight;
        double newSubtotal = 0;
        if (newQuantity > 0) {
          newSubtotal += newQuantity * product.price;
        }
        if (newWeight > 0) {
          newSubtotal += newWeight * product.price;
        }

        _cart[product.id!] = CartItem(
          product: product,
          quantity: newQuantity,
          weight: newWeight,
          weightUnit: product.weightUnit,
          unitPrice: product.price,
          subtotal: newSubtotal,
        );
      } else {
        _cart[product.id!] = CartItem(
          product: product,
          quantity: quantity,
          weight: weight,
          weightUnit: product.weightUnit,
          unitPrice: product.price,
          subtotal: subtotal,
        );
      }
    });

    // Clear the input controllers after adding
    _qtyControllers[product.id]?.text = '';
    _weightControllers[product.id]?.text = '';

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
  }

  void _removeFromCart(int productId) {
    setState(() {
      _cart.remove(productId);
    });
  }

  void _updateCartItemQuantity(
    int productId,
    double newQuantity, {
    bool isWeight = false,
  }) {
    final item = _cart[productId];
    if (item == null) return;

    final updatedQty = isWeight ? item.quantity : newQuantity;
    final updatedWeight = isWeight ? newQuantity : item.weight;

    // Remove if both are zero or less
    if (updatedQty <= 0 && updatedWeight <= 0) {
      _removeFromCart(productId);
      return;
    }

    // Calculate new subtotal
    double newSubtotal = 0;
    if (updatedQty > 0) {
      newSubtotal += updatedQty * item.unitPrice;
    }
    if (updatedWeight > 0) {
      newSubtotal += updatedWeight * item.unitPrice;
    }

    setState(() {
      _cart[productId] = CartItem(
        product: item.product,
        quantity: updatedQty,
        weight: updatedWeight,
        weightUnit: item.weightUnit,
        unitPrice: item.unitPrice,
        subtotal: newSubtotal,
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
      if (!mounted) return;
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
        'items': _cart.values
            .map(
              (item) => {
                'product': item.product.id,
                'quantity': item.quantity,
                'weight': item.weight,
                'weight_unit': item.weightUnit,
                'unit_price': item.unitPrice,
                'subtotal': item.subtotal,
              },
            )
            .toList(),
      };

      // Create sale
      final sale = await _saleService.createSale(saleData);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Show success dialog with print option
      final shouldPrint = await _showSuccessDialog(sale);

      // Clear cart and customer info
      _clearCart();
      _customerNameController.clear();
      _customerPhoneController.clear();

      // Force refresh products from backend (not cache)
      if (!mounted) return;
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
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
        title: Text('Complete Sale', style: AppTypography.headlineMedium()),
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
              Text('Payment Method', style: AppTypography.titleMedium()),
              const SizedBox(height: AppTheme.space12),
              CustomDropdownField<String>(
                value: _paymentMethod,
                items:
                    [
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
                    Text('Total Amount:', style: AppTypography.titleMedium()),
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
                      Text('Total Amount:', style: AppTypography.bodyMedium()),
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
                      Text('Payment:', style: AppTypography.bodyMedium()),
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
                        Text('Customer:', style: AppTypography.bodyMedium()),
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
                  const Icon(Icons.print, color: AppColors.info, size: 20),
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
        title: Text('Sell Products', style: AppTypography.headlineMedium()),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.shopPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.shopPrimary,
          tabs: [
            Tab(icon: const Icon(Icons.inventory_2), text: 'Select Products'),
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
        children: [_buildProductsTab(), _buildCartTab()],
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
            child: CircularProgressIndicator(color: AppColors.shopPrimary),
          );
        }

        final authProvider = Provider.of<AuthProvider>(context);
        final currentShopId = authProvider.user?.shopId;

        // Filter products available in this shop with stock
        final availableProducts = productProvider.products
            .where((p) => p.receivedByShopId == currentShopId && p.quantity > 0)
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
    // Get or create controllers for this product
    _qtyControllers[product.id!] ??= TextEditingController();
    _weightControllers[product.id!] ??= TextEditingController();

    final qtyController = _qtyControllers[product.id!]!;
    final weightController = _weightControllers[product.id!]!;

    final hasWeight = product.weight != null && product.weight! > 0;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Info Row
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.shopPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: AppColors.shopPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.titleMedium().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Batch: ${product.batchNumber}',
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TZS ${product.price.toStringAsFixed(0)}',
                    style: AppTypography.titleMedium().copyWith(
                      color: AppColors.shopPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '/unit',
                    style: AppTypography.labelSmall().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),

          // Stock Info Row
          Row(
            children: [
              // Quantity stock
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space8,
                  vertical: AppTheme.space4,
                ),
                decoration: BoxDecoration(
                  color: product.quantity > 5
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  '${product.quantity.toStringAsFixed(0)} units',
                  style: AppTypography.labelSmall().copyWith(
                    color: product.quantity > 5
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (hasWeight) ...[
                const SizedBox(width: AppTheme.space8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                    vertical: AppTheme.space4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    '${product.weight!.toStringAsFixed(1)} ${product.weightUnit}',
                    style: AppTypography.labelSmall().copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.space12),

          // Input Row - Quantity and Weight
          Row(
            children: [
              // Quantity Input
              Expanded(
                child: NumberTextField(
                  controller: qtyController,
                  label: 'Qty (units)',
                  allowDecimals: false,
                ),
              ),
              if (hasWeight) ...[
                const SizedBox(width: AppTheme.space8),
                // Weight Input
                Expanded(
                  child: NumberTextField(
                    controller: weightController,
                    label: 'Weight (${product.weightUnit})',
                    allowDecimals: true,
                  ),
                ),
              ],
              const SizedBox(width: AppTheme.space8),
              // Add to Cart Button
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton.filled(
                  onPressed: () {
                    final qty = double.tryParse(qtyController.text) ?? 0;
                    final wt = double.tryParse(weightController.text) ?? 0;
                    _addToCart(product, qty, wt);
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.shopPrimary,
                    foregroundColor: Colors.white,
                  ),
                ),
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
                    content: const Text(
                      'Are you sure you want to clear all items from the cart?',
                    ),
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
    final qtyController = TextEditingController(
      text: item.quantity > 0 ? item.quantity.toStringAsFixed(0) : '',
    );
    final weightController = TextEditingController(
      text: item.weight > 0 ? item.weight.toStringAsFixed(1) : '',
    );

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row - Product Name and Delete
          Row(
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.product.name,
                      style: AppTypography.titleMedium().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Batch: ${item.product.batchNumber}',
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: AppTheme.space12),

          // Price Row
          Text(
            'Unit Price: TZS ${item.unitPrice.toStringAsFixed(2)}',
            style: AppTypography.bodySmall().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space12),

          // Quantity and Weight Row
          Row(
            children: [
              // Quantity Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Quantity',
                      style: AppTypography.labelSmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: NumberTextField(
                            controller: qtyController,
                            label: '',
                            allowDecimals: false,
                            onChanged: (value) {
                              final newVal = double.tryParse(value) ?? 0;
                              _updateCartItemQuantity(
                                item.product.id!,
                                newVal,
                                isWeight: false,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Text(
                          'units',
                          style: AppTypography.bodySmall().copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Weight Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Weight',
                      style: AppTypography.labelSmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: NumberTextField(
                            controller: weightController,
                            label: '',
                            allowDecimals: true,
                            onChanged: (value) {
                              final newVal = double.tryParse(value) ?? 0;
                              _updateCartItemQuantity(
                                item.product.id!,
                                newVal,
                                isWeight: true,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Text(
                          item.weightUnit,
                          style: AppTypography.bodySmall().copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Subtotal
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Subtotal',
                    style: AppTypography.labelSmall().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    'TZS ${item.subtotal.toStringAsFixed(0)}',
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
  final double weight;
  final String weightUnit;
  final double unitPrice;
  final double subtotal;

  CartItem({
    required this.product,
    required this.quantity,
    required this.weight,
    required this.weightUnit,
    required this.unitPrice,
    required this.subtotal,
  });
}
