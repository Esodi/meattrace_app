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

  @override
  void initState() {
    super.initState();
    _animalProvider = Provider.of<AnimalProvider>(context, listen: false);
    _animalProvider.fetchAnimals();
  }

  Future<void> _refreshData() async {
    await _animalProvider.fetchAnimals();
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
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
          ),
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
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
                  () => context.go('/select-animals-transfer'),
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
                            'Transferred',
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
      ),

      // Floating action button for quick animal registration
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/register-animal'),
        backgroundColor: AppTheme.accentMaroon,
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