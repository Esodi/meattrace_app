import 'package:flutter/material.dart';
import '../../models/animal.dart';
import '../../models/product.dart';
import '../../services/dio_client.dart';
import '../../utils/app_colors.dart';
import 'product_detail_screen.dart';
import '../farmer/animal_detail_screen.dart';

class ProcessorInventoryScreen extends StatefulWidget {
  const ProcessorInventoryScreen({Key? key}) : super(key: key);

  @override
  State<ProcessorInventoryScreen> createState() => _ProcessorInventoryScreenState();
}

class _ProcessorInventoryScreenState extends State<ProcessorInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Animal> _receivedAnimals = [];
  List<Product> _products = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dio = DioClient().dio;
      
      // Fetch received animals
      final animalsResponse = await dio.get('/animals/');
      final receivedAnimals = (animalsResponse.data['results'] as List)
          .map((json) => Animal.fromMap(json))
          .where((animal) => animal.receivedBy != null)
          .toList();
      
      // Fetch products
      final productsResponse = await dio.get('/products/');
      final products = (productsResponse.data['results'] as List)
          .map((json) => Product.fromMap(json))
          .toList();
      
      setState(() {
        _receivedAnimals = receivedAnimals;
        _products = products;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading inventory: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Received Animals', icon: Icon(Icons.pets)),
            Tab(text: 'Products', icon: Icon(Icons.inventory)),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          print('DEBUG: Screen height: ${constraints.maxHeight}, width: ${constraints.maxWidth}');
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search inventory...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),
              Expanded(
                child: Container(
                  height: constraints.maxHeight - 150, // Reserve space for search and app bar
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildReceivedAnimalsTab(),
                            _buildProductsTab(),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create product or receive animals
          if (_tabController.index == 0) {
            // Receive animals action
            Navigator.pushNamed(context, '/receive-animals');
          } else {
            // Create product action
            Navigator.pushNamed(context, '/create-product');
          }
        },
        backgroundColor: AppColors.processorPrimary,
        icon: Icon(_tabController.index == 0 ? Icons.download : Icons.add),
        label: Text(_tabController.index == 0 ? 'Receive' : 'Create'),
      ),
    );
  }

  Widget _buildReceivedAnimalsTab() {
    final filteredAnimals = _receivedAnimals.where((animal) {
      if (_searchQuery.isEmpty) return true;
      return animal.animalId.toLowerCase().contains(_searchQuery) ||
          animal.species.toLowerCase().contains(_searchQuery) ||
          (animal.breed?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    if (filteredAnimals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No animals received yet'
                  : 'No animals found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isEmpty)
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/receive-animals'),
                icon: const Icon(Icons.download),
                label: const Text('Receive Animals'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredAnimals.length,
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final animal = filteredAnimals[index];
          return _buildAnimalCard(animal);
        },
      ),
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimalDetailScreen(animalId: animal.id!.toString()),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.processorPrimary.withOpacity(0.1),
                    child: Icon(
                      _getSpeciesIcon(animal.species),
                      color: AppColors.processorPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal.animalId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${animal.species} ${animal.breed != null ? "• ${animal.breed}" : ""}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (animal.slaughtered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Text(
                        'Slaughtered',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.calendar_today, '${animal.age} years'),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.monitor_weight,
                    '${animal.liveWeight ?? 0} kg',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.local_hospital,
                    animal.healthStatus ?? 'Unknown',
                  ),
                ],
              ),
              if (animal.receivedAt != null) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.download_done, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Received: ${_formatDate(animal.receivedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    final filteredProducts = _products.where((product) {
      if (_searchQuery.isEmpty) return true;
      return product.name.toLowerCase().contains(_searchQuery) ||
          product.batchNumber.toLowerCase().contains(_searchQuery) ||
          product.productType.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No products yet' : 'No products found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isEmpty)
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/create-product'),
                icon: const Icon(Icons.add),
                label: const Text('Create Product'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredProducts.length,
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id!.toString()),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.processorPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: AppColors.processorPrimary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.processorPrimary,
                        ),
                      ),
                      Text(
                        'per ${product.weightUnit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.category, product.productType),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.monitor_weight,
                    '${product.weight ?? 0} ${product.weightUnit}',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.inventory, '${product.quantity.toInt()}'),
                ],
              ),
              if (product.transferredTo != null) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.local_shipping, size: 16, color: Colors.orange.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Transferred',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSpeciesIcon(String species) {
    switch (species.toLowerCase()) {
      case 'cow':
      case 'cattle':
        return Icons.agriculture;
      case 'pig':
        return Icons.pets;
      case 'chicken':
        return Icons.egg;
      case 'sheep':
      case 'goat':
        return Icons.cruelty_free;
      default:
        return Icons.pets;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
