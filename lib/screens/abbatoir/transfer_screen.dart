import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/animal.dart';
import '../../providers/animal_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/core/custom_button.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final List<Animal> _selectedAnimals = [];
  int? _selectedProcessingUnit;
  List<Map<String, dynamic>> _processingUnits = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProcessingUnits();
  }

  Future<void> _fetchProcessingUnits() async {
    setState(() => _isLoading = true);
    try {
      final animalProvider = Provider.of<AnimalProvider>(
        context,
        listen: false,
      );
      final units = await animalProvider.getProcessingUnits();
      setState(() {
        _processingUnits = units;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch processing units: $e')),
      );
    }
  }

  void _toggleAnimalSelection(Animal animal) {
    setState(() {
      if (_selectedAnimals.contains(animal)) {
        _selectedAnimals.remove(animal);
      } else {
        _selectedAnimals.add(animal);
      }
    });
  }

  Future<void> _transferAnimals() async {
    if (_selectedAnimals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one animal.')),
      );
      return;
    }

    if (_selectedProcessingUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a processing unit.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final animalProvider = Provider.of<AnimalProvider>(
        context,
        listen: false,
      );
      await animalProvider.transferAnimals(
        _selectedAnimals.map((a) => a.id).toList(),
        _selectedProcessingUnit!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Animals transferred successfully!')),
      );
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to transfer animals: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Animals'),
        backgroundColor: AppColors.abbatoirPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProcessingUnitDropdown(),
                Expanded(child: _buildAnimalList()),
              ],
            ),
      bottomNavigationBar: _buildTransferButton(),
    );
  }

  Widget _buildProcessingUnitDropdown() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButtonFormField<int>(
        initialValue: _selectedProcessingUnit,
        hint: const Text('Select Processing Unit'),
        onChanged: (value) {
          setState(() {
            _selectedProcessingUnit = value;
          });
        },
        items: _processingUnits.map((unit) {
          return DropdownMenuItem<int>(
            value: unit['id'],
            child: Text(unit['name']),
          );
        }).toList(),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Processing Unit',
        ),
      ),
    );
  }

  Widget _buildAnimalList() {
    return Consumer<AnimalProvider>(
      builder: (context, animalProvider, child) {
        final animals = animalProvider.animals
            .where(
              (animal) => animal.slaughtered && animal.transferredTo == null,
            )
            .toList();

        if (animals.isEmpty) {
          return const Center(
            child: Text('No animals available for transfer.'),
          );
        }

        return ListView.builder(
          itemCount: animals.length,
          itemBuilder: (context, index) {
            final animal = animals[index];
            final isSelected = _selectedAnimals.contains(animal);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CheckboxListTile(
                title: Text(animal.animalName ?? animal.animalId),
                subtitle: Text(animal.species),
                value: isSelected,
                onChanged: (value) => _toggleAnimalSelection(animal),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransferButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CustomButton(
        label: 'Transfer Selected Animals',
        onPressed: _transferAnimals,
        loading: _isLoading,
      ),
    );
  }
}
