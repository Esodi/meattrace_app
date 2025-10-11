import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/animal_provider.dart';
import '../utils/theme.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/enhanced_back_button.dart';
import '../services/navigation_service.dart';
import '../models/animal.dart';

class EnhancedLivestockHistoryScreen extends StatefulWidget {
  const EnhancedLivestockHistoryScreen({super.key});

  @override
  State<EnhancedLivestockHistoryScreen> createState() => _EnhancedLivestockHistoryScreenState();
}

class _EnhancedLivestockHistoryScreenState extends State<EnhancedLivestockHistoryScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  // Controllers for state preservation
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  // Filter states
  bool? _selectedSlaughterStatus = false;
  String _searchQuery = '';

  // UI states
  bool _showFilters = true;
  double _lastScrollPosition = 0.0;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Restore state and load data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _restoreState();
      await _loadAnimals();
    });
    
    // Listen to scroll changes for state preservation
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveCurrentState();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveCurrentState();
    }
  }

  void _onScroll() {
    _lastScrollPosition = _scrollController.offset;
  }

  /// Restore saved state from previous session
  Future<void> _restoreState() async {
    try {
      final state = await NavigationService.instance.restoreState('/livestock-history');
      if (state != null) {
        setState(() {
          _selectedSlaughterStatus = state['selectedSlaughterStatus'] ?? false;
          _searchQuery = state['searchQuery'] ?? '';
          _showFilters = state['showFilters'] ?? true;
          _lastScrollPosition = state['scrollPosition'] ?? 0.0;
        });
        
        _searchController.text = _searchQuery;
        
        // Restore scroll position after a short delay
        if (_lastScrollPosition > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _lastScrollPosition,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      }
    } catch (e) {
      // Ignore restoration errors
    }
  }

  /// Save current state for restoration
  void _saveCurrentState() {
    final state = {
      'selectedSlaughterStatus': _selectedSlaughterStatus,
      'searchQuery': _searchQuery,
      'showFilters': _showFilters,
      'scrollPosition': _lastScrollPosition,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    NavigationService.instance.saveState('/livestock-history', state).then((_) {
      // Save state asynchronously to avoid blocking UI
    });
  }

  /// Load animals with current filters
  Future<void> _loadAnimals() async {
    debugPrint('LivestockHistoryScreen: Fetching animals with slaughtered filter: $_selectedSlaughterStatus (false=active, true=slaughtered)');
    final animalProvider = context.read<AnimalProvider>();
    await animalProvider.fetchAnimals(
      slaughtered: _selectedSlaughterStatus, // false=active, true=slaughtered
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
  }

  /// Handle search input changes
  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    
    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == value) {
        _loadAnimals();
      }
    });
  }

  /// Handle slaughter status filter change
  void _onSlaughterStatusFilterChanged(bool? status) {
    setState(() {
      _selectedSlaughterStatus = status;
    });
    _loadAnimals();
  }

  /// Clear all filters
  void _clearFilters() {
    setState(() {
      _selectedSlaughterStatus = false; // Reset to show active animals
      _searchQuery = '';
      _searchController.clear();
    });
    _loadAnimals();
  }

  /// Handle refresh
  Future<void> _handleRefresh() async {
    await _loadAnimals();
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmationDialog(Animal animal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Animal'),
          content: Text(
            'Are you sure you want to delete ${animal.species} ${animal.animalName ?? animal.animalId ?? '#${animal.id}'}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _deleteAnimal(animal);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  /// Delete animal
  Future<void> _deleteAnimal(Animal animal) async {
    try {
      final animalProvider = context.read<AnimalProvider>();
      await animalProvider.deleteAnimal(animal.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${animal.species} deleted successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete animal: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  /// Get preserved state for back navigation
  Map<String, dynamic> _getPreservedState() {
    return {
      'selectedSlaughterStatus': _selectedSlaughterStatus,
      'searchQuery': _searchQuery,
      'showFilters': _showFilters,
      'scrollPosition': _scrollController.hasClients ? _scrollController.offset : _lastScrollPosition,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          _saveCurrentState();
          final shouldPop = await context.smartNavigateBack(
            userType: 'farmer',
            preservedState: _getPreservedState(),
          );
          if (shouldPop) {
            if (mounted) Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: createEnhancedAppBarWithBackButton(
          title: 'Livestock History',
          fallbackRoute: '/farmer-home',
          preservedState: _getPreservedState(),
          actions: [
            IconButton(
              icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _handleRefresh,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search animals...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            
            // Filters section
            if (_showFilters) _buildFiltersSection(),
            
            // Animals list
            Expanded(
              child: Consumer<AnimalProvider>(
                builder: (context, animalProvider, child) {
                  if (animalProvider.isLoading) {
                    return const Center(child: LoadingIndicator());
                  }

                  if (animalProvider.error != null) {
                    return _buildErrorState(animalProvider);
                  }

                  final animals = _getFilteredAnimals(animalProvider.animals);

                  if (animals.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: animals.length,
                      itemBuilder: (context, index) {
                        final animal = animals[index];
                        return _buildAnimalCard(animal);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Slaughter status filter
              DropdownButton<bool>(
                value: _selectedSlaughterStatus,
                hint: const Text('Status'),
                items: const [
                  DropdownMenuItem(
                    value: false,
                    child: Text('Active'),
                  ),
                  DropdownMenuItem(
                    value: true,
                    child: Text('Slaughtered'),
                  ),
                ],
                onChanged: _onSlaughterStatusFilterChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AnimalProvider animalProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load livestock history',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            animalProvider.error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleRefresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _hasActiveFilters() ? 'No animals match your filters' : 'No livestock registered yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters() 
                ? 'Try adjusting your search or filters'
                : 'Register your first animal to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animal header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getAnimalColor(animal.species),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    _getAnimalIcon(animal.species),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal.animalName != null
                            ? '${animal.species} - ${animal.animalName} (${animal.animalId ?? '#${animal.id}'})'
                            : '${animal.species} (${animal.animalId ?? '#${animal.id}'})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      Text(
                        'Registered: ${_formatDate(animal.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                // Status indicator and delete button
                Row(
                  children: [
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: animal.slaughtered
                            ? AppTheme.errorRed.withOpacity(0.1)
                            : AppTheme.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: animal.slaughtered
                              ? AppTheme.errorRed
                              : AppTheme.successGreen,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        animal.slaughtered ? 'Slaughtered' : 'Active',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: animal.slaughtered
                                  ? AppTheme.errorRed
                                  : AppTheme.successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete button (only for active animals)
                    if (!animal.slaughtered)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmationDialog(animal),
                        tooltip: 'Delete animal',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Animal details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Age',
                    '${animal.age} months',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Weight',
                    '${animal.weight} kg',
                    Icons.monitor_weight,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    'Breed',
                    animal.breed ?? 'N/A',
                    Icons.category,
                  ),
                ),
              ],
            ),

            if (animal.farmName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.home,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Farm: ${animal.farmName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ],

            if (animal.slaughtered && animal.slaughteredAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.errorRed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Slaughtered: ${_formatDate(animal.slaughteredAt!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.errorRed,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryGreen,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Animal> _getFilteredAnimals(List<Animal> animals) {
    // API already handles filtering, so return animals as-is
    return animals;
  }

  bool _hasActiveFilters() {
    return _selectedSlaughterStatus == true ||
           _searchQuery.isNotEmpty;
  }

  Color _getAnimalColor(String species) {
    switch (species.toLowerCase()) {
      case 'cow':
        return AppTheme.primaryGreen;
      case 'pig':
        return AppTheme.accentOrange;
      case 'chicken':
        return AppTheme.secondaryBlue;
      case 'sheep':
        return AppTheme.warningAmber;
      case 'goat':
        return AppTheme.primaryGreen;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getAnimalIcon(String species) {
    switch (species.toLowerCase()) {
      case 'cow':
        return Icons.pets;
      case 'pig':
        return Icons.pets;
      case 'chicken':
        return Icons.pets;
      case 'sheep':
        return Icons.pets;
      case 'goat':
        return Icons.pets;
      default:
        return Icons.pets;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}







