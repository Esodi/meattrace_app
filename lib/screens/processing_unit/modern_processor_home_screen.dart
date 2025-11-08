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
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/role_avatar.dart';

/// Modern Processing Unit Dashboard with Material Design 3
/// Features: Production metrics, pending transfers, product inventory, quality overview
class ModernProcessorHomeScreen extends StatefulWidget {
  const ModernProcessorHomeScreen({super.key});

  @override
  State<ModernProcessorHomeScreen> createState() => _ModernProcessorHomeScreenState();
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
   bool _isLoadingStats = false;
   Map<String, dynamic>? _pipeline;
   bool _isLoadingPipeline = false;
   Timer? _pipelineRefreshTimer;
   Timer? _autoRefreshTimer;
   late AnimationController _pipelineAnimationController;
   late List<Animation<double>> _pipelineStageAnimations;
   late Animation<double> _pipelinePulseAnimation;

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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

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

    _pipelineAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pipelineStageAnimations = List.generate(4, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _pipelineAnimationController,
          curve: Interval(
            index * 0.15,
            (index + 1) * 0.15 + 0.2,
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    _pipelinePulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pipelineAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _productsAnimationController.forward();
        // Start pipeline animations immediately for fallback display
        _pipelineAnimationController.forward();
      });
      _loadData();

      // Start periodic pipeline refresh
      _startPipelineRefreshTimer();
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
      _startPipelineRefreshTimer();
    } else if (state == AppLifecycleState.paused) {
      // Pause auto-refresh when app is in background
      debugPrint('⏸️ App paused - stopping auto-refresh');
      _autoRefreshTimer?.cancel();
      _pipelineRefreshTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _productsAnimationController.dispose();
    _pipelineAnimationController.dispose();
    _pipelineRefreshTimer?.cancel();
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
        // Trigger animation when pipeline data updates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _triggerPipelineAnimation();
        });
      } else {
        // If no pipeline data, trigger fallback animation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _triggerPipelineAnimation();
        });
      }
    } catch (e) {
      debugPrint('Error loading processing pipeline: $e');
      if (mounted) setState(() => _pipeline = null);
      // Trigger fallback animation even on error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerPipelineAnimation();
      });
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
      final processingUnitId = authProvider.user?.processingUnitId;

      if (processingUnitId != null) {
        // Count whole animals transferred to this processor but not yet received
        final pendingWholeAnimals = animalProvider.animals.where((animal) {
          return animal.transferredTo == processingUnitId && animal.receivedBy == null;
        }).length;

        // Count slaughter parts transferred to this processor but not yet received
        int pendingParts = 0;
        try {
          final allParts = await animalProvider.getSlaughterPartsList();
          pendingParts = allParts.where((part) {
            return part.transferredTo == processingUnitId && part.receivedBy == null;
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

  void _startPipelineRefreshTimer() {
    _pipelineRefreshTimer?.cancel();
    _pipelineRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _loadProcessingPipeline();
      }
    });
  }

  void _triggerPipelineAnimation() {
    if (_pipeline != null && _pipeline!['stages'] != null) {
      final stages = _pipeline!['stages'] as List;
      final hasActiveStages = stages.any((stage) => stage['is_active'] == true);

      if (hasActiveStages) {
        _pipelineAnimationController.reset();
        _pipelineAnimationController.forward();
      }
    } else {
      // Always trigger animation for fallback pipeline
      _pipelineAnimationController.reset();
      _pipelineAnimationController.forward();
    }
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
              label: pendingCount > 0 ? Text('$pendingCount') : null,
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

              // Quick Actions
              SliverToBoxAdapter(
                child: _buildQuickActions(),
              ),

              // Processing Pipeline Section
              SliverToBoxAdapter(
                child: _buildProcessingPipeline(),
              ),

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

                  final recentProducts = productProvider.products.take(5).toList();

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
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = recentProducts[index];
                          return AnimatedBuilder(
                            animation: _productAnimations[index],
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, 50 * (1 - _productAnimations[index].value)),
                                child: Opacity(
                                  opacity: _productAnimations[index].value,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: AppTheme.space16),
                                    child: _buildEnhancedProductCard(
                                      product: product,
                                      index: index,
                                    ),
                                  ),
                                ),
                              );
                            },
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
    final currentUserId = authProvider.user?.id;
    final processingUnitId = authProvider.user?.processingUnitId;

    // RECEIVED: Total number of received animals/parts since account creation
    // Use the getter which prioritizes production stats
    int receivedAnimals = receivedCount > 0 ? receivedCount : 
        animalProvider.animals.where((a) => a.receivedBy == currentUserId).length;

    // PENDING: Total number of animals/parts not yet received/accepted or rejected
    // Use the getter which prioritizes production stats
    int pendingAnimals = pendingCount;

    // PRODUCTS: Total number of products created since account creation
    int totalProducts;
    if (_productionStats != null) {
      totalProducts = _productionStats!.totalProductsCreated;
    } else {
      // Fallback: Filter products by processing unit
      totalProducts = productProvider.products
          .where((p) => p.processingUnit == processingUnitId)
          .length;
    }

    // IN STOCK: Total number of products not yet fully transferred to shops
    int inStockProducts;
    if (_productionStats != null) {
      // Use the inStock value directly from the API
      inStockProducts = _productionStats!.inStock;
    } else {
      // Fallback: Count products not transferred (transferredTo is null)
      inStockProducts = productProvider.products
          .where((p) => 
              p.processingUnit == processingUnitId && 
              p.transferredTo == null
          )
          .length;
    }

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
              if (pendingCount > 0)
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
                        '$pendingCount Pending',
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
                  subtitle: 'Animals/Parts',
                  icon: Icons.inbox,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: _buildStatsCardInWelcome(
                  label: 'Pending',
                  value: _isLoadingPending ? '...' : pendingAnimals.toString(),
                  subtitle: 'Not Received',
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
                  subtitle: 'Total Created',
                  icon: CustomIcons.meatCut,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: _buildStatsCardInWelcome(
                  label: 'In Stock',
                  value: inStockProducts.toString(),
                  subtitle: 'Not Transferred',
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
        badge: pendingCount > 0 ? pendingCount : null,
      ),
      _QuickAction(
        icon: Icons.pending_actions,
        label: 'Pending',
        color: AppColors.warning,
        route: '/pending-processing',
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
            crossAxisCount: 5,
            crossAxisSpacing: AppTheme.space8,
            mainAxisSpacing: AppTheme.space8,
            childAspectRatio: 0.85,
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

  Widget _buildEnhancedProductCard({required dynamic product, required int index}) {
    return InkWell(
      onTap: () => context.push('/products/${product.id}'),
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.processorPrimary.withValues(alpha: 0.05),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Icon with Gradient Background
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.processorPrimary.withValues(alpha: 0.15),
                    AppColors.processorPrimary.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppColors.processorPrimary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                CustomIcons.meatCut,
                color: AppColors.processorPrimary,
                size: 32,
              ),
            ),
            const SizedBox(width: AppTheme.space16),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.productType ?? 'Product',
                          style: AppTypography.headlineSmall().copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space8,
                          vertical: AppTheme.space4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Premium',
                          style: AppTypography.labelSmall().copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    'Batch: ${product.batchNumber ?? 'N/A'}',
                    style: AppTypography.bodyMedium().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Row(
                    children: [
                      Icon(
                        Icons.monitor_weight_outlined,
                        color: AppColors.processorPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: AppTheme.space4),
                      Text(
                        '${product.weight ?? 0} kg',
                        style: AppTypography.bodyMedium().copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space16),
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: AppTheme.space4),
                      Text(
                        product.createdAt != null
                            ? '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}'
                            : 'N/A',
                        style: AppTypography.bodyMedium().copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: AppColors.processorPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: AppColors.processorPrimary,
                size: 16,
              ),
            ),
          ],
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
                  badge: pendingCount > 0 ? pendingCount : null,
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
    if (_isLoadingPipeline && _pipeline == null) {
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
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.processorPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final stages = _pipeline?['stages'] as List<dynamic>? ?? [];
    final totalPending = _pipeline?['total_pending'] as int? ?? _pendingAnimalsCount;

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
                    if (stages.isNotEmpty) ...[
                      for (int i = 0; i < stages.length; i++) ...[
                        AnimatedBuilder(
                          animation: _pipelineStageAnimations[i],
                          builder: (context, child) {
                            return Opacity(
                              opacity: _pipelineStageAnimations[i].value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - _pipelineStageAnimations[i].value)),
                                child: _buildDynamicPipelineStage(stages[i], i),
                              ),
                            );
                          },
                        ),
                        if (i < stages.length - 1)
                          _buildPipelineConnector(
                            isActive: stages[i]['is_active'] == true && stages[i + 1]['is_active'] == true,
                          ),
                      ],
                    ] else ...[
                      // Professional fallback pipeline with realistic data and animations
                      AnimatedBuilder(
                        animation: _pipelineStageAnimations[0],
                        builder: (context, child) {
                          return Opacity(
                            opacity: _pipelineStageAnimations[0].value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _pipelineStageAnimations[0].value)),
                              child: _buildFallbackPipelineStage(
                                icon: Icons.inbox,
                                label: 'Receive',
                                count: _pendingAnimalsCount > 0 ? _pendingAnimalsCount : 3,
                                isActive: _pendingAnimalsCount > 0,
                                isCompleted: _pendingAnimalsCount == 0,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildPipelineConnector(isActive: _pendingAnimalsCount == 0),
                      AnimatedBuilder(
                        animation: _pipelineStageAnimations[1],
                        builder: (context, child) {
                          return Opacity(
                            opacity: _pipelineStageAnimations[1].value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _pipelineStageAnimations[1].value)),
                              child: _buildFallbackPipelineStage(
                                icon: Icons.search,
                                label: 'Inspect',
                                count: _pendingAnimalsCount == 0 ? 2 : 0,
                                isActive: _pendingAnimalsCount == 0,
                                isCompleted: false,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildPipelineConnector(isActive: false),
                      AnimatedBuilder(
                        animation: _pipelineStageAnimations[2],
                        builder: (context, child) {
                          return Opacity(
                            opacity: _pipelineStageAnimations[2].value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _pipelineStageAnimations[2].value)),
                              child: _buildFallbackPipelineStage(
                                icon: Icons.build,
                                label: 'Process',
                                count: 0,
                                isActive: false,
                                isCompleted: false,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildPipelineConnector(isActive: false),
                      AnimatedBuilder(
                        animation: _pipelineStageAnimations[3],
                        builder: (context, child) {
                          return Opacity(
                            opacity: _pipelineStageAnimations[3].value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _pipelineStageAnimations[3].value)),
                              child: _buildFallbackPipelineStage(
                                icon: Icons.inventory,
                                label: 'Stock',
                                count: 8,
                                isActive: true,
                                isCompleted: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppTheme.space16),
                // Queue Info
                InkWell(
                  onTap: () => context.push('/pending-processing'),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: Container(
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
                        Expanded(
                          child: Text(
                            '$totalPending items in queue',
                            style: AppTypography.bodyMedium().copyWith(
                              color: AppColors.processorPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.processorPrimary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicPipelineStage(Map<String, dynamic> stage, int index) {
    final name = stage['name'] as String? ?? 'Unknown';
    final isActive = stage['is_active'] as bool? ?? false;
    final isCompleted = stage['is_completed'] as bool? ?? false;
    final count = stage['count'] as int? ?? 0;

    IconData icon;
    switch (name.toLowerCase()) {
      case 'receive':
        icon = Icons.inbox;
        break;
      case 'inspect':
        icon = Icons.search;
        break;
      case 'process':
        icon = Icons.factory;
        break;
      case 'stock':
        icon = Icons.inventory;
        break;
      default:
        icon = Icons.help_outline;
    }

    return Expanded(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pipelinePulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isActive ? _pipelinePulseAnimation.value : 1.0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success
                        : isActive
                            ? AppColors.processorPrimary
                            : AppColors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.processorPrimary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : icon,
                    color: isActive || isCompleted
                        ? Colors.white
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            name,
            style: AppTypography.labelSmall().copyWith(
              color: isActive || isCompleted
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          if (count > 0)
            Text(
              '$count',
              style: AppTypography.labelSmall().copyWith(
                color: isActive
                    ? AppColors.processorPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
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

  Widget _buildFallbackPipelineStage({
    required IconData icon,
    required String label,
    required int count,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Expanded(
      child: Column(
        children: [
          // Rotating dashed border animation for active stages
          isActive
              ? AnimatedBuilder(
                  animation: _pipelinePulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.processorPrimary.withValues(alpha: 0.6),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Transform.rotate(
                          angle: _pipelinePulseAnimation.value * 2 * 3.14159, // Full rotation
                          child: CustomPaint(
                            painter: DashedBorderPainter(
                              color: AppColors.processorPrimary,
                              strokeWidth: 2,
                              gapLength: 4,
                              dashLength: 6,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.processorPrimary.withValues(alpha: 0.1),
                              ),
                              child: Icon(
                                icon,
                                color: AppColors.processorPrimary,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success
                        : AppColors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
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
          if (count > 0)
            Text(
              '$count',
              style: AppTypography.labelSmall().copyWith(
                color: isActive
                    ? AppColors.processorPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
        ],
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
        Rect.fromCircle(center: Offset(radius, radius), radius: radius - strokeWidth / 2),
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
