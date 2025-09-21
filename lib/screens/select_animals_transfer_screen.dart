import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/animal_provider.dart';
import '../models/animal.dart';
import '../utils/theme.dart';
import '../widgets/enhanced_back_button.dart';

class SelectAnimalsTransferScreen extends StatefulWidget {
  const SelectAnimalsTransferScreen({super.key});

  @override
  State<SelectAnimalsTransferScreen> createState() => _SelectAnimalsTransferScreenState();
}

class _SelectAnimalsTransferScreenState extends State<SelectAnimalsTransferScreen> {
  late AnimalProvider _animalProvider;
  List<Animal> _slaughteredAnimals = [];
  List<Animal> _selectedAnimals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animalProvider = Provider.of<AnimalProvider>(context, listen: false);
    _loadSlaughteredAnimals();
  }

  Future<void> _loadSlaughteredAnimals() async {
    setState(() => _isLoading = true);
    try {
      // Get slaughtered animals that haven't been transferred yet
      await _animalProvider.fetchAnimals(slaughtered: true);
      setState(() {
        _slaughteredAnimals = _animalProvider.animals.where((animal) => animal.transferredTo == null).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load animals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBarWithBackButton(
        title: 'Select Animals to Transfer',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSlaughteredAnimals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _slaughteredAnimals.isEmpty
              ? _buildEmptyState()
              : _buildAnimalsList(),
      floatingActionButton: _selectedAnimals.isNotEmpty
          ? FloatingActionButton(
              onPressed: _proceedToSelectProcessingUnit,
              backgroundColor: AppTheme.accentOrange,
              child: const Icon(Icons.arrow_forward),
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
            'No slaughtered animals available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Slaughter some animals first before transferring them',
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
            'Select slaughtered animals to transfer to processing unit',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _slaughteredAnimals.length,
            itemBuilder: (context, index) {
              final animal = _slaughteredAnimals[index];
              final isSelected = _selectedAnimals.contains(animal);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: CheckboxListTile(
                  title: Text(
                    animal.animalName ?? animal.animalId,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${animal.species} • ${animal.weight}kg • Slaughtered: ${animal.slaughteredAt?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
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
              );
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
                  onPressed: _proceedToSelectProcessingUnit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Next: Select Processing Unit'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _proceedToSelectProcessingUnit() {
    if (_selectedAnimals.isEmpty) return;

    // Pass selected animals to the next screen
    context.push('/select-processing-unit', extra: _selectedAnimals);
  }
}