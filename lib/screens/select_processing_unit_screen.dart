import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/animal_provider.dart';
import '../providers/auth_provider.dart';
import '../models/animal.dart';
import '../utils/theme.dart';
import '../widgets/enhanced_back_button.dart';

class SelectProcessingUnitScreen extends StatefulWidget {
  const SelectProcessingUnitScreen({super.key});

  @override
  State<SelectProcessingUnitScreen> createState() => _SelectProcessingUnitScreenState();
}

class _SelectProcessingUnitScreenState extends State<SelectProcessingUnitScreen> {
  late AnimalProvider _animalProvider;
  late AuthProvider _authProvider;
  List<Map<String, dynamic>> _processingUnits = [];
  List<Animal> _selectedAnimals = [];
  bool _isLoading = true;
  bool _isTransferring = false;
  Map<String, dynamic>? _selectedProcessingUnit;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      _authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Get selected animals from route extra
      final extra = GoRouterState.of(context).extra;
      if (extra is List<Animal>) {
        _selectedAnimals = extra;
      }

      _loadProcessingUnits();
      _isInitialized = true;
    }
  }

  Future<void> _loadProcessingUnits() async {
    setState(() => _isLoading = true);
    try {
      final processingUnits = await _animalProvider.getProcessingUnits();
      setState(() {
        _processingUnits = processingUnits;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load processing units: $e'),
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
        title: 'Select Processing Unit',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProcessingUnits,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _processingUnits.isEmpty
              ? _buildEmptyState()
              : _buildProcessingUnitsList(),
      floatingActionButton: _selectedProcessingUnit != null
          ? FloatingActionButton(
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
            Icons.business_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No processing units available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact administrator to register processing units',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingUnitsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transfer ${_selectedAnimals.length} animal(s) to:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selected animals: ${_selectedAnimals.length} item(s)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _processingUnits.length,
            itemBuilder: (context, index) {
              final processingUnit = _processingUnits[index];
              final isSelected = _selectedProcessingUnit?['id'] == processingUnit['id'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: RadioListTile<Map<String, dynamic>>(
                  title: Text(
                    processingUnit['username'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    processingUnit['email'],
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: processingUnit,
                  groupValue: _selectedProcessingUnit,
                  onChanged: (Map<String, dynamic>? value) {
                    setState(() {
                      _selectedProcessingUnit = value;
                    });
                  },
                  activeColor: AppTheme.accentOrange,
                ),
              );
            },
          ),
        ),
        if (_selectedProcessingUnit != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.backgroundGray,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transfer to: ${_selectedProcessingUnit!['username']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                      Text(
                        '${_selectedAnimals.length} animal(s) selected',
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
            ),
          ),
      ],
    );
  }

  Future<void> _initiateTransfer() async {
    if (_selectedProcessingUnit == null || _selectedAnimals.isEmpty) return;

    setState(() => _isTransferring = true);

    try {
      final processingUnitId = _selectedProcessingUnit!['id'];
      final animalIds = _selectedAnimals.where((animal) => animal.id != null).map((animal) => animal.id!).toList();

      final response = await _animalProvider.transferAnimals(animalIds, processingUnitId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Transfer completed successfully'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to farmer home
        context.go('/farmer-home');
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