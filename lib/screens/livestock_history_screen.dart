import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/animal_provider.dart';
import '../utils/theme.dart';
import '../widgets/loading_indicator.dart';

class LivestockHistoryScreen extends StatefulWidget {
  const LivestockHistoryScreen({super.key});

  @override
  State<LivestockHistoryScreen> createState() => _LivestockHistoryScreenState();
}

class _LivestockHistoryScreenState extends State<LivestockHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load animals when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimalProvider>().fetchAnimals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livestock History'),
      ),
      body: Consumer<AnimalProvider>(
        builder: (context, animalProvider, child) {
          if (animalProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (animalProvider.error != null) {
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
                    onPressed: () => animalProvider.fetchAnimals(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final animals = animalProvider.animals;

          if (animals.isEmpty) {
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
                    'No livestock registered yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Register your first animal to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animal = animals[index];
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
                                  '${animal.species} ${animal.animalId ?? '#${animal.id}'}',
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
            },
          );
        },
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