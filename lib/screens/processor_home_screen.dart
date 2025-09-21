import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../widgets/enhanced_back_button.dart';

class ProcessorHomeScreen extends StatelessWidget {
  const ProcessorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: createAppBarWithBackButton(
        title: 'Processing Unit Dashboard',
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
                      'Welcome, ${user?.username ?? 'Processor'}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Process animals into products and manage your production pipeline.',
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
                  'Create Product',
                  Icons.add_business,
                  AppTheme.primaryGreen,
                  () => context.go('/create-product'),
                ),
                _buildActionCard(
                  context,
                  'Receive Animals',
                  Icons.inventory,
                  AppTheme.accentOrange,
                  () => context.go('/receive-animals'),
                ),
                _buildActionCard(
                  context,
                  'Manage Categories',
                  Icons.category,
                  AppTheme.secondaryBlue,
                  () => context.go('/product-categories'),
                ),
                _buildActionCard(
                  context,
                  'Products Dashboard',
                  Icons.dashboard,
                  AppTheme.accentOrange,
                  () => context.go('/products-dashboard'),
                ),
                _buildActionCard(
                  context,
                  'Scan QR Code',
                  Icons.qr_code_scanner,
                  AppTheme.primaryGreen,
                  () => context.go('/qr-scanner'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Production Pipeline
            Text(
              'Production Pipeline',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),

            // Pipeline stages
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildPipelineStage(
                      context,
                      'Stage 1: Animal Reception',
                      'Receive slaughtered animals from farmers',
                      Icons.receipt_long,
                      AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 16),
                    _buildPipelineStage(
                      context,
                      'Stage 2: Processing',
                      'Process animals into meat products',
                      Icons.restaurant,
                      AppTheme.accentOrange,
                    ),
                    const SizedBox(height: 16),
                    _buildPipelineStage(
                      context,
                      'Stage 3: Packaging',
                      'Package products for distribution',
                      Icons.inventory_2,
                      AppTheme.secondaryBlue,
                    ),
                    const SizedBox(height: 16),
                    _buildPipelineStage(
                      context,
                      'Stage 4: Quality Control',
                      'Final quality checks and QR code generation',
                      Icons.check_circle,
                      AppTheme.successGreen,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stats section
            Text(
              'Production Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Products Created',
                    '0',
                    Icons.production_quantity_limits,
                    AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Animals Processed',
                    '0',
                    Icons.pets,
                    AppTheme.secondaryBlue,
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
                    'Active Categories',
                    '4',
                    Icons.category,
                    AppTheme.accentOrange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'QR Codes Generated',
                    '0',
                    Icons.qr_code,
                    AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // Floating action button for quick product creation
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/create-product'),
        backgroundColor: AppTheme.accentOrange,
        child: const Icon(Icons.add),
      ),
    );
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

  Widget _buildPipelineStage(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
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