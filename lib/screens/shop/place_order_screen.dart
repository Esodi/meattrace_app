import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/processing_unit.dart';
import '../../services/dio_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_card.dart';

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  List<ProcessingUnit> _processingUnits = [];
  List<Product> _availableProducts = [];
  ProcessingUnit? _selectedUnit;
  final Map<Product, double> _cart = {};
  final _deliveryAddressController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProcessingUnits();
  }

  @override
  void dispose() {
    _deliveryAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProcessingUnits() async {
    setState(() => _isLoading = true);
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/processing-units/');
      final units = (response.data['results'] as List)
          .map((json) => ProcessingUnit.fromJson(json))
          .toList();

      setState(() => _processingUnits = units);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading processing units: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProducts(int processingUnitId) async {
    setState(() => _isLoading = true);
    try {
      final dio = DioClient().dio;
      final response = await dio.get(
        '/products/',
        queryParameters: {'processing_unit': processingUnitId},
      );

      final products = (response.data['results'] as List)
          .map((json) => Product.fromMap(json))
          .where(
            (product) => (product.weight ?? 0) > 0 && product.transferredTo == null,
          )
          .toList();

      setState(() => _availableProducts = products);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to your order')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dio = DioClient().dio;

      // Calculate total
      double totalAmount = 0;
      final orderItems = _cart.entries.map((entry) {
        final subtotal = entry.key.price * entry.value;
        totalAmount += subtotal;
        return {
          'product_id': entry.key.id,
          'quantity': entry.value,
          'weight': entry.value,
          'weight_unit': entry.key.weightUnit,
          'unit_price': entry.key.price,
          'subtotal': subtotal,
        };
      }).toList();

      // Create order
      final orderData = {
        'shop': _selectedUnit!.id,
        'delivery_address': _deliveryAddressController.text.trim(),
        'notes': _notesController.text.trim(),
        'total_amount': totalAmount,
        'items': orderItems,
      };

      await dio.post('/orders/', data: orderData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error placing order: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Place Order', style: AppTypography.headlineMedium()),
            Text(
              'Order from processing units',
              style: AppTypography.bodySmall().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          if (_cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.space16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space12,
                    vertical: AppTheme.space6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.shopPrimary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.white, size: 16),
                      const SizedBox(width: AppTheme.space4),
                      Text(
                        '${_cart.length}',
                        style: AppTypography.labelMedium().copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.shopPrimary),
            )
          : Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: AppColors.shopPrimary),
              ),
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep == 0 && _selectedUnit == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a supplier')),
                    );
                    return;
                  }
                  if (_currentStep == 1 && _cart.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please add items to your order'),
                      ),
                    );
                    return;
                  }
                  if (_currentStep < 2) {
                    setState(() => _currentStep++);
                  } else {
                    _submitOrder();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  }
                },
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppTheme.space16),
                    child: Row(
                      children: [
                        CustomButton(
                          label: _currentStep == 2 ? 'Place Order' : 'Continue',
                          customColor: AppColors.shopPrimary,
                          onPressed: details.onStepContinue,
                        ),
                        if (_currentStep > 0) ...[
                          const SizedBox(width: AppTheme.space12),
                          CustomButton(
                            label: 'Back',
                            variant: ButtonVariant.secondary,
                            onPressed: details.onStepCancel,
                          ),
                        ],
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: Text(
                      'Select Supplier',
                      style: AppTypography.titleMedium(),
                    ),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0
                        ? StepState.complete
                        : StepState.indexed,
                    content: _buildSelectSupplierStep(),
                  ),
                  Step(
                    title: Text(
                      'Select Products',
                      style: AppTypography.titleMedium(),
                    ),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1
                        ? StepState.complete
                        : StepState.indexed,
                    content: _buildSelectProductsStep(),
                  ),
                  Step(
                    title: Text(
                      'Review & Confirm',
                      style: AppTypography.titleMedium(),
                    ),
                    isActive: _currentStep >= 2,
                    content: _buildReviewStep(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectSupplierStep() {
    if (_processingUnits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space32),
          child: Column(
            children: [
              Icon(
                Icons.factory_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppTheme.space16),
              Text(
                'No suppliers available',
                style: AppTypography.headlineMedium().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _processingUnits.length,
      itemBuilder: (context, index) {
        final unit = _processingUnits[index];
        final isSelected = _selectedUnit?.id == unit.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.space8),
          child: CustomCard(
            padding: EdgeInsets.zero,
            borderColor: isSelected ? AppColors.shopPrimary : null,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedUnit = unit;
                  _cart.clear();
                });
                _loadProducts(unit.id!);
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: AppColors.processorPrimary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: Icon(
                        Icons.factory,
                        color: AppColors.processorPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.name,
                            style: AppTypography.titleMedium().copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (unit.location != null) ...[
                            const SizedBox(height: AppTheme.space4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppTheme.space4),
                                Expanded(
                                  child: Text(
                                    unit.location!,
                                    style: AppTypography.bodySmall().copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (unit.contactPhone != null) ...[
                            const SizedBox(height: AppTheme.space4),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppTheme.space4),
                                Text(
                                  unit.contactPhone!,
                                  style: AppTypography.bodySmall().copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.shopPrimary,
                        size: 28,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectProductsStep() {
    if (_selectedUnit == null) {
      return const Center(child: Text('Please select a supplier first'));
    }

    if (_availableProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No products available from this supplier',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _availableProducts.length,
          itemBuilder: (context, index) {
            final product = _availableProducts[index];
            final selectedWeight = _cart[product] ?? 0.0;
            final availableWeight = product.weight ?? product.quantity;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Batch: ${product.batchNumber}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '\$${product.price.toStringAsFixed(2)} per ${product.weightUnit}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.shopPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${availableWeight.toStringAsFixed(1)} ${product.weightUnit} available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: selectedWeight > 0
                              ? () {
                                  setState(() {
                                    if (selectedWeight <= 1) {
                                      _cart.remove(product);
                                    } else {
                                      _cart[product] = selectedWeight - 1;
                                    }
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.shopPrimary,
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            selectedWeight.toStringAsFixed(1),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: selectedWeight < availableWeight
                              ? () {
                                  setState(() {
                                    _cart[product] = selectedWeight + 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppColors.shopPrimary,
                        ),
                        const Spacer(),
                        if (selectedWeight > 0)
                          Text(
                            'Subtotal: \$${(product.price * selectedWeight).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final totalAmount = _cart.entries.fold<double>(
      0,
      (sum, entry) => sum + (entry.key.price * entry.value),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.factory, color: AppColors.processorPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Supplier: ${_selectedUnit?.name ?? ""}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Items',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._cart.entries.map((entry) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(entry.key.name),
              subtitle: Text(
                '${entry.value.toStringAsFixed(1)} ${entry.key.weightUnit} × \$${entry.key.price.toStringAsFixed(2)}',
              ),
              trailing: Text(
                '\$${(entry.key.price * entry.value).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
        const Divider(height: 32),
        TextField(
          controller: _deliveryAddressController,
          decoration: const InputDecoration(
            labelText: 'Delivery Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.shopPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.shopPrimary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.shopPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
