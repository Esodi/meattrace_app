import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/animal_provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/livestock/animal_card.dart';
import '../../widgets/livestock/activity_timeline.dart';

/// Modern Farmer Dashboard with Material Design 3
/// Features: Stats overview, recent animals, quick actions, activity timeline
class ModernFarmerHomeScreen extends StatefulWidget {
  const ModernFarmerHomeScreen({super.key});

  @override
  State<ModernFarmerHomeScreen> createState() => _ModernFarmerHomeScreenState();
}

class _ModernFarmerHomeScreenState extends State<ModernFarmerHomeScreen>
    with TickerProviderStateMixin, RouteAware {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _transferredCount = 0;
  bool _isLoadingTransferred = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this screen
    print('🔄 [FarmerDashboard] didChangeDependencies - Refreshing data');
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🏠 FARMER_DASHBOARD - LOAD_DATA START');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    
    print('📊 Provider state BEFORE fetch:');
    print('   - animalProvider.animals.length: ${animalProvider.animals.length}');
    print('   - animalProvider.isLoading: ${animalProvider.isLoading}');
    print('   - animalProvider.error: ${animalProvider.error}');
    print('   - activityProvider.activities.length: ${activityProvider.activities.length}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    print('📡 Starting parallel fetch of animals, activities, and dashboard...');
    try {
      final apiService = ApiService();
      await Future.wait([
        animalProvider.fetchAnimals(slaughtered: null), // Fetch ALL animals (active + slaughtered)
        activityProvider.fetchActivities(),
        apiService.fetchDashboard(), // Fetch dashboard data
        apiService.fetchActivities(), // Fetch activity data
      ]);
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ FETCH COMPLETE');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Provider state AFTER fetch:');
      print('   - animalProvider.animals.length: ${animalProvider.animals.length}');
      print('   - animalProvider.isLoading: ${animalProvider.isLoading}');
      print('   - animalProvider.error: ${animalProvider.error}');
      print('   - activityProvider.activities.length: ${activityProvider.activities.length}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stackTrace) {
      print('❌ ERROR in parallel fetch: $e');
      print('❌ Stack trace: $stackTrace');
    }
    
    print('🔄 Loading transferred count...');
    await _loadTransferredCount();
    
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('� FARMER_DASHBOARD - LOAD_DATA COMPLETE');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 Final counts:');
    print('   - Total animals: ${animalProvider.animals.length}');
    print('   - Transferred count: $_transferredCount');
    print('   - Activities: ${activityProvider.activities.length}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  Future<void> _loadTransferredCount() async {
    if (!mounted) return;
    setState(() => _isLoadingTransferred = true);

    try {
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      final count = await animalProvider.getTransferredAnimalsCount();
      if (mounted) {
        setState(() => _transferredCount = count);
      }
    } catch (e) {
      debugPrint('Error loading transferred count: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingTransferred = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        context.push('/farmer/livestock-history');
        break;
      case 2:
        context.push('/select-animals-transfer');
        break;
      case 3:
        context.push('/farmer/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.farmerPrimary,
                    AppColors.farmerPrimary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: const Icon(
                Icons.agriculture,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MeatTrace Pro',
                    style: AppTypography.titleMedium().copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    user?.username ?? 'Farmer',
                    style: AppTypography.bodySmall().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            color: AppColors.textPrimary,
            onPressed: () {
              // TODO: Navigate to notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            color: AppColors.textPrimary,
            onPressed: () {
              context.push('/farmer/settings');
            },
          ),
          const SizedBox(width: AppTheme.space8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.farmerPrimary,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // Welcome Header with Overview
              Consumer<AnimalProvider>(
                builder: (context, animalProvider, child) {
                  return SliverToBoxAdapter(
                    child: _buildWelcomeHeader(user?.username ?? 'Farmer', animalProvider),
                  );
                },
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: _buildQuickActions(),
              ),

              // Recent Activity Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppTheme.space24),
                  child: Consumer<ActivityProvider>(
                    builder: (context, activityProvider, child) {
                      if (activityProvider.isLoading && activityProvider.activities.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return ActivityTimeline(
                        activities: activityProvider.getRecentActivities(limit: 5),
                        onViewAll: () {
                          // TODO: Navigate to full activity history
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Activity history coming soon!'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Recent Animals Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space16,
                    AppTheme.space24,
                    AppTheme.space16,
                    AppTheme.space8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Animals',
                        style: AppTypography.headlineMedium(),
                      ),
                      TextButton(
                        onPressed: () => context.push('/farmer/livestock-history'),
                        child: Text(
                          'View All',
                          style: AppTypography.button().copyWith(
                            color: AppColors.farmerPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Animals List
              Consumer<AnimalProvider>(
                builder: (context, animalProvider, child) {
                  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                  print('� UI CONSUMER - REBUILDING');
                  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                  print('📊 Current provider state:');
                  print('   - isLoading: ${animalProvider.isLoading}');
                  print('   - animals.length: ${animalProvider.animals.length}');
                  print('   - error: ${animalProvider.error}');
                  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                  
                  if (animalProvider.isLoading && animalProvider.animals.isEmpty) {
                    print('⏳ Showing loading indicator (no cached data)');
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.farmerPrimary,
                        ),
                      ),
                    );
                  }

                  final recentAnimals = animalProvider.animals.take(5).toList();
                  print('📋 Recent animals to display: ${recentAnimals.length}');
                  if (recentAnimals.isNotEmpty) {
                    print('📝 First few animals:');
                    for (var i = 0; i < recentAnimals.length && i < 3; i++) {
                      final a = recentAnimals[i];
                      print('   [$i] ${a.animalId} - ${a.species} (ID: ${a.id})');
                    }
                  }

                  if (recentAnimals.isEmpty) {
                    print('📭 No animals - showing empty state');
                    return SliverToBoxAdapter(
                      child: _buildEmptyState(),
                    );
                  }
                  
                  print('✅ Rendering ${recentAnimals.length} animal cards');
                  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space16,
                      0,
                      AppTheme.space16,
                      AppTheme.space24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= recentAnimals.length) {
                            return const SizedBox.shrink();
                          }
                          final animal = recentAnimals[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.space12),
                            child: CompactAnimalCard(
                              animalId: animal.animalId,
                              species: animal.species,
                              healthStatus: animal.healthStatus ?? 'healthy',
                              onTap: () {
                                // Navigate to animal details
                                if (animal.id != null) {
                                  context.push('/animals/${animal.id}');
                                }
                              },
                            ),
                          );
                        },
                        childCount: recentAnimals.length,
                      ),
                    ),
                  );
                },
              ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.space24),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: CustomFAB(
        icon: Icons.add,
        onPressed: () => context.push('/register-animal'),
        backgroundColor: AppColors.farmerPrimary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.farmerPrimary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: AppTypography.labelMedium().copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelMedium(),
        elevation: 8,
        backgroundColor: Theme.of(context).colorScheme.surface,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Animals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: 'Transfer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(String username, AnimalProvider animalProvider) {
    final totalAnimals = animalProvider.animals.length;
    final activeAnimals = animalProvider.animals.where((a) => !a.slaughtered && a.transferredTo == null).length;
    final processedAnimals = animalProvider.animals.where((a) => a.slaughtered).length;

    return Container(
      margin: const EdgeInsets.all(AppTheme.space16),
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.farmerPrimary,
            AppColors.farmerPrimary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.farmerPrimary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: AppTypography.bodyMedium().copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      username,
                      style: AppTypography.headlineLarge().copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.space4),
                    Text(
                      'Verified',
                      style: AppTypography.labelMedium().copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    'Track your livestock from registration to transfer',
                    style: AppTypography.bodyMedium().copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space24),
          Text(
            'Overview',
            style: AppTypography.headlineMedium().copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            children: [
              Expanded(
                child: _buildStatsCardInWelcome(
                  label: 'Total',
                  value: totalAnimals.toString(),
                  subtitle: 'Animals',
                  icon: Icons.pets,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: _buildStatsCardInWelcome(
                  label: 'Active',
                  value: activeAnimals.toString(),
                  subtitle: 'On Farm',
                  icon: Icons.health_and_safety,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            children: [
              Expanded(
                child: _buildStatsCardInWelcome(
                  label: 'Processed',
                  value: processedAnimals.toString(),
                  subtitle: 'Animals',
                  icon: Icons.check_circle,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: _buildStatsCardInWelcome(
                  label: 'Transferred',
                  value: _isLoadingTransferred ? '...' : _transferredCount.toString(),
                  subtitle: 'To Processors',
                  icon: Icons.send,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCardInWelcome({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: AppTheme.space8),
              Text(
                label,
                style: AppTypography.labelMedium().copyWith(
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            value,
            style: AppTypography.headlineSmall().copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: AppTypography.bodySmall().copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.pets,
        label: 'Register',
        color: AppColors.farmerPrimary,
        route: '/register-animal',
      ),
      _QuickAction(
        icon: Icons.set_meal,
        label: 'Slaughter',
        color: AppColors.error,
        route: '/slaughter-animal',
      ),
      _QuickAction(
        icon: Icons.send,
        label: 'Transfer',
        color: AppColors.processorPrimary,
        route: '/select-animals-transfer',
      ),
      _QuickAction(
        icon: Icons.history,
        label: 'History',
        color: AppColors.info,
        route: '/farmer/livestock-history',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space24,
        AppTheme.space16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTypography.headlineMedium(),
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions.map((action) {
              return _buildQuickActionButton(action);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(_QuickAction action) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
        child: InkWell(
          onTap: () => context.push(action.route),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    action.icon,
                    color: action.color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  action.label,
                  style: AppTypography.labelMedium().copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space32),
      child: EmptyStateCard(
        icon: Icons.pets,
        message: 'No Animals Yet',
        subtitle: 'Start by registering your first animal to begin tracking your livestock.',
        action: CustomButton(
          label: 'Register Animal',
          onPressed: () => context.push('/register-animal'),
        ),
      ),
    );
  }
}

/// Quick action button data model
class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}
