import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/animal_provider.dart';
import '../models/animal.dart';
import '../services/animal_service.dart';
import '../utils/theme.dart';
import '../widgets/enhanced_back_button.dart';

class ReceiveAnimalsScreen extends StatefulWidget {
  const ReceiveAnimalsScreen({super.key});

  @override
  State<ReceiveAnimalsScreen> createState() => _ReceiveAnimalsScreenState();
}

class _ReceiveAnimalsScreenState extends State<ReceiveAnimalsScreen> {
  late AnimalProvider _animalProvider;
  List<Animal> _transferredAnimals = [];
  List<Animal> _selectedAnimals = [];
  bool _isReceiving = false;
  bool _isLoading = true;
  Map<int, CarcassMeasurement?> _carcassMeasurements = {};
  Map<int, bool> _isLoadingMeasurements = {};

  @override
  void initState() {
    super.initState();
    _animalProvider = Provider.of<AnimalProvider>(context, listen: false);
    _loadTransferredAnimals();
  }

  Future<void> _loadTransferredAnimals() async {
    setState(() => _isLoading = true);
    try {
      final animals = await _animalProvider.fetchTransferredAnimals();
      if (mounted) {
        setState(() {
          _transferredAnimals = animals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load transferred animals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCarcassMeasurements(int animalId) async {
    if (_carcassMeasurements.containsKey(animalId)) return; // Already loaded

    setState(() {
      _isLoadingMeasurements[animalId] = true;
    });

    try {
      final animalService = AnimalService();
      final measurement = await animalService.getCarcassMeasurementForAnimal(animalId);
      if (mounted) {
        setState(() {
          _carcassMeasurements[animalId] = measurement;
          _isLoadingMeasurements[animalId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMeasurements[animalId] = false;
        });
        // Don't show error snackbar for carcass measurements, just silently fail
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createEnhancedAppBarWithBackButton(
        title: 'Receive Animals',
        fallbackRoute: '/processor-home',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransferredAnimals,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransferredAnimals,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _transferredAnimals.isEmpty
                ? _buildEmptyState()
                : _buildAnimalsList(),
      ),
      floatingActionButton: _selectedAnimals.isNotEmpty
          ? FloatingActionButton(
              heroTag: null,
              onPressed: _isReceiving ? null : _receiveSelectedAnimals,
              backgroundColor: AppTheme.accentOrange,
              child: _isReceiving
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Icon(Icons.check),
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
            Icons.inventory_2_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No transferred animals',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Animals transferred by farmers will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Select animals to receive from farmers',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _transferredAnimals.length,
            itemBuilder: (context, index) {
              final animal = _transferredAnimals[index];
              return _buildAnimalCard(animal);
            },
          ),
        ),
        if (_selectedAnimals.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.backgroundGray,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedAnimals.length} animal(s) selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentOrange,
                  ),
                ),
                ElevatedButton(
                  onPressed: _isReceiving ? null : _receiveSelectedAnimals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: _isReceiving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Receive'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    final isSelected = _selectedAnimals.contains(animal);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getAnimalColor(animal.species),
          child: Icon(
            _getAnimalIcon(animal.species),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedAnimals.add(animal);
                  } else {
                    _selectedAnimals.remove(animal);
                  }
                });
              },
              activeColor: AppTheme.accentOrange,
            ),
            Expanded(
              child: Text(
                animal.animalName ?? animal.animalId,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${animal.species} • ${animal.weight ?? 'N/A'}kg • Farmer: ${animal.farmerUsername ?? 'Unknown'}',
          style: const TextStyle(fontSize: 12),
        ),
        onExpansionChanged: (expanded) {
          if (expanded && animal.id != null) {
            _loadCarcassMeasurements(animal.id!);
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information Section
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        context,
                        'Animal ID',
                        animal.animalId,
                        Icons.tag,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        context,
                        'Name',
                        animal.animalName ?? 'N/A',
                        Icons.pets,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        context,
                        'Type',
                        animal.species,
                        Icons.category,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        context,
                        'Age',
                        '${animal.age} months',
                        Icons.calendar_today,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        context,
                        'Initial Weight',
                        '${animal.weight ?? 'N/A'} kg',
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

                // Health Status Section
                const SizedBox(height: 16),
                _buildSectionTitle('Health Status'),
                const SizedBox(height: 8),
                Text(
                  animal.healthStatus ?? 'Not specified',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                // Origin Section
                const SizedBox(height: 16),
                _buildSectionTitle('Origin'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Farmer: ${animal.farmerUsername ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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

                // Processing History Section
                const SizedBox(height: 16),
                _buildSectionTitle('Processing History'),
                const SizedBox(height: 8),
                _buildHistoryItem(
                  'Registration Date',
                  animal.createdAt,
                  Icons.event_available,
                ),
                if (animal.transferredAt != null)
                  _buildHistoryItem(
                    'Transferred At',
                    animal.transferredAt!,
                    Icons.send,
                  ),
                if (animal.receivedAt != null)
                  _buildHistoryItem(
                    'Received At',
                    animal.receivedAt!,
                    Icons.call_received,
                  ),

                // Carcass Measurements Section (fetched on demand)
                const SizedBox(height: 16),
                _buildSectionTitle('Weights of Parts'),
                const SizedBox(height: 8),
                if (_isLoadingMeasurements[animal.id] == true)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Loading measurements...'),
                      ],
                    ),
                  )
                else if (_carcassMeasurements.containsKey(animal.id!) && _carcassMeasurements[animal.id!] != null)
                  ..._carcassMeasurements[animal.id!]!.getAllMeasurements().map((measurement) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cut,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${measurement['name']}: ${measurement['value']} ${measurement['unit']}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  const Text(
                    'No carcass measurements available',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
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

  Widget _buildHistoryItem(String label, DateTime date, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${_formatDate(date)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _receiveSelectedAnimals() async {
    if (_selectedAnimals.isEmpty) return;

    setState(() => _isReceiving = true);

    try {
      final animalIds = _selectedAnimals.map((animal) => animal.id).toList();

      final response = await _animalProvider.receiveAnimals(animalIds);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Successfully received ${_selectedAnimals.length} animal(s)'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Clear selection and reload
      setState(() {
        _selectedAnimals.clear();
      });
      _loadTransferredAnimals();

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to receive animals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isReceiving = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
}







