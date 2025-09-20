import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/animal_provider.dart';
import '../models/animal.dart';
import '../utils/theme.dart';
import '../widgets/enhanced_back_button.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  late AnimalProvider _animalProvider;
  List<Animal> _selectedAnimals = [];
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _animalProvider = Provider.of<AnimalProvider>(context, listen: false);
    _animalProvider.fetchAnimals();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: createAppBarWithBackButton(
        title: 'Farmer Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
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
                      'Welcome, ${user?.username ?? 'Farmer'}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your livestock and track your animals through the supply chain.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),

            // Action buttons grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  'Register Animal',
                  Icons.add_circle,
                  AppTheme.primaryRed,
                  () => context.go('/register-animal'),
                ),
                _buildActionCard(
                  context,
                  'Slaughter Animal',
                  Icons.restaurant_menu,
                  AppTheme.accentMaroon,
                  () => context.go('/slaughter-animal'),
                ),
                _buildActionCard(
                  context,
                  'Livestock History',
                  Icons.thermostat,
                  AppTheme.secondaryBurgundy,
                  () => context.go('/livestock-history'),
                ),
                _buildActionCard(
                  context,
                  'Transfer Carcasses',
                  Icons.location_on,
                  AppTheme.secondaryBurgundy,
                  () => _showTransferAnimalsDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Stats section
            Text(
              'Your Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),

            Consumer<AnimalProvider>(
              builder: (context, animalProvider, child) {
                final totalAnimals = animalProvider.animals.length;
                final activeAnimals = animalProvider.animals.where((a) => !a.slaughtered).length;
                final slaughtered = animalProvider.animals.where((a) => a.slaughtered).length;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Total Animals',
                            totalAnimals.toString(),
                            Icons.pets,
                            AppTheme.primaryRed,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Active Animals',
                            activeAnimals.toString(),
                            Icons.timeline,
                            AppTheme.secondaryBurgundy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Slaughtered',
                            slaughtered.toString(),
                            Icons.inventory,
                            AppTheme.accentMaroon,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Transfer Carcasses',
                            '0', // TODO: Implement transfer count
                            Icons.send,
                            AppTheme.secondaryBurgundy,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),

      // Floating action button for quick animal registration
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/register-animal'),
        backgroundColor: AppTheme.accentMaroon,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTransferAnimalsDialog(BuildContext context) {
    final slaughteredAnimals = _animalProvider.animals.where((animal) => animal.slaughtered).toList();

    if (slaughteredAnimals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No slaughtered animals available for transfer'),
          backgroundColor: AppTheme.accentMaroon,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Transfer Animals'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select slaughtered animals to transfer to processing unit:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: slaughteredAnimals.length,
                        itemBuilder: (context, index) {
                          final animal = slaughteredAnimals[index];
                          final isSelected = _selectedAnimals.contains(animal);

                          return CheckboxListTile(
                            title: Text(
                              animal.animalName ?? animal.animalId,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              '${animal.species} • ${animal.weight}kg • Slaughtered: ${animal.slaughteredAt?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 12),
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
                            activeColor: AppTheme.secondaryBurgundy,
                          );
                        },
                      ),
                    ),
                    if (_selectedAnimals.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          '${_selectedAnimals.length} animal(s) selected',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryBurgundy,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedAnimals.clear();
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _selectedAnimals.isEmpty || _isTransferring
                      ? null
                      : () => _initiateTransfer(context, setState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryBurgundy,
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
            );
          },
        );
      },
    ).then((_) {
      // Clear selection when dialog is closed
      setState(() {
        _selectedAnimals.clear();
      });
    });
  }

  Future<void> _initiateTransfer(BuildContext context, StateSetter setState) async {
    if (_selectedAnimals.isEmpty) return;

    setState(() {
      _isTransferring = true;
    });

    try {
      // For now, use a demo processing unit ID (in a real app, this would be selected by the user)
      const demoProcessingUnitId = 13; // demo_processor user ID

      final animalIds = _selectedAnimals.map((animal) => animal.id).toList();

      // Make API call to transfer animals
      final response = await _animalProvider.transferAnimals(animalIds, demoProcessingUnitId);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Transfer completed'),
            backgroundColor: AppTheme.primaryRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Close dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Refresh animals list
      _animalProvider.fetchAnimals();

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isTransferring = false;
      });
    }
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}