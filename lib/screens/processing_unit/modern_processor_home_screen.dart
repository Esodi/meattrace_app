import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/animal_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/production_stats.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/status_badge.dart';
import '../../widgets/core/role_avatar.dart';
import '../../widgets/livestock/product_card.dart';

/// Modern Processing Unit Dashboard with Material Design 3
/// Features: Production metrics, pending transfers, product inventory, quality overview
class ModernProcessorHomeScreen extends StatefulWidget {
  const ModernProcessorHomeScreen({super.key});

  @override
  State<ModernProcessorHomeScreen> createState() => _ModernProcessorHomeScreenState();
}

class _ModernProcessorHomeScreenState extends State<ModernProcessorHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _pendingAnimalsCount = 0;
  bool _isLoadingPending = false;
  int _selectedIndex = 0;
  ProductionStats? _productionStats;
  bool _isLoadingStats = false;
  Map<String, dynamic>? _pipeline;
  bool _isLoadingPipeline = false;

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
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final apiService = ApiService();

    await Future.wait([
      animalProvider.fetchAnimals(slaughtered: null),
      productProvider.fetchProducts(),
      _loadPendingAnimalsCount(),
      _loadProductionStats(),
      apiService.fetchDashboard(), // Fetch dashboard data
      apiService.fetchActivities(), // Fetch activity data
      _loadProcessingPipeline(),
    ]);
  }

  Future<void> _loadProcessingPipeline() async {
    if (!mounted) return;
    setState(() => _isLoadingPipeline = true);

    try {
      final apiService = ApiService();
      final data = await apiService.fetchProcessingPipeline();

      if (mounted) {
        setState(() => _pipeline = data);
      }
    } catch (e) {
      debugPrint('Error loading processing pipeline: $e');
      if (mounted) setState(() => _pipeline = null);
    } finally {
      if (mounted) setState(() => _isLoadingPipeline = false);
    }
  }

  Future<void> _advancePipeline() async {
    final apiService = ApiService();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Advancing pipeline...')),
    );

    try {
      // Try a backend endpoint for advancing pipeline. Backend may not
      // expose this; handle errors gracefully.
      await apiService.post('/processing-pipeline/advance/');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pipeline advanced')),
      );
      await _loadProcessingPipeline();
      await _loadPendingAnimalsCount();
      await _loadProductionStats();
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not advance pipeline: $e')),
      );
      debugPrint('Advance pipeline failed: $e');
    }
  }

  Future<void> _loadPendingAnimalsCount() async {
    if (!mounted) return;
    setState(() => _isLoadingPending = true);

    try {
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // The backend stores `transferred_to` as a ProcessingUnit id. The local
      // user object contains `processingUnitId` (the id of the ProcessingUnit)
      // so compare against that, not the user's numeric id.
      final processingUnitId = authProvider.user?.processingUnitId;

      if (processingUnitId != null) {
        // Count animals transferred to this processor but not yet received
        final pendingAnimals = animalProvider.animals.where((animal) {
          return animal.transferredTo == processingUnitId && animal.receivedBy == null;
        }).length;

        if (mounted) {
          setState(() => _pendingAnimalsCount = pendingAnimals);
        }
      }
    } catch (e) {
      debugPrint('Error loading pending count: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPending = false);
      }
    }
  }

  Future<void> _loadProductionStats() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);

    try {
      final apiService = ApiService();
      final stats = await apiService.fetchProductionStats();

      if (mounted) {
        setState(() => _productionStats = stats);
      }
    } catch (e) {
      debugPrint('Error loading production stats: $e');
      // Keep existing stats or set to null on error
      if (mounted) {
        setState(() => _productionStats = null);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
    
    switch (index) {
      case 0: // Dashboard - already here
        break;
      case 1: // Products
        context.push('/processor/products');
        break;
      case 2: // Scan
        context.push('/qr-scanner');
        break;
      case 3: // Settings
        context.push('/processor/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColors.backgroundLight,
      drawer: _buildNavigationDrawer(user),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          tooltip: 'Menu',
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Processing Unit',
              style: AppTypography.headlineMedium(),
            ),
            Text(
              'Production Dashboard',
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              label: _pendingAnimalsCount > 0 ? Text('$_pendingAnimalsCount') : null,
              child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            ),
            tooltip: 'Notifications',
            onPressed: () => context.push('/receive-animals'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            tooltip: 'Settings',
            onPressed: () => context.push('/processor/settings'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.space16),
            child: RoleAvatar(
              name: user?.username ?? 'P',
              role: 'processing_unit',
              size: AvatarSize.small,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.processorPrimary,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // Welcome Header
              SliverToBoxAdapter(
                child: _buildWelcomeHeader(user?.username ?? 'Processor'),
              ),

              // Stats Cards
              SliverToBoxAdapter(
                child: Consumer2<AnimalProvider, ProductProvider>(
                  builder: (context, animalProvider, productProvider, child) {
                    return _buildStatsSection(animalProvider, productProvider);
                  },
                ),
              ),

              // Processing Pipeline Section
              SliverToBoxAdapter(
                child: _buildProcessingPipeline(),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: _buildQuickActions(),
              ),

              // Pending Transfers Section
              if (_pendingAnimalsCount > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space16,
                      AppTheme.space24,
                      AppTheme.space16,
                      AppTheme.space12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Pending Transfers',
                              style: AppTypography.headlineMedium(),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            CountBadge(count: _pendingAnimalsCount),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.push('/receive-animals'),
                          child: Text(
                            'View All',
                            style: AppTypography.button().copyWith(
                              color: AppColors.processorPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Recent Products Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.space16,
                    _pendingAnimalsCount > 0 ? 0 : AppTheme.space24,
                    AppTheme.space16,
                    AppTheme.space8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Products',
                        style: AppTypography.headlineMedium(),
                      ),
                      TextButton(
                        onPressed: () => context.push('/processor/products'),
                        child: Text(
                          'View All',
                          style: AppTypography.button().copyWith(
                            color: AppColors.processorPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Products List
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoading) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.processorPrimary,
                        ),
                      ),
                    );
                  }

                  final recentProducts = productProvider.products.take(5).toList();

                  if (recentProducts.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyState(),
                    );
                  }

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
                          final product = recentProducts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.space12),
                            child: ProductCard(
                              productId: product.id.toString(),
                              batchNumber: product.batchNumber,
                              productType: product.productType,
                              qualityGrade: 'premium',
                              weight: product.weight,
                              productionDate: product.createdAt,
                              onTap: () => context.push('/products/${product.id}'),
                            ),
                          );
                        },
                        childCount: recentProducts.length,
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
      floatingActionButton: _buildSpeedDialFAB(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.processorPrimary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: AppTypography.labelMedium().copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelMedium(),
        elevation: 8,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(String username) {
    // Gather provider-driven stats inside the welcome card so the overview
    // appears within the same hero card (following the farmer dashboard pattern)
    final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final receivedAnimals = _productionStats?.totalAnimalsReceived ??
        animalProvider.animals.where((a) => a.receivedBy == authProvider.user?.id).length;
    final totalProducts = _productionStats?.totalProductsCreated ?? productProvider.products.length;
    final activeProducts = _productionStats?.totalProductsTransferred != null
        ? (totalProducts - _productionStats!.totalProductsTransferred)
        : productProvider.products.where((p) => p.transferredTo == null).length;

    return Container(
      margin: const EdgeInsets.all(AppTheme.space16),
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.processorPrimary,
            AppColors.processorPrimary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.processorPrimary.withValues(alpha: 0.3),
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
                  CustomIcons.processingPlant,
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
              if (_pendingAnimalsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space12,
                    vertical: AppTheme.space8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: AppTheme.space4),
                      Text(
                        '$_pendingAnimalsCount Pending',
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
                    'Process animals into quality meat products',
                    style: AppTypography.bodyMedium().copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space24),
          // Production Overview inside the welcome card (farmer-style)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Production Overview',
                style: AppTypography.headlineMedium().copyWith(
                  color: Colors.white,
                ),
              ),
              if (_isLoadingStats)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
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
                  label: 'Received',
                  value: receivedAnimals.toString(),
                  subtitle: 'Animals',
                  icon: Icons.inbox,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: _buildStatsCardInWelcome(
                  label: 'Pending',
                  value: _isLoadingPending ? '...' : _pendingAnimalsCount.toString(),
                  subtitle: 'Transfers',
                  icon: Icons.schedule,
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
                  label: 'Products',
                  value: totalProducts.toString(),
                  subtitle: 'Total',
                  icon: CustomIcons.meatCut,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: _buildStatsCardInWelcome(
                  label: 'In Stock',
                  value: activeProducts.toString(),
                  subtitle: 'Products',
                  icon: Icons.inventory,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(AnimalProvider animalProvider, ProductProvider productProvider) {
    // Overview moved into welcome header; keep this section minimal or use for
    // additional, wider stats in future. For now render nothing to avoid
    // duplicate overview UI.
    return const SizedBox.shrink();
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
        icon: Icons.inbox,
        label: 'Receive',
        color: AppColors.info,
        route: '/receive-animals',
        badge: _pendingAnimalsCount > 0 ? _pendingAnimalsCount : null,
      ),
      _QuickAction(
        icon: CustomIcons.meatCut,
        label: 'Process',
        color: AppColors.processorPrimary,
        route: '/create-product',
      ),
      _QuickAction(
        icon: Icons.category,
        label: 'Categories',
        color: AppColors.secondaryBlue,
        route: '/processor/product-categories',
      ),
      _QuickAction(
        icon: Icons.send,
        label: 'Transfer',
        color: AppColors.warning,
        route: '/transfer-products',
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
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: AppTheme.space8,
            mainAxisSpacing: AppTheme.space8,
            childAspectRatio: 0.9,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: actions.map((action) => _buildQuickActionButton(action)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(_QuickAction action) {
    return InkWell(
      onTap: () => context.push(action.route),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
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
                if (action.badge != null)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          '${action.badge}',
                          style: AppTypography.labelSmall().copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space32),
      child: EmptyStateCard(
        icon: CustomIcons.meatCut,
        message: 'No Products Yet',
        subtitle: 'Start by receiving animals and creating your first products.',
        action: CustomButton(
          label: 'Receive Animals',
          onPressed: () => context.push('/receive-animals'),
        ),
      ),
    );
  }

  /// Navigation Drawer Widget
  Widget _buildNavigationDrawer(dynamic user) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header with User Profile
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space48,
              AppTheme.space16,
              AppTheme.space16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.processorPrimary,
                  AppColors.processorPrimary.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RoleAvatar(
                  name: user?.username ?? 'Processor',
                  role: 'processing_unit',
                  size: AvatarSize.large,
                ),
                const SizedBox(height: AppTheme.space12),
                Text(
                  user?.username ?? 'Processor',
                  style: AppTypography.headlineMedium().copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Processing Unit',
                  style: AppTypography.bodyMedium().copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.inventory_2,
                  title: 'Products',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/processor/products');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.inbox,
                  title: 'Receive Animals',
                  badge: _pendingAnimalsCount > 0 ? _pendingAnimalsCount : null,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/receive-animals');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.qr_code,
                  title: 'QR Codes',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/processor-qr-codes');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Analytics',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/processor/analytics');
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/processor/settings');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/help');
                  },
                ),
              ],
            ),
          ),

          // Logout Button
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              'Logout',
              style: AppTypography.bodyLarge().copyWith(
                color: AppColors.error,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog();
            },
          ),
          const SizedBox(height: AppTheme.space16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? badge,
  }) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: AppColors.processorPrimary),
          if (badge != null)
            Positioned(
              right: -8,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    '$badge',
                    style: AppTypography.labelSmall().copyWith(
                      color: Colors.white,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge(),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
              context.go('/login');
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Processing Pipeline Visualization Widget
  Widget _buildProcessingPipeline() {
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
            'Processing Pipeline',
            style: AppTypography.headlineMedium(),
          ),
          const SizedBox(height: AppTheme.space12),
          Container(
            padding: const EdgeInsets.all(AppTheme.space20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
                // Pipeline Visual
                Row(
                  children: [
                    _buildPipelineStage(
                      icon: Icons.inbox,
                      label: 'Receive',
                      isActive: true,
                      isCompleted: true,
                    ),
                    _buildPipelineConnector(isActive: true),
                    _buildPipelineStage(
                      icon: Icons.search,
                      label: 'Inspect',
                      isActive: true,
                      isCompleted: false,
                    ),
                    _buildPipelineConnector(isActive: false),
                    _buildPipelineStage(
                      icon: Icons.factory,
                      label: 'Process',
                      isActive: false,
                      isCompleted: false,
                    ),
                    _buildPipelineConnector(isActive: false),
                    _buildPipelineStage(
                      icon: Icons.inventory,
                      label: 'Stock',
                      isActive: false,
                      isCompleted: false,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space16),
                // Queue Info
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: AppColors.processorPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: AppColors.processorPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        '$_pendingAnimalsCount items in queue',
                        style: AppTypography.bodyMedium().copyWith(
                          color: AppColors.processorPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStage({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success
                  : isActive
                      ? AppColors.processorPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isActive || isCompleted
                  ? Colors.white
                  : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            label,
            style: AppTypography.labelSmall().copyWith(
              color: isActive || isCompleted
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineConnector({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.processorPrimary
              : AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  /// Speed Dial FAB Widget
  Widget _buildSpeedDialFAB() {
    return FloatingActionButton(
      onPressed: () => _showSpeedDialActions(),
      backgroundColor: AppColors.processorPrimary,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showSpeedDialActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
        ),
        padding: const EdgeInsets.all(AppTheme.space16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7, // Max 70% of screen height
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Quick Actions',
                style: AppTypography.headlineMedium(),
              ),
              const SizedBox(height: AppTheme.space16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSpeedDialAction(
                        icon: Icons.play_arrow,
                        label: 'Process Batch',
                        color: AppColors.processorPrimary,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/create-product');
                        },
                      ),
                      _buildSpeedDialAction(
                        icon: Icons.inventory_2,
                        label: 'Producer Inventory',
                        color: AppColors.info,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/producer-inventory');
                        },
                      ),
                      _buildSpeedDialAction(
                        icon: Icons.inbox,
                        label: 'Receive Animals',
                        color: AppColors.warning,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/receive-animals');
                        },
                      ),
                      _buildSpeedDialAction(
                        icon: Icons.qr_code,
                        label: 'View QR Codes',
                        color: AppColors.success,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/processor-qr-codes');
                        },
                      ),
                      _buildSpeedDialAction(
                        icon: Icons.send,
                        label: 'Transfer Products',
                        color: AppColors.warning,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/transfer-products');
                        },
                      ),
                      _buildSpeedDialAction(
                        icon: Icons.category,
                        label: 'Product Categories',
                        color: AppColors.info,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/processor/product-categories');
                        },
                      ),
                      const SizedBox(height: AppTheme.space8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedDialAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space8),
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppTheme.space16),
            Text(
              label,
              style: AppTypography.bodyLarge().copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
  final int? badge;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    this.badge,
  });
}
