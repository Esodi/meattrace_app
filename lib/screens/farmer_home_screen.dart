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

class _FarmerHomeScreenState extends State<FarmerHomeScreen> with WidgetsBindingObserver {
  late AnimalProvider _animalProvider;
  int _transferredCount = 0;
  bool _isLoadingTransferred = false;

  @override
  void initState() {
    super.initState();
    _animalProvider = Provider.of<AnimalProvider>(context, listen: false);
    _animalProvider.fetchAnimals();
    _loadTransferredCount();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    await _animalProvider.fetchAnimals();
    await _loadTransferredCount();
  }

  Future<void> _loadTransferredCount() async {
    setState(() => _isLoadingTransferred = true);
    try {
      final transferredAnimals = await _animalProvider.getTransferredAnimalsCount();
      setState(() => _transferredCount = transferredAnimals);
    } catch (e) {
      // Keep current count on error
    } finally {
      setState(() => _isLoadingTransferred = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Dash'),
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 88.0), // Extra padding for FAB
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.username ?? 'Farmer'}!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be a good farmer, Okay?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),

              // Action buttons grid - 2x2 layout
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionButton(
                    context,
                    'Register\nLivestock',
                    Icons.add_circle,
                    () => context.go('/register-animal'),
                  ),
                  _buildActionButton(
                    context,
                    'Slaughter\nLivestock',
                    Icons.restaurant_menu,
                    () => context.go('/slaughter-animal'),
                  ),
                  _buildActionButton(
                    context,
                    'History',
                    Icons.history,
                    () => context.go('/livestock-history'),
                  ),
                  _buildActionButton(
                    context,
                    'Transfer',
                    Icons.send,
                    () => context.go('/select-animals-transfer'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats section
              const Text(
                'Farm Stats',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),

              Consumer<AnimalProvider>(
                builder: (context, animalProvider, child) {
                  final totalAnimals = animalProvider.animals.length;
                  final activeAnimals = animalProvider.animals.where((a) => !a.slaughtered).length;
                  final slaughtered = animalProvider.animals.where((a) => a.slaughtered).length;
                  return Column(
                    children: [
                      _buildStatCard(context, 'Total Animals', totalAnimals.toString()),
                      const SizedBox(height: 16),
                      _buildStatCard(context, 'Active Animals', activeAnimals.toString()),
                      const SizedBox(height: 16),
                      _buildStatCard(context, 'Slaughtered Animals', slaughtered.toString()),
                      const SizedBox(height: 16),
                      _buildStatCard(
                        context,
                        'Transferred Animals',
                        _isLoadingTransferred ? '...' : _transferredCount.toString()
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/register-animal'),
        child: const Icon(Icons.add),
      ),
    );
  }


  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 80, // Fixed height to ensure proper layout
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dividerGray),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}