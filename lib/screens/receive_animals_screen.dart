import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/animal_provider.dart';
import '../models/animal.dart';
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: createAppBarWithBackButton(
        title: 'Receive Animals',
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
                        '${animal.species} • ${animal.weight}kg • Farmer: ${animal.farmerUsername ?? 'Unknown'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Transferred: ${animal.transferredAt?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
}