import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/animal_provider.dart';
import '../../models/animal.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/status_badge.dart';

/// Livestock History Screen - View all registered animals
/// Features: Search, filters, list view, swipe actions
class LivestockHistoryScreen extends StatefulWidget {
  const LivestockHistoryScreen({super.key});

  @override
  State<LivestockHistoryScreen> createState() => _LivestockHistoryScreenState();
}

class _LivestockHistoryScreenState extends State<LivestockHistoryScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSpecies = 'All';
  String _selectedStatus = 'All';
  bool _isLoading = false;

  // Display names for species (UI labels)
  final List<String> _speciesOptions = ['All', 'Cattle', 'Pig', 'Chicken', 'Sheep', 'Goat'];
  
  // Map UI display names to backend values
  final Map<String, String> _speciesMapping = {
    'All': 'All',
    'Cattle': 'cow',
    'Pig': 'pig',
    'Chicken': 'chicken',
    'Sheep': 'sheep',
    'Goat': 'goat',
  };
  final List<String> _statusOptions = ['All', 'Healthy', 'Slaughtered', 'Transferred', 'Semi-Transferred'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      _loadAnimals();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload animals when app becomes active/resumed
    if (state == AppLifecycleState.resumed) {
      print('📋 [LivestockHistory] App resumed, reloading animals');
      _loadAnimals();
    }
  }

  @override
  void didUpdateWidget(LivestockHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload animals when widget updates
    print('📋 [LivestockHistory] didUpdateWidget - Reloading animals');
    _loadAnimals();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnimals() async {
    print('📋 [LivestockHistory] _loadAnimals - START');
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<AnimalProvider>(context, listen: false);
      print('📋 [LivestockHistory] Current animals count: ${provider.animals.length}');
      
      // Clear cache first to ensure fresh data
      await provider.clearAnimals();
      print('📋 [LivestockHistory] Cache cleared');
      
      // Fetch all animals (both active and slaughtered)
      await provider.fetchAnimals(slaughtered: null);
      print('📋 [LivestockHistory] After fetch, animals count: ${provider.animals.length}');
      
      // Log each animal for debugging
      for (var i = 0; i < provider.animals.length && i < 5; i++) {
        final animal = provider.animals[i];
        print('  [$i] ${animal.animalId} - ${animal.species} (slaughtered: ${animal.slaughtered})');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        print('📋 [LivestockHistory] _loadAnimals - COMPLETE');
      }
    }
  }

  List<Animal> _getFilteredAnimals(List<Animal> animals) {
    return animals.where((animal) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final matchesSearch = animal.animalId.toLowerCase().contains(searchLower) ||
            (animal.animalName?.toLowerCase().contains(searchLower) ?? false) ||
            animal.species.toLowerCase().contains(searchLower) ||
            (animal.breed?.toLowerCase().contains(searchLower) ?? false);
        if (!matchesSearch) return false;
      }

      // Species filter
      if (_selectedSpecies != 'All') {
        final backendSpecies = _speciesMapping[_selectedSpecies] ?? _selectedSpecies.toLowerCase();
        if (animal.species != backendSpecies) {
          return false;
        }
      }

      // Status filter - using lifecycle status
      if (_selectedStatus != 'All') {
        final lifecycleStatus = animal.computedLifecycleStatus;
        if (_selectedStatus == 'Healthy' && lifecycleStatus != AnimalLifecycleStatus.healthy) return false;
        if (_selectedStatus == 'Slaughtered' && lifecycleStatus != AnimalLifecycleStatus.slaughtered) return false;
        if (_selectedStatus == 'Transferred' && lifecycleStatus != AnimalLifecycleStatus.transferred) return false;
        if (_selectedStatus == 'Semi-Transferred' && lifecycleStatus != AnimalLifecycleStatus.semiTransferred) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.farmerPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Livestock History',
          style: AppTypography.headlineMedium(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),

            // Filter Chips
            _buildFilterChips(),

            // Animals List
            Expanded(
              child: _buildAnimalsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to register screen and reload animals when returning
          await context.push('/register-animal');
          // Reload animals after returning from registration
          print('📋 [LivestockHistory] Returned from registration, reloading...');
          if (mounted) {
            _loadAnimals();
          }
        },
        backgroundColor: AppColors.farmerPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search animals...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            label: _selectedSpecies,
            icon: Icons.pets,
            onTap: () => _showSpeciesFilter(),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: _selectedStatus,
            icon: Icons.health_and_safety,
            onTap: () => _showStatusFilter(),
          ),
          const SizedBox(width: 8),
          if (_selectedSpecies != 'All' || _selectedStatus != 'All')
            _buildFilterChip(
              label: 'Clear',
              icon: Icons.clear,
              onTap: _clearFilters,
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color ?? AppColors.farmerPrimary),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide(color: color ?? AppColors.farmerPrimary),
    );
  }

  Widget _buildAnimalsList() {
    return Consumer<AnimalProvider>(
      builder: (context, animalProvider, child) {
        if (_isLoading && animalProvider.animals.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (animalProvider.error != null) {
          return _buildErrorState(animalProvider.error!);
        }

        final filteredAnimals = _getFilteredAnimals(animalProvider.animals);

        if (filteredAnimals.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadAnimals,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredAnimals.length,
            itemBuilder: (context, index) {
              final animal = filteredAnimals[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAnimalCard(animal),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    return Dismissible(
      key: Key(animal.id.toString()),
      background: _buildSwipeBackground(Colors.blue, Icons.edit, Alignment.centerLeft),
      secondaryBackground: _buildSwipeBackground(Colors.red, Icons.delete, Alignment.centerRight),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit action
          context.push('/animals/${animal.id}/edit');
          return false;
        } else {
          // Delete action
          return await _confirmDelete(animal);
        }
      },
      child: CustomCard(
        onTap: () => context.push('/animals/${animal.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Animal Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.farmerPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getAnimalIcon(animal.species),
                  size: 32,
                  color: AppColors.farmerPrimary,
                ),
              ),
              const SizedBox(width: 16),

              // Animal Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            animal.animalName ?? animal.animalId,
                            style: AppTypography.headlineSmall(),
                          ),
                        ),
                        StatusBadge(
                          label: _getStatusLabel(animal),
                          color: _getStatusColor(animal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      animal.breed ?? animal.species,
                      style: AppTypography.bodyLarge(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.monitor_weight,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${animal.liveWeight ?? 0} kg',
                          style: AppTypography.bodyMedium(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${animal.age.toStringAsFixed(1)} yrs',
                          style: AppTypography.bodyMedium(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // View Button
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () => context.push('/animals/${animal.id}'),
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No animals found',
              style: AppTypography.headlineMedium(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty || _selectedSpecies != 'All' || _selectedStatus != 'All'
                  ? 'Try adjusting your filters or search'
                  : 'Start by registering your first animal',
              style: AppTypography.bodyLarge(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: AppTypography.headlineMedium(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: AppTypography.bodyLarge(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAnimals,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Options', style: AppTypography.headlineMedium()),
            const SizedBox(height: 24),
            Text('Species', style: AppTypography.headlineSmall()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _speciesOptions
                  .map((species) => FilterChip(
                        label: Text(species),
                        selected: _selectedSpecies == species,
                        onSelected: (selected) {
                          setState(() => _selectedSpecies = species);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text('Status', style: AppTypography.headlineSmall()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _statusOptions
                  .map((status) => FilterChip(
                        label: Text(status),
                        selected: _selectedStatus == status,
                        onSelected: (selected) {
                          setState(() => _selectedStatus = status);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSpeciesFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: _speciesOptions
            .map((species) => ListTile(
                  title: Text(species),
                  leading: Radio<String>(
                    value: species,
                    groupValue: _selectedSpecies,
                    onChanged: (value) {
                      setState(() => _selectedSpecies = value!);
                      Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    setState(() => _selectedSpecies = species);
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: _statusOptions
            .map((status) => ListTile(
                  title: Text(status),
                  leading: Radio<String>(
                    value: status,
                    groupValue: _selectedStatus,
                    onChanged: (value) {
                      setState(() => _selectedStatus = value!);
                      Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    setState(() => _selectedStatus = status);
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedSpecies = 'All';
      _selectedStatus = 'All';
      _searchController.clear();
    });
  }

  Future<bool> _confirmDelete(Animal animal) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Animal'),
            content: Text('Are you sure you want to delete ${animal.animalName ?? animal.animalId}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  IconData _getAnimalIcon(String species) {
    switch (species.toLowerCase()) {
      case 'cattle':
      case 'cow':
        return Icons.pets;
      case 'pig':
        return Icons.pets;
      case 'chicken':
        return Icons.egg;
      case 'sheep':
        return Icons.pets;
      case 'goat':
        return Icons.pets;
      default:
        return Icons.pets;
    }
  }

  String _getStatusLabel(Animal animal) {
    final status = animal.computedLifecycleStatus;
    switch (status) {
      case AnimalLifecycleStatus.healthy:
        return 'Healthy';
      case AnimalLifecycleStatus.slaughtered:
        return 'Slaughtered';
      case AnimalLifecycleStatus.transferred:
        return 'Transferred';
      case AnimalLifecycleStatus.semiTransferred:
        return 'Semi-Transferred';
    }
  }

  Color _getStatusColor(Animal animal) {
    final status = animal.computedLifecycleStatus;
    switch (status) {
      case AnimalLifecycleStatus.healthy:
        return Colors.green;
      case AnimalLifecycleStatus.slaughtered:
        return Colors.grey;
      case AnimalLifecycleStatus.transferred:
        return Colors.blue;
      case AnimalLifecycleStatus.semiTransferred:
        return Colors.purple;
    }
  }
}
