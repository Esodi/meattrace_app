import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:meattrace_app/providers/animal_provider.dart';
// import 'package:meattrace_app/providers/product_provider.dart'; // Removed
import 'package:meattrace_app/providers/auth_provider.dart';
import 'package:meattrace_app/models/animal.dart';
// import 'package:meattrace_app/models/product.dart'; // Removed
import 'package:meattrace_app/utils/app_colors.dart';

/// Current Inventory Screen showing available raw materials
/// Tab 1: Raw Materials - Animals/parts received but not yet processed
class CurrentInventoryScreen extends StatefulWidget {
  const CurrentInventoryScreen({super.key});

  @override
  State<CurrentInventoryScreen> createState() => _CurrentInventoryScreenState();
}

class _CurrentInventoryScreenState extends State<CurrentInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  // Raw materials data
  List<Animal> _receivedAnimals = [];
  List<SlaughterPart> _receivedParts = [];

  // Filter for raw materials
  String _rawMaterialsFilter = 'all'; // 'all', 'animals', 'parts'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final animalProvider = Provider.of<AnimalProvider>(
        context,
        listen: false,
      );
      // ProductProvider not needed anymore
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final processingUnitId = authProvider.user?.processingUnitId;

      // Load animals only - products not needed for this screen anymore
      await animalProvider.fetchAnimals();

      // Load slaughter parts separately since they're not cached in provider
      List<SlaughterPart> slaughterParts = [];
      try {
        slaughterParts = await animalProvider.getSlaughterPartsList();
      } catch (e) {
        debugPrint('Error loading slaughter parts: $e');
      }

      // Filter received animals that are not fully processed
      // Received animals have receivedBy set and have remaining_weight > 0
      _receivedAnimals = animalProvider.animals
          .where(
            (a) =>
                a.receivedBy != null &&
                a.transferredTo == processingUnitId &&
                (a.remainingWeight ?? 0) > 0,
          )
          .toList();

      // Filter received parts that are not fully processed
      _receivedParts = slaughterParts
          .where(
            (p) =>
                p.receivedBy != null &&
                p.transferredTo == processingUnitId &&
                (p.remainingWeight ?? p.weight) > 0,
          )
          .toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Inventory'),
        backgroundColor: AppColors.processorPrimary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Raw Materials'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : TabBarView(
              controller: _tabController,
              children: [_buildRawMaterialsTab()],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error loading inventory',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Tab 1: Raw Materials (animals and slaughter parts not yet processed)
  Widget _buildRawMaterialsTab() {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _rawMaterialsFilter == 'all',
                onSelected: (_) => setState(() => _rawMaterialsFilter = 'all'),
                selectedColor: AppColors.processorPrimary.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('Animals (${_receivedAnimals.length})'),
                selected: _rawMaterialsFilter == 'animals',
                onSelected: (_) =>
                    setState(() => _rawMaterialsFilter = 'animals'),
                selectedColor: AppColors.processorPrimary.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('Parts (${_receivedParts.length})'),
                selected: _rawMaterialsFilter == 'parts',
                onSelected: (_) =>
                    setState(() => _rawMaterialsFilter = 'parts'),
                selectedColor: AppColors.processorPrimary.withOpacity(0.2),
              ),
            ],
          ),
        ),
        // Stats summary
        _buildRawMaterialsSummary(),
        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _buildRawMaterialsList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRawMaterialsSummary() {
    final totalAnimals = _receivedAnimals.length;
    final totalParts = _receivedParts.length;
    final totalAnimalWeight = _receivedAnimals.fold<double>(
      0,
      (sum, a) => sum + (a.remainingWeight ?? 0),
    );
    final totalPartWeight = _receivedParts.fold<double>(
      0,
      (sum, p) => sum + (p.remainingWeight ?? p.weight),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.processorPrimary.withOpacity(0.1),
            AppColors.processorPrimary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.processorPrimary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            Icons.pets,
            '$totalAnimals',
            'Animals',
            '${totalAnimalWeight.toStringAsFixed(1)} kg',
          ),
          Container(height: 40, width: 1, color: Colors.grey.shade300),
          _buildSummaryItem(
            Icons.content_cut,
            '$totalParts',
            'Parts',
            '${totalPartWeight.toStringAsFixed(1)} kg',
          ),
          Container(height: 40, width: 1, color: Colors.grey.shade300),
          _buildSummaryItem(
            Icons.scale,
            (totalAnimalWeight + totalPartWeight).toStringAsFixed(1),
            'Total',
            'kg available',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String value,
    String label,
    String subtitle,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppColors.processorPrimary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildRawMaterialsList() {
    final List<dynamic> items = [];

    if (_rawMaterialsFilter == 'all' || _rawMaterialsFilter == 'animals') {
      items.addAll(_receivedAnimals.map((a) => {'type': 'animal', 'data': a}));
    }
    if (_rawMaterialsFilter == 'all' || _rawMaterialsFilter == 'parts') {
      items.addAll(_receivedParts.map((p) => {'type': 'part', 'data': p}));
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No raw materials available',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Receive animals or parts to see them here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item['type'] == 'animal') {
          return _buildAnimalCard(item['data'] as Animal);
        } else {
          return _buildPartCard(item['data'] as SlaughterPart);
        }
      },
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    final remainingWeight = animal.remainingWeight ?? 0;
    final originalWeight = animal.liveWeight ?? 0;
    final usedPercentage = originalWeight > 0
        ? ((originalWeight - remainingWeight) / originalWeight * 100).clamp(
            0,
            100,
          )
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.processorPrimary.withOpacity(0.1),
          child: Icon(Icons.pets, color: AppColors.processorPrimary),
        ),
        title: Text(
          animal.animalName ?? animal.animalId,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${animal.species} • ${animal.breed ?? 'Unknown breed'}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: usedPercentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      usedPercentage > 80
                          ? Colors.red
                          : AppColors.processorPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${remainingWeight.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: remainingWeight > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () => context.push('/animals/${animal.id}'),
        ),
        isThreeLine: true,
        onTap: () => context.push('/animals/${animal.id}'),
      ),
    );
  }

  Widget _buildPartCard(SlaughterPart part) {
    final remainingWeight = part.remainingWeight ?? part.weight;
    final originalWeight = part.weight;
    final usedPercentage = originalWeight > 0
        ? ((originalWeight - remainingWeight) / originalWeight * 100).clamp(
            0,
            100,
          )
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.1),
          child: Icon(Icons.content_cut, color: Colors.orange.shade700),
        ),
        title: Text(
          part.partType.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From Animal ${part.animalId}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: usedPercentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      usedPercentage > 80 ? Colors.red : Colors.orange.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${remainingWeight.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: remainingWeight > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          // Could navigate to part detail if available
        },
      ),
    );
  }
}
