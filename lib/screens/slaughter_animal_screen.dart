import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/animal.dart';
import '../providers/animal_provider.dart';
import '../utils/theme.dart';
import '../widgets/enhanced_back_button.dart';

class SlaughterAnimalScreen extends StatefulWidget {
  const SlaughterAnimalScreen({super.key});

  @override
  State<SlaughterAnimalScreen> createState() => _SlaughterAnimalScreenState();
}

class _SlaughterAnimalScreenState extends State<SlaughterAnimalScreen> {
  Animal? _selectedAnimal;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchType = 'id'; // 'id' or 'name'
  List<Animal> _registeredAnimals = [];
  bool _isLoadingAnimals = true;

  @override
  void initState() {
    super.initState();
    _loadRegisteredAnimals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRegisteredAnimals() async {
    if (!mounted) return;
    setState(() => _isLoadingAnimals = true);
    try {
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      await animalProvider.fetchAnimals(slaughtered: false);
      if (mounted) {
        setState(() {
          _registeredAnimals = animalProvider.animals.where((animal) => !animal.slaughtered).toList();
          _isLoadingAnimals = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAnimals = false);
      if (mounted) _showError('Failed to load registered animals: $e');
    }
  }

  Future<void> _searchAnimal() async {
    if (_searchController.text.isEmpty) return;
    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      final searchTerm = _searchController.text.trim();

      // Use backend search API
      await animalProvider.fetchAnimals(search: searchTerm);

      final animals = animalProvider.animals;

      // Filter results based on search type and ensure not slaughtered
      Animal? foundAnimal;
      if (_searchType == 'id') {
        foundAnimal = animals.firstWhere(
          (animal) => animal.animalId.toLowerCase() == searchTerm.toLowerCase() && !animal.slaughtered,
          orElse: () => throw Exception('Animal not found'),
        );
      } else {
        foundAnimal = animals.firstWhere(
          (animal) => animal.animalName?.toLowerCase() == searchTerm.toLowerCase() && !animal.slaughtered,
          orElse: () => throw Exception('Animal not found'),
        );
      }

      if (mounted) {
        setState(() {
          _selectedAnimal = foundAnimal;
        });
      }
    } catch (e) {
      final searchField = _searchType == 'id' ? 'ID' : 'name';
      if (mounted) _showError('Animal not found. Please check the $searchField and try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _slaughterAnimal() async {
    if (_selectedAnimal == null) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Slaughter'),
        content: Text(
          'Are you sure you want to mark "${_selectedAnimal!.species} ${_selectedAnimal!.animalId}" as slaughtered? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Confirm Slaughter'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      await animalProvider.slaughterAnimal(
        _selectedAnimal!.animalId,
        DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Animal slaughtered successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        // Refresh the list of registered animals to remove the slaughtered animal
        await _loadRegisteredAnimals();
        // Clear the selected animal since it's now slaughtered
        if (mounted) {
          setState(() {
            _selectedAnimal = null;
          });
        }
        // Navigate to carcass measurement screen instead of home
        context.go('/carcass-measurement', extra: _selectedAnimal);
      }
    } catch (e) {
      if (mounted) _showError('Failed to slaughter animal: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBarWithBackButton(
        title: 'Slaughter Animal',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Animal to Slaughter',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Search type selection
                    RadioGroup<String>(
                      groupValue: _searchType,
                      onChanged: (value) {
                        setState(() {
                          _searchType = value!;
                          _searchController.clear();
                          _selectedAnimal = null;
                        });
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Search by ID'),
                              value: 'id',
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Search by Name'),
                              value: 'name',
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: _searchType == 'id' ? 'Animal ID' : 'Animal Name',
                        prefixIcon: Icon(_searchType == 'id' ? Icons.tag : Icons.pets),
                        hintText: _searchType == 'id'
                            ? 'Enter the unique animal ID'
                            : 'Enter the animal name',
                      ),
                      textInputAction: TextInputAction.search,
                      onFieldSubmitted: (_) => _searchAnimal(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSearching ? null : _searchAnimal,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isSearching ? 'Searching...' : 'Search Animal'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Registered animals list section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registered Animals',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingAnimals)
                      const Center(child: CircularProgressIndicator())
                    else if (_registeredAnimals.isEmpty)
                      Center(
                        child: Text(
                          'No registered animals found',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: _registeredAnimals.length,
                          itemBuilder: (context, index) {
                            final animal = _registeredAnimals[index];
                            final isSelected = _selectedAnimal?.id == animal.id;

                            return Card(
                              color: isSelected ? AppTheme.primaryGreen.withValues(alpha:0.1) : null,
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withValues(alpha:0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.pets,
                                    size: 20,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                title: Text(
                                  animal.animalName ?? animal.animalId,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? AppTheme.primaryGreen : AppTheme.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  '${animal.species} • ${animal.age} months • ${animal.weight != null ? '${animal.weight} kg' : 'N/A'}',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedAnimal = animal;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

             if (_selectedAnimal != null) ...[
              const SizedBox(height: 24),
              // Animal details section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Icon(
                              Icons.pets,
                              size: 30,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_selectedAnimal!.species} ${_selectedAnimal!.animalId}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                ),
                                Text(
                                  'Registered: ${_formatDate(_selectedAnimal!.createdAt)}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Animal info grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Age',
                              '${_selectedAnimal!.age} months',
                              Icons.calendar_today,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Weight',
                              '${_selectedAnimal!.weight} kg',
                              Icons.monitor_weight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Breed',
                              _selectedAnimal!.breed ?? 'N/A',
                              Icons.category,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Farm',
                              _selectedAnimal!.farmName,
                              Icons.home,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Warning section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.warningAmber.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.warningAmber.withValues(alpha:0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: AppTheme.warningAmber,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Once slaughtered, this animal cannot be modified or restored. Make sure this is the correct animal.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.warningAmber,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Slaughter button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _slaughterAnimal,
                          icon: const Icon(Icons.cut),
                          label: const Text('Slaughter Animal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Help section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Slaughter an Animal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      '1. Search for an animal by ID or Name using the search field above, OR select an animal from the registered animals list.',
                    ),
                    _buildHelpItem(
                      '2. Verify the animal details are correct.',
                    ),
                    _buildHelpItem(
                      '3. Confirm the slaughter action when prompted.',
                    ),
                    _buildHelpItem(
                      '4. The animal will be marked as slaughtered and cannot be reversed.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
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

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}








