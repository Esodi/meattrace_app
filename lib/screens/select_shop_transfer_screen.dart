import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../utils/theme.dart';
import '../widgets/enhanced_back_button.dart';

class SelectShopTransferScreen extends StatefulWidget {
  const SelectShopTransferScreen({super.key});

  @override
  State<SelectShopTransferScreen> createState() => _SelectShopTransferScreenState();
}

class _SelectShopTransferScreenState extends State<SelectShopTransferScreen> {
  late ProductProvider _productProvider;
  late AuthProvider _authProvider;
  List<Map<String, dynamic>> _shops = [];
  List<Product> _selectedProducts = [];
  bool _isLoading = true;
  bool _isTransferring = false;
  Map<String, dynamic>? _selectedShop;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _productProvider = Provider.of<ProductProvider>(context, listen: false);
      _authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Get selected products from route extra
      final extra = GoRouterState.of(context).extra;
      if (extra is List<Product>) {
        _selectedProducts = extra;
      }

      _loadShops();
      _isInitialized = true;
    }
  }

  Future<void> _loadShops() async {
    setState(() => _isLoading = true);
    try {
      final shops = await _productProvider.getShops();
      setState(() {
        _shops = shops;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load shops: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createEnhancedAppBarWithBackButton(
        title: 'Select Shop',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShops,
          ),
        ],
        fallbackRoute: '/processor-home',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shops.isEmpty
              ? _buildEmptyState()
              : _buildShopsList(),
      floatingActionButton: _selectedShop != null
          ? FloatingActionButton(
              heroTag: null,
              onPressed: _isTransferring ? null : _initiateTransfer,
              backgroundColor: AppTheme.accentOrange,
              child: _isTransferring
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Icon(Icons.send),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No shops available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact administrator to register shops',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShopsList() {
    debugPrint('Building shops list, selected shop: $_selectedShop, offstage: ${_selectedShop == null}');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transfer ${_selectedProducts.length} product(s) to:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selected products: ${_selectedProducts.length} item(s)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RadioGroup<Map<String, dynamic>>(
            groupValue: _selectedShop,
            onChanged: (Map<String, dynamic>? value) {
              debugPrint('Shop selection changed: ${value?['username']}, id: ${value?['id']}');
              setState(() {
                _selectedShop = value;
              });
            },
            child: ListView.builder(
              itemCount: _shops.length,
              itemBuilder: (context, index) {
                final shop = _shops[index];
                final isSelected = _selectedShop?['id'] == shop['id'];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SizedBox(
                    height: 70,
                    child: RadioListTile<Map<String, dynamic>>(
                      title: Text(
                        shop['username'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        shop['email'],
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: shop,
                      activeColor: AppTheme.accentOrange,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.backgroundGray,
          child: _selectedShop != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transfer to: ${_selectedShop!['username']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentOrange,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_selectedProducts.length} product(s) selected',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isTransferring ? null : _initiateTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isTransferring
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Transfer'),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _initiateTransfer() async {
    if (_selectedShop == null || _selectedProducts.isEmpty) return;

    setState(() => _isTransferring = true);

    try {
      final shopId = _selectedShop!['id'];
      final productIds = _selectedProducts.where((product) => product.id != null).map((product) => product.id!).toList();

      final response = await _productProvider.transferProducts(productIds, shopId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Transfer completed successfully'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to processor home
        context.go('/processor-home');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isTransferring = false);
    }
  }
}







