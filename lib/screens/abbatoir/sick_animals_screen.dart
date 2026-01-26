import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/animal_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/livestock/animal_card.dart';
import 'package:go_router/go_router.dart';

class SickAnimalsScreen extends StatelessWidget {
  const SickAnimalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sick & Under Treatment'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<AnimalProvider>(
        builder: (context, animalProvider, child) {
          final sickAnimals = animalProvider.animals.where((a) {
            final status = a.healthStatus?.toLowerCase() ?? '';
            return status.contains('sick') || status.contains('treatment');
          }).toList();

          if (animalProvider.isLoading && sickAnimals.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (sickAnimals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    size: 80,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  Text(
                    'No sick animals reported',
                    style: AppTypography.headlineSmall().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'All animals are currently healthy',
                    style: AppTypography.bodyMedium().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.space16),
            itemCount: sickAnimals.length,
            itemBuilder: (context, index) {
              final animal = sickAnimals[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space12),
                child: CompactAnimalCard(
                  animalId: animal.animalId,
                  species: animal.species,
                  healthStatus: animal.healthStatus ?? 'Sick',
                  onTap: () {
                    if (animal.id != null) {
                      context.push('/animals/${animal.id}');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
