import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/animal_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/animal.dart';
import '../../models/product.dart';
import '../../widgets/core/custom_app_bar.dart';
import '../../widgets/core/enhanced_back_button.dart';

class InitialInventoryOnboardingScreen extends StatefulWidget {
  const InitialInventoryOnboardingScreen({super.key});

  @override
  State<InitialInventoryOnboardingScreen> createState() =>
      _InitialInventoryOnboardingScreenState();
}

class _InitialInventoryOnboardingScreenState
    extends State<InitialInventoryOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  final _nameController = TextEditingController(); // Name or Tag ID
  final _quantityController = TextEditingController(text: '1');
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _batchController = TextEditingController();
  String _weightUnit = 'kg';
  bool _isProcessing = false;

  // Type Selector
  String _selectedType = 'animal'; // 'animal' or 'product'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Auto-select tab based on role
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = context.read<AuthProvider>().user?.role.toLowerCase();
      if (role == 'shop' || role == 'processor' || role == 'processing_unit') {
        _tabController.animateTo(1);
        setState(() => _selectedType = 'product');
      }
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedType = _tabController.index == 0 ? 'animal' : 'product';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  Future<void> _submitInventory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;

      if (currentUser == null) throw Exception('User not logged in');

      if (_selectedType == 'animal') {
        // Create an "Initial Stock" Animal
        final animal = Animal(
          abbatoir: 0, // Placeholder
          abbatoirName: currentUser.username, // Self as source
          species: 'Not Specified', // Simplified for generic stock
          animalId: _nameController.text.trim(), // Tag ID
          age: 0, // Unknown
          createdAt: DateTime.now(),
          slaughtered: false,
          synced: false,
          isExternal: true, // Marked as external/initial
          originType: 'INITIAL_STOCK', // Special marker
          acquisitionDate: DateTime.now(),
          externalVendorName: 'Opening Stock', // System reserved name
          acquisitionPrice: double.tryParse(_priceController.text),
          liveWeight: double.tryParse(_weightController.text) ?? 50.0,
          remainingWeight: double.tryParse(_weightController.text) ?? 50.0,
          receivedBy: currentUser.id,
          receivedAt: DateTime.now(),
          transferredTo: currentUser.processingUnitId,
          transferredAt: DateTime.now(),
        );

        await context.read<AnimalProvider>().createAnimal(animal);
      } else {
        // Create an "Initial Stock" Product
        final product = Product(
          processingUnit: currentUser.processingUnitId ?? 0,
          processingUnitName: currentUser.processingUnitName,
          animal: 0, // No specific origin animal
          productType: 'meat', // Default
          quantity: double.tryParse(_quantityController.text) ?? 1.0,
          createdAt: DateTime.now(),
          name: _nameController.text.trim(),
          batchNumber: _batchController.text.isEmpty
              ? 'INIT-${DateTime.now().millisecondsSinceEpoch}'
              : _batchController.text,
          weight: double.tryParse(_weightController.text) ?? 1.0,
          weightUnit: _weightUnit,
          price: double.tryParse(_priceController.text) ?? 0.0,
          description: 'Registered as Opening Stock',
          manufacturer: currentUser.username,
          timeline: [],
          isExternal: true,
          externalVendorName: 'Opening Stock',
          acquisitionPrice: double.tryParse(_priceController.text) ?? 0.0,
          remainingWeight: double.tryParse(_weightController.text) ?? 1.0,
          receivedBy: currentUser.id,
          receivedAt: DateTime.now(),
          transferredTo: currentUser.processingUnitId,
          transferredAt: DateTime.now(),
        );

        await context.read<ProductProvider>().createProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventory Item Added Successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear form for next entry
        _nameController.clear();
        _weightController.clear();
        _priceController.clear();
        _batchController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding inventory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Register Opening Stock',
        leading: EnhancedBackButton(fallbackRoute: '/settings'),
      ),
      body: Column(
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.blue.shade800),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mid-Stream Entry',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use this screen to register items you currently own. They will be marked as "Opening Stock" to start traceability from your facility.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.pets), text: 'Animals'),
              Tab(icon: Icon(Icons.shopping_bag), text: 'Products'),
            ],
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_selectedType == 'animal') ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Animal Tag ID / Name',
                          hintText: 'e.g., COW-001',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Live Weight (kg)',
                          border: OutlineInputBorder(),
                          suffixText: 'kg',
                        ),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          hintText: 'e.g., Beef Rump Steak',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.restaurant),
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Weight',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _weightUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(),
                              ),
                              items: ['kg', 'g', 'lbs'].map((u) {
                                return DropdownMenuItem(
                                  value: u,
                                  child: Text(u),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _weightUnit = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _batchController,
                        decoration: const InputDecoration(
                          labelText: 'Batch Number (Optional)',
                          hintText: 'Leave empty to auto-generate',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Estimated Value / Cost',
                        border: OutlineInputBorder(),
                        prefixText: 'TZS ',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _submitInventory,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(
                          _isProcessing
                              ? 'Processing...'
                              : 'Add to ${_selectedType == 'animal' ? 'Livestock' : 'Inventory'}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
