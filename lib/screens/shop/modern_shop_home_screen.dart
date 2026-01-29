import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';

import '../../services/sale_service.dart';
import '../../models/product.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/role_avatar.dart';
import '../../widgets/livestock/product_card.dart';

class ModernShopHomeScreen extends StatefulWidget {
  const ModernShopHomeScreen({super.key});

  @override
  State<ModernShopHomeScreen> createState() => _ModernShopHomeScreenState();
}

class _ModernShopHomeScreenState extends State<ModernShopHomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _pendingProductsCount = 0;
  double _totalSales = 0.0;
  Timer? _autoRefreshTimer;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _loadData();
      _startAutoRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadData();
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
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
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    await Future.wait([
      productProvider.fetchProducts(forceRefresh: forceRefresh),
      _loadPendingProductsCount(),
      _loadTotalSales(),
    ]);
  }

  Future<void> _loadTotalSales() async {
    if (!mounted) return;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = authProvider.user?.shopId;
      if (shopId != null) {
        final sales = await SaleService().getSales(shop: shopId);
        final total = sales.fold<double>(
          0.0,
          (prev, s) => prev + (s.totalAmount),
        );
        if (mounted) setState(() => _totalSales = total);
      }
    } catch (e) {
      debugPrint('Error loading sales total: $e');
    }
  }

  Future<void> _loadPendingProductsCount() async {
    if (!mounted) return;
    try {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = authProvider.user?.shopId;
      if (shopId != null) {
        final pendingProducts = productProvider.products.where((product) {
          return product.transferredTo == shopId &&
              product.receivedByShopId == null;
        }).length;
        if (mounted) setState(() => _pendingProductsCount = pendingProducts);
      }
    } catch (e) {
      debugPrint('Error loading pending count: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadData(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.shopPrimary,
                    AppColors.shopPrimary.withValues(alpha: 0.8),
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
                  Text('MeatTrace Pro', style: AppTypography.headlineMedium()),
                  Text(
                    'Shop Dashboard',
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
            icon: const Icon(
              CustomIcons.MEATTRACE_ICON,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Scan QR Code',
            onPressed: () => context.push('/qr-scanner'),
          ),
          IconButton(
            icon: Badge(
              label: _pendingProductsCount > 0
                  ? Text('$_pendingProductsCount')
                  : null,
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
              ),
            ),
            tooltip: 'Notifications',
            onPressed: () => context.push('/receive-products'),
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Settings',
            onPressed: () => context.push('/shop/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthProvider>().logout(),
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
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.shopPrimary,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildWelcomeHeader(user?.username ?? 'Shop'),
              ),
              SliverToBoxAdapter(child: _buildQuickActions()),
              SliverToBoxAdapter(
                child: Consumer<ProductProvider>(
                  builder: (context, productProvider, child) =>
                      _buildInventoryOverview(productProvider),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space16,
                    0.1,
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
                        onPressed: () => context.push('/shop/inventory'),
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
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoading) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final currentShopId = authProvider.user?.shopId;
                  final featuredProducts =
                      productProvider.products
                          .where(
                            (p) =>
                                p.receivedByShopId == currentShopId &&
                                p.quantity > 0,
                          )
                          .toList()
                        ..sort((a, b) => b.price.compareTo(a.price))
                        ..take(3).toList();

                  if (featuredProducts.isEmpty) {
                    return SliverToBoxAdapter(child: _buildEmptyFeatured());
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
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.space12,
                          ),
                          child: _buildFeaturedProductCard(
                            featuredProducts[index],
                          ),
                        );
                      }, childCount: featuredProducts.length),
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space16,
                    16,
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
                        onPressed: () => context.push('/shop/inventory'),
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
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  final currentShopId = authProvider.user?.shopId;
                  final shopProducts = productProvider.products
                      .where((p) => p.receivedByShopId == currentShopId)
                      .take(5)
                      .toList();
                  if (shopProducts.isEmpty) {
                    return SliverToBoxAdapter(child: _buildEmptyState());
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
                        final product = shopProducts[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.space12,
                          ),
                          child: ProductCard(
                            productId: product.id.toString(),
                            batchNumber: product.batchNumber,
                            productType: product.productType,
                            qualityGrade: 'premium',
                            weight: product.weight,
                            price: product.price.toDouble(),
                            isExternal: product.isExternal,
                            onTap: () =>
                                context.push('/products/${product.id}'),
                          ),
                        );
                      }, childCount: shopProducts.length),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String username) {
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentShopId = authProvider.user?.shopId;
    final shopProducts = productProvider.products
        .where((p) => p.receivedByShopId == currentShopId)
        .toList();
    final totalProducts = shopProducts.length;
    final lowStock = shopProducts
        .where((p) => p.quantity > 0 && p.quantity <= 10)
        .length;
    double totalValue = 0;
    for (var p in shopProducts) {
      totalValue += (p.price * p.quantity);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space24,
            AppTheme.space24,
            AppTheme.space24,
            80.0,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.shopPrimary, AppColors.shopDark],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shopPrimary.withValues(alpha: 0.3),
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
                  Column(
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
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),
              Text(
                'Shop Overview',
                style: AppTypography.titleLarge().copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                'You have $totalProducts products in stock.',
                style: AppTypography.bodySmall().copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -40,
          left: AppTheme.space16,
          right: AppTheme.space16,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
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
                  'Products',
                  totalProducts.toString(),
                  CustomIcons.meatCut,
                  AppColors.shopPrimary,
                ),
                _buildStatDivider(),
                _buildModernStatItem(
                  'Low Stock',
                  lowStock.toString(),
                  Icons.warning_amber_rounded,
                  AppColors.warning,
                ),
                _buildStatDivider(),
                _buildModernStatItem(
                  'Value',
                  _formatCurrency(totalValue),
                  Icons.attach_money,
                  AppColors.success,
                ),
                _buildStatDivider(),
                _buildModernStatItem(
                  'Sales',
                  _formatCurrency(_totalSales),
                  Icons.point_of_sale,
                  AppColors.secondaryBlue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 40, width: 1, color: AppColors.divider);
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

  String _formatCurrency(double value) => value >= 1000000
      ? '${(value / 1000000).toStringAsFixed(1)}M'
      : value >= 1000
      ? '${(value / 1000).toStringAsFixed(0)}K'
      : value.toStringAsFixed(0);

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTypography.headlineMedium()),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.9,
            children: [
              _buildQuickBtn(
                Icons.inbox,
                'Receive',
                AppColors.shopPrimary,
                '/receive-products',
              ),
              _buildQuickBtn(
                Icons.inventory,
                'Inventory',
                AppColors.secondaryBlue,
                '/shop/inventory',
              ),
              _buildQuickBtn(
                Icons.add_shopping_cart,
                'Add Stock',
                AppColors.processorPrimary,
                '/onboarding-inventory',
              ),
              _buildQuickBtn(
                Icons.point_of_sale,
                'New Sale',
                AppColors.success,
                '/shop/sell',
              ),
              _buildQuickBtn(
                Icons.history,
                'Sales History',
                AppColors.secondaryBlue,
                '/shop/sales',
              ),
              _buildQuickBtn(
                Icons.qr_code_scanner,
                'Scan',
                AppColors.warning,
                '/qr-scanner',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBtn(
    IconData icon,
    String label,
    Color color,
    String route,
  ) {
    return InkWell(
      onTap: () => context.push(route),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSmall(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryOverview(ProductProvider productProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shopProducts = productProvider.products
        .where((p) => p.receivedByShopId == authProvider.user?.shopId)
        .toList();
    final total = shopProducts.length;
    if (total == 0) return const SizedBox.shrink();
    final inStock = shopProducts.where((p) => p.quantity > 10).length;
    final low = shopProducts
        .where((p) => p.quantity > 0 && p.quantity <= 10)
        .length;
    final out = shopProducts.where((p) => p.quantity == 0).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inventory Overview', style: AppTypography.headlineMedium()),
          const SizedBox(height: 16),
          _buildBar(
            'In Stock',
            (inStock / total) * 100,
            AppColors.success,
            inStock,
          ),
          _buildBar('Low Stock', (low / total) * 100, AppColors.warning, low),
          _buildBar('Out of Stock', (out / total) * 100, AppColors.error, out),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double val, Color color, int count) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text('$count items')],
        ),
        LinearProgressIndicator(
          value: val / 100,
          color: color,
          backgroundColor: Colors.black12,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFeaturedProductCard(Product product) {
    return CustomCard(
      child: ListTile(
        onTap: () => context.push('/products/${product.id}'),
        leading: const Icon(CustomIcons.meatCut, color: AppColors.shopPrimary),
        title: Text(product.name),
        subtitle: Text('Batch: ${product.batchNumber}'),
        trailing: Text('TZS ${product.price.toStringAsFixed(0)}'),
      ),
    );
  }

  Widget _buildEmptyFeatured() => Center(child: Text('No featured products'));
  Widget _buildEmptyState() => Center(child: Text('Empty inventory'));
}
