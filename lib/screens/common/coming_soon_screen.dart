import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';

class ComingSoonScreen extends StatelessWidget {
  final String featureName;
  final String description;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    required this.featureName,
    this.description = 'This feature is currently under development and will be available soon.',
    this.icon = Icons.construction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          featureName,
          style: AppTypography.headlineSmall(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.farmerPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: AppColors.farmerPrimary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Coming Soon',
                style: AppTypography.headlineMedium(
                  color: AppColors.textPrimary,
                ).copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Feature name
              Text(
                featureName,
                style: AppTypography.headlineSmall(
                  color: AppColors.farmerPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Description
              Text(
                description,
                style: AppTypography.bodyMedium(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
              
              const SizedBox(height: 48),
              
              // Go back button
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.farmerPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'This feature is being migrated to the new UI',
                        style: AppTypography.caption(
                          color: AppColors.info,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
