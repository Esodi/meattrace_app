import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/animal.dart';
import '../providers/animal_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/auth_provider.dart';

class RegisterAnimalScreen extends StatefulWidget {
  const RegisterAnimalScreen({super.key});

  @override
  State<RegisterAnimalScreen> createState() => _RegisterAnimalScreenState();
}

class _RegisterAnimalScreenState extends State<RegisterAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _animalIdController = TextEditingController();
  final _weightController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _healthStatusController = TextEditingController();

  String? _selectedType;
  String? _selectedFarm;
  DateTime _selectedDate = DateTime.now();

  final List<String> _animalTypes = ['Cow', 'Pig', 'Sheep'];
  final List<String> _farms = ['Farm A', 'Farm B', 'Farm C']; // Mock farms

  @override
  void dispose() {
    _animalIdController.dispose();
    _weightController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _healthStatusController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final connectivityProvider = context.read<ConnectivityProvider>();
      final isOnline = connectivityProvider.isOnline;
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
        }
        return;
      }

      final animal = Animal(
        farmer: user.id,
        species: _selectedType!,
        age: int.parse(_ageController.text.isNotEmpty ? _ageController.text : '0'),
        weight: double.parse(_weightController.text),
        createdAt: _selectedDate,
        slaughtered: false,
        animalId: _animalIdController.text,
        breed: _breedController.text.isNotEmpty ? _breedController.text : null,
        farmName: _selectedFarm!,
        healthStatus: _healthStatusController.text.isNotEmpty ? _healthStatusController.text : null,
      );

      final provider = context.read<AnimalProvider>();
      await provider.createAnimal(animal, isOnline: isOnline);

      if (!mounted) return;

      if (provider.error == null || provider.error!.contains('Saved offline')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isOnline ? 'Animal registered successfully' : 'Animal saved offline')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${provider.error}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    // Check if user is authenticated and is a farmer
    if (user == null) {
      return Scaffold(
        body: const Center(
          child: Text('Please log in to access this page'),
        ),
      );
    }

    if (user.role != 'Farmer') {
      return Scaffold(
        body: const Center(
          child: Text('Access denied. Only farmers can register animals.'),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F5F5), Color(0xFFE8F5E8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Register Animal'),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.pets,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Progress Indicator
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Registration Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.8, // Mock progress
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '80% Complete',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form Content
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Photo Upload Section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Animal Photo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF4CAF50),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Color(0xFF757575),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Implement photo upload with image_picker
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Photo upload feature coming soon')),
                              );
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take Photo'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Basic Information Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info,
                                  color: Color(0xFF4CAF50),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Basic Information',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: const Color(0xFF212121),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Animal Type',
                                prefixIcon: Icon(Icons.pets),
                              ),
                              items: _animalTypes.map((type) {
                                return DropdownMenuItem(value: type, child: Text(type));
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a type';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _animalIdController,
                              decoration: const InputDecoration(
                                labelText: 'Animal ID',
                                prefixIcon: Icon(Icons.tag),
                                hintText: 'Enter unique animal ID',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter animal ID';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _ageController,
                              decoration: const InputDecoration(
                                labelText: 'Age (months)',
                                prefixIcon: Icon(Icons.calendar_view_month),
                                hintText: 'Enter animal age in months',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter age';
                                }
                                final age = int.tryParse(value);
                                if (age == null || age < 0) {
                                  return 'Please enter a valid age';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _weightController,
                              decoration: const InputDecoration(
                                labelText: 'Weight (kg)',
                                prefixIcon: Icon(Icons.monitor_weight),
                                hintText: 'Enter weight in kilograms',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter weight';
                                }
                                final weight = double.tryParse(value);
                                if (weight == null || weight <= 0) {
                                  return 'Please enter a valid weight';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _breedController,
                              decoration: const InputDecoration(
                                labelText: 'Breed',
                                prefixIcon: Icon(Icons.category),
                                hintText: 'Enter animal breed',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _healthStatusController,
                              decoration: const InputDecoration(
                                labelText: 'Health Status',
                                prefixIcon: Icon(Icons.health_and_safety),
                                hintText: 'Enter health status (e.g., Healthy, Sick)',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Farm Information Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF2196F3),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Farm Information',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: const Color(0xFF212121),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedFarm,
                            decoration: const InputDecoration(
                              labelText: 'Farm Name',
                              prefixIcon: Icon(Icons.agriculture),
                            ),
                            items: _farms.map((farm) {
                              return DropdownMenuItem(value: farm, child: Text(farm));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFarm = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a farm';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Card(
                            color: const Color(0xFFF5F5F5),
                            child: ListTile(
                              title: const Text('Registration Date'),
                              subtitle: Text(
                                _selectedDate.toLocal().toString().split(' ')[0],
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () => _selectDate(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  Consumer<AnimalProvider>(
                    builder: (context, provider, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: provider.isLoading ? null : _submitForm,
                          icon: provider.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            provider.isLoading ? 'Registering...' : 'Register Animal',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
