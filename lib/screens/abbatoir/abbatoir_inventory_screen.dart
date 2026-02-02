import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/animal_provider.dart';
import '../../models/animal.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/status_badge.dart';

class AbbatoirInventoryScreen extends StatefulWidget {
  const AbbatoirInventoryScreen({super.key});

  @override
  State<AbbatoirInventoryScreen> createState() =>
      _AbbatoirInventoryScreenState();
}

class _AbbatoirInventoryScreenState extends State<AbbatoirInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  List<Animal> _liveAnimals = [];
  List<Animal> _slaughteredAnimals = [];
  List<SlaughterPart> _slaughterParts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      // Load all animals
      await animalProvider.fetchAnimals(slaughtered: null);

      // Load slaughter parts
      List<SlaughterPart> parts = [];
      try {
        parts = await animalProvider.getSlaughterPartsList();
      } catch (e) {
        debugPrint('Error loading parts: $e');
      }

      // Filter: Current inventory means items that belong to this abattoir/user and NOT yet transferred
      // For abattoir, usually items are "created by" or "at" their unit.
      // Since 'abbatoir' field in Animal holds ID, we filter by that.

      _liveAnimals = animalProvider.animals
          .where(
            (a) =>
                !a.slaughtered &&
                a.transferredTo == null &&
                !a.animalId.startsWith('PART-HOLDER'),
          )
          .toList();

      _slaughteredAnimals = animalProvider.animals
          .where((a) => a.slaughtered && a.transferredTo == null)
          .toList();

      _slaughterParts = parts.where((p) => p.transferredTo == null).toList();

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
        title: const Text('Abattoir Inventory'),
        backgroundColor: AppColors.abbatoirPrimary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.pets), text: 'Live'),
            Tab(icon: Icon(Icons.checkroom), text: 'Slaughtered'),
            Tab(icon: Icon(Icons.restaurant), text: 'Parts'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_liveAnimals, 'animals'),
                _buildList(_slaughteredAnimals, 'animals'),
                _buildList(_slaughterParts, 'parts'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/abbatoir/stock'),
        backgroundColor: AppColors.abbatoirPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Stock'),
      ),
    );
  }

  Widget _buildList(List<dynamic> items, String type) {
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
              'No $type in stock',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.space16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (type == 'animals') {
            return _buildAnimalCard(item as Animal);
          } else {
            return _buildPartCard(item as SlaughterPart);
          }
        },
      ),
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.push('/animals/${animal.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.abbatoirPrimary.withOpacity(0.1),
              child: Icon(Icons.pets, color: AppColors.abbatoirPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
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
                              animal.animalName?.isNotEmpty == true
                                  ? animal.animalName!
                                  : animal.animalId,
                              style: AppTypography.titleMedium(),
                            ),
                            if (animal.animalName?.isNotEmpty == true)
                              Text(
                                'Tag: ${animal.animalId}',
                                style: AppTypography.bodySmall(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (animal.isExternal) _buildExternalBadge(),
                      StatusBadge(
                        label: animal.slaughtered ? 'Slaughtered' : 'Healthy',
                        color: animal.slaughtered
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${animal.species} • ${animal.breed ?? 'Unknown'}',
                    style: AppTypography.bodySmall(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${animal.liveWeight ?? 0} kg',
                    style: AppTypography.bodyMedium(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartCard(SlaughterPart part) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: const Icon(Icons.restaurant, color: Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          part.partType.displayName,
                          style: AppTypography.titleMedium(),
                        ),
                      ),
                      // Parts from abattoir stock screen are marked as isExternal in the animal they belong to
                      // But for simplicity in this view, we'll just show the part
                      StatusBadge(label: 'Available', color: Colors.green),
                    ],
                  ),
                  Text(
                    'From Tag: ${part.partId ?? 'N/A'}',
                    style: AppTypography.bodySmall(),
                  ),
                  Text(
                    '${part.weight} ${part.weightUnit}',
                    style: AppTypography.bodyMedium(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExternalBadge() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'External',
        style: TextStyle(
          fontSize: 10,
          color: Colors.purple.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error loading inventory', style: AppTypography.titleMedium()),
          Text(_error ?? 'Unknown error', style: AppTypography.bodySmall()),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }
}
