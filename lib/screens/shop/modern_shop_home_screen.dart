import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/api_service.dart';
import '../../services/sale_service.dart';
import '../../models/product.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/status_badge.dart';
import '../../widgets/core/role_avatar.dart';
import '../../widgets/livestock/product_card.dart';
import 'shop_inventory_screen.dart';
import 'order_history_screen.dart';
import 'shop_profile_screen.dart';
import 'place_order_screen.dart';

/// Modern Shop Dashboard with Material Design 3 and Bottom Navigation
/// Features: Inventory overview, sales metrics, product management, customer QR generation
/// Bottom Nav: Dashboard | Inventory | Orders | Profile
class ModernShopHomeScreen extends StatefulWidget {
  final int initialIndex;
  
  const ModernShopHomeScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<ModernShopHomeScreen> createState() => _ModernShopHomeScreenState();
}

class _ModernShopHomeScreenState extends State<ModernShopHomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late int _selectedIndex;

  int _pendingProductsCount = 0;
  bool _isLoadingPending = false;
  double _totalSales = 0.0;
  bool _isLoadingSales = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _selectedIndex = widget.initialIndex;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      if (_selectedIndex == 0) {
        _loadData();
        _startAutoRefresh();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      debugPrint('🔄 App resumed - refreshing Shop Dashboard');
      if (_selectedIndex == 0) {
        _loadData();
        _startAutoRefresh();
      }
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
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh data every 30 seconds for dynamic updates
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _selectedIndex == 0) {
        debugPrint('🔄 Auto-refreshing Shop Dashboard data...');
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final apiService = ApiService();
    await Future.wait([
      productProvider.fetchProducts(),
      _loadPendingProductsCount(),
      _loadTotalSales(),
      apiService.fetchDashboard(), // Fetch dashboard data
      apiService.fetchActivities(), // Fetch activity data
    ]);
  }

  Future<void> _loadTotalSales() async {
    if (!mounted) return;
    setState(() => _isLoadingSales = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = authProvider.user?.shopId;

      if (shopId != null) {
        final sales = await SaleService().getSales(shop: shopId);
        final total = sales.fold<double>(0.0, (prev, s) => prev + (s.totalAmount));
        if (mounted) setState(() => _totalSales = total);
      }
    } catch (e) {
      debugPrint('Error loading sales total: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSales = false);
    }
  }

  Future<void> _loadPendingProductsCount() async {
    if (!mounted) return;
    setState(() => _isLoadingPending = true);

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = authProvider.user?.shopId;

      if (shopId != null) {
        // Count products transferred to this shop but not yet received
        final pendingProducts = productProvider.products.where((product) {
          return product.transferredTo == shopId && product.receivedBy == null;
        }).length;

        if (mounted) {
          setState(() => _pendingProductsCount = pendingProducts);
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

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _selectedIndex == 0 ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MeatTrace Pro',
              style: AppTypography.headlineMedium(),
            ),
            Text(
              'Shop Dashboard',
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CustomIcons.MEATTRACE_ICON, color: AppColors.textPrimary),
            tooltip: 'Scan QR Code',
            onPressed: () => context.push('/qr-scanner'),
          ),
          IconButton(
            icon: Badge(
              label: _pendingProductsCount > 0 ? Text('$_pendingProductsCount') : null,
              child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            ),
            tooltip: 'Notifications',
            onPressed: () => context.push('/receive-products'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            tooltip: 'Settings',
            onPressed: () => context.push('/shop/settings'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.space16),
            child: RoleAvatar(
              name: user?.username ?? 'S',
              role: 'shop',
              size: AvatarSize.small,
            ),
          ),
        ],
      ) : null,
      body: _selectedIndex == 0
          ? RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.shopPrimary,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // Welcome Header
              SliverToBoxAdapter(
                child: _buildWelcomeHeader(user?.username ?? 'Shop'),
              ),

              // Stats Cards
              SliverToBoxAdapter(
                child: Consumer<ProductProvider>(
                  builder: (context, productProvider, child) {
                    return _buildStatsSection(productProvider);
                  },
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: _buildQuickActions(),
              ),

              // Inventory Overview
              SliverToBoxAdapter(
                child: Consumer<ProductProvider>(
                  builder: (context, productProvider, child) {
                    return _buildInventoryOverview(productProvider);
                  },
                ),
              ),

              // Featured Products Section
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
                        'Featured Products',
                        style: AppTypography.headlineMedium(),
                      ),
                      TextButton(
                        onPressed: () => context.push('/product-inventory'),
                        child: Text(
                          'View All',
                          style: AppTypography.button().copyWith(
                            color: AppColors.shopPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Featured Products List
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoading) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.shopPrimary,
                        ),
                      ),
                    );
                  }

                  final authProvider = Provider.of<AuthProvider>(context);
                  final currentShopId = authProvider.user?.shopId;

                  // Get featured products (top 3 by price, assuming higher price = premium)
                  final featuredProducts = productProvider.products
                      .where((p) => p.receivedBy == currentShopId && p.quantity > 0)
                      .toList()
                    ..sort((a, b) => b.price.compareTo(a.price))
                    ..take(3)
                    .toList();

                  if (featuredProducts.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.space32),
                        child: EmptyStateCard(
                          icon: Icons.star_border,
                          message: 'No Featured Products',
                          subtitle: 'Premium products will appear here once available.',
                          action: CustomButton(
                            label: 'Browse Inventory',
                            onPressed: () => context.push('/product-inventory'),
                          ),
                        ),
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
                          final product = featuredProducts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.space12),
                            child: _buildFeaturedProductCard(product),
                          );
                        },
                        childCount: featuredProducts.length,
                      ),
                    ),
                  );
                },
              ),

              // Inventory Section
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
                        'Recent Inventory',
                        style: AppTypography.headlineMedium(),
                      ),
                      TextButton(
                        onPressed: () => context.push('/product-inventory'),
                        child: Text(
                          'View All',
                          style: AppTypography.button().copyWith(
                            color: AppColors.shopPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Product Inventory List
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoading) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.shopPrimary,
                        ),
                      ),
                    );
                  }

                  final authProvider = Provider.of<AuthProvider>(context);
                  final currentShopId = authProvider.user?.shopId;

                  // Filter products received by this shop
                  final shopProducts = productProvider.products
                      .where((p) => p.receivedBy == currentShopId)
                      .take(5)
                      .toList();

                  if (shopProducts.isEmpty) {
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
                          final product = shopProducts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.space12),
                            child: ProductCard(
                              productId: product.id.toString(),
                              batchNumber: product.batchNumber ?? 'N/A',
                              productType: product.productType,
                              qualityGrade: 'premium',
                              weight: product.weight?.toDouble(),
                              price: product.price?.toDouble(),
                              onTap: () => context.push('/products/${product.id}'),
                            ),
                          );
                        },
                        childCount: shopProducts.length,
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
      )
      : _selectedIndex == 1
          ? const ShopInventoryScreen()
          : _selectedIndex == 2
              ? const OrderHistoryScreen()
              : const ShopProfileScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          // Restart auto-refresh when switching to Dashboard tab
          if (index == 0) {
            _loadData();
            _startAutoRefresh();
          } else {
            _autoRefreshTimer?.cancel();
          }
        },
        selectedItemColor: AppColors.shopPrimary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTypography.labelMedium(),
        unselectedLabelStyle: AppTypography.labelSmall(),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CustomIcons.shop),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? CustomFAB(
              icon: CustomIcons.MEATTRACE_ICON,
              tooltip: 'Generate QR',
              onPressed: () {
                // TODO: Navigate to QR generation screen
                _showQRGenerationDialog();
              },
            )
          : _selectedIndex == 2
              ? CustomFAB(
                  icon: Icons.point_of_sale,
                  tooltip: 'New Sale',
                  onPressed: () {
                    context.push('/shop/sell');
                  },
                )
              : null,
    );
  }

  Widget _buildWelcomeHeader(String username) {
    // compute shop-level stats to display inside the welcome card (farmer-style)
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentShopId = authProvider.user?.shopId;

    final shopProducts = productProvider.products.where((p) => p.receivedBy == currentShopId).toList();
    final totalProducts = shopProducts.length;
    final lowStock = shopProducts.where((p) => p.quantity > 0 && p.quantity <= 10).length;

    double totalInventoryValue = 0.0;
    for (var product in shopProducts) {
      totalInventoryValue += (product.price * product.quantity);
    }

    return Container(
      margin: const EdgeInsets.all(AppTheme.space16),
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.shopPrimary,
            AppColors.shopPrimary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.shopPrimary.withValues(alpha: 0.3),
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
                  CustomIcons.shop,
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
              if (_pendingProductsCount > 0)
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
                        '$_pendingProductsCount Pending',
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
                    'Manage inventory and provide traceability to customers',
                    style: AppTypography.bodyMedium().copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space24),
          // Sales / Production Overview inside the welcome card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Overview',
                style: AppTypography.headlineMedium().copyWith(
                  color: Colors.white,
                ),
              ),
              if (_isLoadingSales)
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
                  label: 'Products',
                  value: totalProducts.toString(),
                  subtitle: 'In Inventory',
                  icon: CustomIcons.meatCut,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: _buildStatsCardInWelcome(
                  label: 'Low Stock',
                  value: lowStock.toString(),
                  subtitle: 'Items',
                  icon: Icons.warning,
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
                  label: 'Inventory',
                  value: 'TZS ${totalInventoryValue.toStringAsFixed(0)}',
                  subtitle: 'Total Value',
                  icon: Icons.attach_money,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: _buildStatsCardInWelcome(
                  label: 'Sales',
                  value: 'TZS ${_totalSales.toStringAsFixed(2)}',
                  subtitle: 'Total Sales',
                  icon: Icons.point_of_sale,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ProductProvider productProvider) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentShopId = authProvider.user?.shopId;

    final shopProducts = productProvider.products.where((p) => p.receivedBy == currentShopId).toList();
    final totalProducts = shopProducts.length;
    final lowStock = shopProducts.where((p) => p.quantity > 0 && p.quantity <= 10).length;

    // Calculate total inventory value (sum of all products: price * quantity)
    double totalInventoryValue = 0.0;
    for (var product in shopProducts) {
      totalInventoryValue += (product.price * product.quantity);
    }

  // Use total sales fetched from Sales API

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview moved into welcome card for compact summary; avoid
          // duplicating content here. Keep this method for future wide stats.
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildInventoryOverview(ProductProvider productProvider) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentShopId = authProvider.user?.shopId;

    final shopProducts = productProvider.products.where((p) => p.receivedBy == currentShopId).toList();
    final totalProducts = shopProducts.length;
    final inStock = shopProducts.where((p) => p.quantity > 10).length;
    final lowStock = shopProducts.where((p) => p.quantity > 0 && p.quantity <= 10).length;
    final outOfStock = shopProducts.where((p) => p.quantity == 0).length;

    final inStockPercentage = totalProducts > 0 ? (inStock / totalProducts) * 100 : 0.0;
    final lowStockPercentage = totalProducts > 0 ? (lowStock / totalProducts) * 100 : 0.0;
    final outOfStockPercentage = totalProducts > 0 ? (outOfStock / totalProducts) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space24,
        AppTheme.space16,
        AppTheme.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Overview',
            style: AppTypography.headlineMedium(),
          ),
          const SizedBox(height: AppTheme.space16),
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                children: [
                  // In Stock Progress Bar
                  _buildProgressBar(
                    label: 'In Stock',
                    value: inStockPercentage,
                    color: AppColors.success,
                    count: inStock,
                  ),
                  const SizedBox(height: AppTheme.space16),

                  // Low Stock Progress Bar
                  _buildProgressBar(
                    label: 'Low Stock',
                    value: lowStockPercentage,
                    color: AppColors.warning,
                    count: lowStock,
                  ),
                  const SizedBox(height: AppTheme.space16),

                  // Out of Stock Progress Bar
                  _buildProgressBar(
                    label: 'Out of Stock',
                    value: outOfStockPercentage,
                    color: AppColors.error,
                    count: outOfStock,
                  ),
                ],
              ),
            ),
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

  Widget _buildProgressBar({
    required String label,
    required double value,
    required Color color,
    required int count,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium().copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${count} items (${value.toStringAsFixed(0)}%)',
              style: AppTypography.bodySmall().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.dividerLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedProductCard(Product product) {
    return CustomCard(
      child: InkWell(
        onTap: () => context.push('/products/${product.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Row(
            children: [
              // Product Image/Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.shopPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  CustomIcons.meatCut,
                  color: AppColors.shopPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.space16),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name and Rating
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: AppTypography.titleMedium().copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Star Rating
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space8,
                            vertical: AppTheme.space4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: AppColors.accentOrange,
                                size: 16,
                              ),
                              const SizedBox(width: AppTheme.space4),
                              Text(
                                '4.8', // Mock rating
                                style: AppTypography.labelSmall().copyWith(
                                  color: AppColors.accentOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space4),

                    // Batch Number and Stock
                    Row(
                      children: [
                        Text(
                          'Batch: ${product.batchNumber ?? 'N/A'}',
                          style: AppTypography.bodySmall().copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space8,
                            vertical: AppTheme.space4,
                          ),
                          decoration: BoxDecoration(
                            color: product.quantity > 10
                                ? AppColors.success.withValues(alpha: 0.1)
                                : product.quantity > 0
                                    ? AppColors.warning.withValues(alpha: 0.1)
                                    : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            product.quantity > 10
                                ? '${product.quantity} in stock'
                                : product.quantity > 0
                                    ? 'Low stock'
                                    : 'Out of stock',
                            style: AppTypography.labelSmall().copyWith(
                              color: product.quantity > 10
                                  ? AppColors.success
                                  : product.quantity > 0
                                      ? AppColors.warning
                                      : AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space8),

                    // Price
                    Text(
                      '\$${product.price.toStringAsFixed(2)}/kg',
                      style: AppTypography.titleMedium().copyWith(
                        color: AppColors.shopPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.inbox,
        label: 'Receive',
        color: AppColors.info,
        route: '/receive-products',
        badge: _pendingProductsCount > 0 ? _pendingProductsCount : null,
      ),
      _QuickAction(
        icon: Icons.inventory,
        label: 'Inventory',
        color: AppColors.shopPrimary,
        onTap: () => setState(() => _selectedIndex = 1), // Switch to inventory tab
      ),
      _QuickAction(
        icon: CustomIcons.MEATTRACE_ICON,
        label: 'Generate',
        color: AppColors.success,
        onTap: _showQRGenerationDialog,
      ),
      _QuickAction(
        icon: Icons.scanner,
        label: 'Scan',
        color: AppColors.farmerPrimary,
        route: '/qr-scanner',
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
          onTap: action.onTap ?? () {
            if (action.route != null) {
              context.push(action.route!);
            }
          },
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
        subtitle: 'Start by receiving products from processing units to build your inventory.',
        action: CustomButton(
          label: 'Receive Products',
          onPressed: () => context.push('/receive-products'),
        ),
      ),
    );
  }

  void _showQRGenerationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: AppColors.shopPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: const Icon(
                CustomIcons.MEATTRACE_ICON,
                color: AppColors.shopPrimary,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Text(
              'Generate QR Code',
              style: AppTypography.headlineMedium(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select a product to generate a customer QR code for traceability.',
              style: AppTypography.bodyMedium(),
            ),
            const SizedBox(height: AppTheme.space16),
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coming Soon',
                          style: AppTypography.titleMedium().copyWith(color: AppColors.info),
                        ),
                        Text(
                          'QR code generation feature will be available in the next update.',
                          style: AppTypography.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CustomButton(
            variant: ButtonVariant.secondary,
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Quick action button data model
class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String? route;
  final int? badge;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.route,
    this.badge,
    this.onTap,
  });
}
