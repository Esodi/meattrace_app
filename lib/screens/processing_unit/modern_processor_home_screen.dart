import 'dart:async';
import 'dart:math' as math;
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
import '../../widgets/core/role_avatar.dart';

/// Modern Processing Unit Dashboard with Material Design 3
/// Features: Production metrics, pending transfers, product inventory, quality overview
class ModernProcessorHomeScreen extends StatefulWidget {
  const ModernProcessorHomeScreen({super.key});

  @override
  State<ModernProcessorHomeScreen> createState() =>
      _ModernProcessorHomeScreenState();
}

class _ModernProcessorHomeScreenState extends State<ModernProcessorHomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _productsAnimationController;
  late List<Animation<double>> _productAnimations;

  int _pendingAnimalsCount = 0;
  bool _isLoadingPending = false;
  int _selectedIndex = 0;
  ProductionStats? _productionStats;
  Timer? _autoRefreshTimer;

  // Getter to return pending count from production stats or fallback to local count
  int get pendingCount {
    return _productionStats?.pending ?? _pendingAnimalsCount;
  }

  // Getter to return received count from production stats
  int get receivedCount {
    return _productionStats?.received ?? 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _productsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _productAnimations = List.generate(5, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _productsAnimationController,
          curve: Interval(
            index * 0.1,
            (index + 1) * 0.1 + 0.3,
            curve: Curves.elasticOut,
          ),
        ),
      );
    });

    // Processing pipeline animations removed - feature deprecated

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _productsAnimationController.forward();
      });
      _loadData();
      _startAutoRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      debugPrint('🔄 App resumed - refreshing Processor Dashboard');
      _loadData();
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      // Pause auto-refresh when app is in background
      debugPrint('⏸️ App paused - stopping auto-refresh');
      _autoRefreshTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _productsAnimationController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh data every 30 seconds for dynamic updates
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        debugPrint('🔄 Auto-refreshing Processor Dashboard data...');
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final apiService = ApiService();

    await Future.wait([
      animalProvider.fetchAnimals(slaughtered: null),
      productProvider.fetchProducts(),
      _loadPendingAnimalsCount(),
      _loadProductionStats(),
      apiService.fetchDashboard(), // Fetch dashboard data
      apiService.fetchActivities(), // Fetch activity data
    ]);
  }

  Future<void> _loadPendingAnimalsCount() async {
    if (!mounted) return;
    setState(() => _isLoadingPending = true);

    try {
      final animalProvider = Provider.of<AnimalProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final processingUnitId = authProvider.user?.processingUnitId;

      if (processingUnitId != null) {
        // Count whole animals transferred to this processor but not yet received
        final pendingWholeAnimals = animalProvider.animals.where((animal) {
          return animal.transferredTo == processingUnitId &&
              animal.receivedBy == null;
        }).length;

        // Count slaughter parts transferred to this processor but not yet received
        int pendingParts = 0;
        try {
          final allParts = await animalProvider.getSlaughterPartsList();
          pendingParts = allParts.where((part) {
            return part.transferredTo == processingUnitId &&
                part.receivedBy == null;
          }).length;
        } catch (e) {
          debugPrint('Error loading pending parts: $e');
        }

        final totalPending = pendingWholeAnimals + pendingParts;

        if (mounted) {
          setState(() => _pendingAnimalsCount = totalPending);
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

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      final stats = await apiService.fetchProductionStats(
        unitId: authProvider.user?.processingUnitId,
      );

      if (mounted) {
        setState(() => _productionStats = stats);
      }
    } catch (e) {
      debugPrint('Error loading production stats: $e');
      if (mounted) {
        setState(() => _productionStats = null);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  // Pipeline refresh and animation helpers removed

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
        automaticallyImplyLeading: false, // Hide drawer icon
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.processorPrimary,
                    AppColors.processorPrimary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(
                  'assets/icons/MEATTRACE_ICON.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
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
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: Badge(
              label: pendingCount > 0 ? Text('$pendingCount') : null,
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
              ),
            ),
            tooltip: 'Notifications',
            onPressed: () => context.push('/processor/notifications'),
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Settings',
            onPressed: () => context.push('/processor/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
          const SizedBox(width: AppTheme.space8),
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

              // Quick Actions
              SliverToBoxAdapter(child: _buildQuickActions()),

              // Processing Pipeline removed

              // Recent Products Section
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
                    return SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(
                          AppTheme.space16,
                          0,
                          AppTheme.space16,
                          AppTheme.space24,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.processorPrimary,
                          ),
                        ),
                      ),
                    );
                  }

                  final recentProducts = productProvider.products
                      .take(5)
                      .toList();

                  if (recentProducts.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(
                          AppTheme.space16,
                          0,
                          AppTheme.space16,
                          AppTheme.space24,
                        ),
                        child: _buildEnhancedEmptyState(),
                      ),
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
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = recentProducts[index];
                        return AnimatedBuilder(
                          animation: _productAnimations[index],
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                50 * (1 - _productAnimations[index].value),
                              ),
                              child: Opacity(
                                opacity: _productAnimations[index].value,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppTheme.space16,
                                  ),
                                  child: _buildEnhancedProductCard(
                                    product: product,
                                    index: index,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }, childCount: recentProducts.length),
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
    );
  }

  Widget _buildWelcomeHeader(String username) {
    // Gather provider-driven stats
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final processingUnitId = authProvider.user?.processingUnitId;
    final processingUnitName =
        authProvider.user?.processingUnitName ?? 'Processing Unit';

    // RECEIVED: Total number of received animals/parts since account creation
    int receivedAnimals = receivedCount;

    // PENDING: Total number of animals/parts not yet received
    int pendingAnimals = pendingCount;

    // PRODUCTS: Total number of products created
    int totalProducts = _productionStats?.totalProductsCreated ?? 0;

    // TRANSFERRED: Products transferred out
    int transferredProducts = productProvider.products
        .where(
          (p) =>
              p.processingUnit.toString() == processingUnitId?.toString() &&
              p.transferredTo != null,
        )
        .length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Header Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space24,
            AppTheme.space24,
            AppTheme.space24,
            80.0, // Extra bottom padding for floating card
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
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.processorPrimary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning,',
                          style: AppTypography.bodyMedium().copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          username,
                          style: AppTypography.headlineLarge().copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          processingUnitName,
                          style: AppTypography.bodyLarge().copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_circle_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Floating Stats Grid
        Positioned(
          bottom: -40,
          left: AppTheme.space16,
          right: AppTheme.space16,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildModernStatItem(
                  'Received',
                  receivedAnimals.toString(),
                  Icons.inbox,
                  AppColors.processorPrimary,
                ),
                _buildStatDivider(),
                _buildModernStatItem(
                  'Pending',
                  _isLoadingPending ? '...' : pendingAnimals.toString(),
                  Icons.schedule,
                  AppColors.warning,
                ),
                _buildStatDivider(),
                _buildModernStatItem(
                  'Products',
                  totalProducts.toString(),
                  CustomIcons.meatCut,
                  AppColors.secondaryBlue,
                ),
                _buildStatDivider(),
                _buildModernStatItem(
                  'Transferred',
                  transferredProducts.toString(),
                  Icons.local_shipping_outlined,
                  AppColors.success,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.space8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          value,
          style: AppTypography.titleLarge().copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall().copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 40, width: 1, color: AppColors.divider);
  }

  Widget _buildStatsSection(
    AnimalProvider animalProvider,
    ProductProvider productProvider,
  ) {
    // Overview moved into welcome header; keep this section minimal or use for
    // additional, wider stats in future. For now render nothing to avoid
    // duplicate overview UI.
    return const SizedBox.shrink();
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.download_rounded,
        label: 'Receive',
        color: AppColors.processorPrimary,
        route: '/receive-animals',
        badge: pendingCount > 0 ? pendingCount : null,
      ),
      _QuickAction(
        icon: CustomIcons.meatCut,
        label: 'Process',
        color: const Color(0xFF6C63FF),
        route: '/create-product',
      ),
      _QuickAction(
        icon: Icons.grid_view_rounded,
        label: 'Categories',
        color: const Color(0xFF00BFA5),
        route: '/processor/product-categories',
      ),
      _QuickAction(
        icon: Icons.local_shipping_rounded,
        label: 'Transfer',
        color: const Color(0xFFFF6B6B),
        route: '/transfer-products',
      ),
      _QuickAction(
        icon: Icons.warehouse_rounded,
        label: 'Inventory',
        color: const Color(0xFF4B7BEC),
        route: '/processor/current-inventory',
      ),
      _QuickAction(
        icon: Icons.add_home_work,
        label: 'Stock',
        color: AppColors.processorPrimary,
        route: '/onboarding-inventory',
      ),
      _QuickAction(
        icon: Icons.business_center,
        label: 'Vendors',
        color: AppColors.secondaryBlue,
        route: '/external-vendors',
      ),
      _QuickAction(
        icon: Icons.analytics_outlined,
        label: 'Traceability',
        color: const Color(0xFFF39C12),
        route: '/processor/traceability',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space32,
        AppTheme.space20,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: AppTypography.headlineSmall().copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.processorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Operations',
                  style: AppTypography.labelSmall().copyWith(
                    color: AppColors.processorPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space20),
          LayoutBuilder(
            builder: (context, constraints) {
              final int crossAxisCount = constraints.maxWidth < 360 ? 3 : 4;
              return GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.82,
                ),
                itemCount: actions.length,
                itemBuilder: (context, index) =>
                    _buildQuickActionButton(actions[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(_QuickAction action) {
    return InkWell(
      onTap: () => context.push(action.route),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: action.color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: action.color.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action.icon, color: action.color, size: 24),
                ),
                if (action.badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          '${action.badge}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              action.label,
              style: AppTypography.labelMedium().copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            AppColors.backgroundLight.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.processorPrimary.withValues(alpha: 0.1),
                  AppColors.processorPrimary.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CustomIcons.meatCut,
              color: AppColors.processorPrimary,
              size: 48,
            ),
          ),
          const SizedBox(height: AppTheme.space20),
          Text(
            'No Products Yet',
            style: AppTypography.headlineMedium().copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Start by receiving animals and creating your first products.',
            style: AppTypography.bodyLarge().copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space24),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.processorPrimary,
                  AppColors.processorPrimary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: AppColors.processorPrimary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CustomButton(
              label: 'Receive Animals',
              onPressed: () => context.push('/receive-animals'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProductCard({
    required dynamic product,
    required int index,
  }) {
    final String productType = product.productType ?? 'Unknown Product';
    final String batchNumber = product.batchNumber ?? 'N/A';
    final double weight = product.weight ?? 0.0;
    final String weightUnit = product.weightUnit ?? 'kg';
    final DateTime? createdAt = product.createdAt;

    return InkWell(
      onTap: () => context.push('/products/${product.id}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Lead Indicator Side
              Container(width: 6, color: AppColors.processorPrimary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Icon Badge
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.processorPrimary.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          CustomIcons.meatCut,
                          color: AppColors.processorPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    productType.toUpperCase(),
                                    style: AppTypography.labelLarge().copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (product.isExternal) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryBlue.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'External',
                                      style: AppTypography.labelSmall()
                                          .copyWith(
                                            color: AppColors.secondaryBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: AppTypography.labelSmall().copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Batch #$batchNumber',
                              style: AppTypography.labelMedium().copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildProductBadge(
                                  Icons.monitor_weight_outlined,
                                  '$weight $weightUnit',
                                  Colors.blueGrey,
                                ),
                                const SizedBox(width: 8),
                                _buildProductBadge(
                                  Icons.event_available_outlined,
                                  createdAt != null
                                      ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                                      : 'N/A',
                                  Colors.blueGrey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
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

  Widget _buildProductBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall().copyWith(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
                    if (_selectedIndex != 0) _onNavItemTapped(0);
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
                  icon: Icons.qr_code_scanner,
                  title: 'Scan QR',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/qr-scanner');
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
              style: AppTypography.bodyLarge().copyWith(color: AppColors.error),
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
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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
      title: Text(title, style: AppTypography.bodyLarge()),
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

  // Pipeline helpers and fallback stage removed

  /// Speed Dial FAB Widget
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

/// Custom painter for dashed border animation
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashLength = 6.0,
    this.gapLength = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final circumference = 2 * math.pi * radius;
    final dashAndGapLength = dashLength + gapLength;
    final dashCount = (circumference / dashAndGapLength).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * dashAndGapLength) / radius;
      final endAngle = ((i * dashAndGapLength) + dashLength) / radius;

      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(radius, radius),
          radius: radius - strokeWidth / 2,
        ),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
