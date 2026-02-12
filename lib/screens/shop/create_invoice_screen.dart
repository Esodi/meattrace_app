import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/invoice.dart';
import '../../models/product.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../widgets/core/custom_button.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _customerTinController =
      TextEditingController(); // This matches backend model but might not be used if moved to header
  final _customerRefController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _issueDate = DateTime.now();
  DateTime? _dueDate;
  final List<InvoiceItem> _items = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _customerAddressController.dispose();
    _customerTinController.dispose();
    _customerRefController.dispose();
    _paymentTermsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create Invoice', style: AppTypography.headlineMedium()),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCustomerSection(),
            const SizedBox(height: 24),
            _buildDatesSection(),
            const SizedBox(height: 24),
            _buildItemsSection(),
            const SizedBox(height: 24),
            _buildNotesSection(),
            const SizedBox(height: 24),
            _buildSummary(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: AppTypography.titleMedium().copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.shopPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerRefController,
              decoration: const InputDecoration(
                labelText: 'Customer Reference (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bookmark_border),
                hintText: 'e.g. Order #1234',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter customer name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerTinController,
              decoration: const InputDecoration(
                labelText: 'Customer TIN (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customerPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _customerEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerAddressController,
              decoration: const InputDecoration(
                labelText: 'Physical Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dates',
              style: AppTypography.titleMedium().copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.shopPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Issue Date'),
              subtitle: Text(_issueDate.toString().split(' ')[0]),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _issueDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _issueDate = date);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Due Date (Optional)'),
              subtitle: Text(_dueDate?.toString().split(' ')[0] ?? 'Not set'),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: _issueDate,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _dueDate = date);
                }
              },
            ),
            TextFormField(
              controller: _paymentTermsController,
              decoration: const InputDecoration(
                labelText: 'Payment Terms (Optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Net 30, Due on receipt',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items',
                  style: AppTypography.titleMedium().copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.shopPrimary,
                  ),
                ),
                CustomButton(
                  label: 'Add',
                  icon: Icons.add,
                  onPressed: _addItem,
                  variant: ButtonVariant.text,
                  size: ButtonSize.small,
                  customColor: AppColors.shopPrimary,
                ),
              ],
            ),
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No items added yet')),
              )
            else
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildItemCard(item, index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(InvoiceItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey[50],
      child: ListTile(
        title: Text(item.productName ?? 'Product ${item.product}'),
        subtitle: Text(
          'Weight: ${item.quantity.toStringAsFixed(1)} kg × TZS ${item.unitPrice}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TZS ${item.subtotal.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() => _items.removeAt(index));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    if (productProvider.products.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No products available')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        products: productProvider.products,
        onAdd: (item) {
          setState(() => _items.add(item));
        },
      ),
    );
  }

  Widget _buildNotesSection() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (Optional)',
        border: OutlineInputBorder(),
        hintText: 'Add any additional notes or terms',
      ),
      maxLines: 3,
    );
  }

  Widget _buildSummary() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                Text(
                  'TZS ${_subtotal.toStringAsFixed(0)}',
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
    );
  }

  Widget _buildSubmitButton() {
    return CustomButton(
      label: 'Create Invoice',
      onPressed: _isSubmitting ? null : _submitInvoice,
      loading: _isSubmitting,
      variant: ButtonVariant.primary,
      fullWidth: true,
      customColor: AppColors.shopPrimary,
    );
  }

  Future<void> _submitInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = authProvider.user?.shopId;

      if (shopId == null) {
        throw Exception('No shop associated with user');
      }

      final invoice = Invoice(
        invoiceNumber: '',
        shop: shopId,
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
        customerEmail: _customerEmailController.text,
        customerAddress: _customerAddressController.text,
        customerTin: _customerTinController.text,
        customerRef: _customerRefController.text,
        issueDate: _issueDate,
        dueDate: _dueDate,
        paymentTerms: _paymentTermsController.text.isNotEmpty
            ? _paymentTermsController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        items: _items,
      );

      final invoiceProvider = Provider.of<InvoiceProvider>(
        context,
        listen: false,
      );
      await invoiceProvider.createInvoice(invoice);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice created successfully'),
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _AddItemDialog extends StatefulWidget {
  final List<Product> products;
  final Function(InvoiceItem) onAdd;

  const _AddItemDialog({required this.products, required this.onAdd});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  Product? _selectedProduct;
  final _quantityController = TextEditingController(text: '1.0');
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Product>(
            initialValue: _selectedProduct,
            decoration: const InputDecoration(
              labelText: 'Product',
              border: OutlineInputBorder(),
            ),
            items: widget.products.map((product) {
              return DropdownMenuItem(
                value: product,
                child: Text(product.name),
              );
            }).toList(),
            onChanged: (product) {
              setState(() {
                _selectedProduct = product;
                _priceController.text = product?.price.toString() ?? '';
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Unit Price',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedProduct != null &&
                _quantityController.text.isNotEmpty &&
                _priceController.text.isNotEmpty) {
              final item = InvoiceItem(
                product: _selectedProduct!.id!,
                productName: _selectedProduct!.name,
                quantity: double.parse(_quantityController.text),
                unitPrice: double.parse(_priceController.text),
              );
              widget.onAdd(item);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
