import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/auth_provider.dart';
import '../providers/yield_trends_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';
import '../widgets/interactive_dashboard_card.dart';
import '../widgets/data_visualization_widgets.dart';
import '../widgets/enhanced_yield_trends_chart.dart';
import '../widgets/custom_dashboard_fabs.dart';
import '../widgets/responsive_dashboard_layout.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/real_time_progress_pipeline.dart';
import '../services/api_service.dart';
import '../services/dio_client.dart';
import '../models/production_stats.dart';
import '../models/processing_stage.dart' as models;
import '../models/order.dart';

class ProcessorHomeScreen extends StatefulWidget {
  const ProcessorHomeScreen({super.key});

  @override
  State<ProcessorHomeScreen> createState() => _ProcessorHomeScreenState();
}

class _ProcessorHomeScreenState extends State<ProcessorHomeScreen> with WidgetsBindingObserver {
  late ApiService _apiService;
  late DioClient _dioClient;
  ProductionStats? _productionStats;
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _dioClient = DioClient();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stats = await _apiService.fetchProductionStats();
      final orders = await _apiService.fetchOrders();

      if (mounted) {
        setState(() {
          _productionStats = stats;
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildOrdersList() {
    return Column(
      children: _orders.map((order) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Customer: ${order.customer}',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                Text(
                  'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Created: ${order.createdAt.toLocal().toString().split('.')[0]}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (order.qrCode != null && order.qrCode!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Processing QR Code:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.3)),
                      ),
                      child: Image.network(
                        '${DioClient.baseUrl}${order.qrCode}',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.qr_code,
                            size: 60,
                            color: Colors.grey,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Scan for detailed processing info',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return ResponsiveDashboardLayout(
      currentRoute: '/processor-home',
      content: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) return;
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Are you sure you want to exit the app?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('MeatTrace Processor'),
            actions: [
              const ThemeToggle(),
              const SizedBox(width: 8),
              const AccessibilityToggle(),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh data',
                onPressed: () => _refreshData(),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
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
              padding: EdgeInsets.all(Responsive.getPadding(context)).copyWith(bottom: 88.0),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      // Welcome section
                      InteractiveDashboardCard(
                        title: 'Welcome back, ${user?.username ?? 'Processor'}!',
                        value: 'Processing Dashboard',
                        icon: Icons.factory,
                        color: AppTheme.primaryGreen,
                        subtitle: 'Monitor your meat processing operations and quality control',
                        animationDelay: Duration.zero,
                      ),
                      const SizedBox(height: 24),

                      // Key Metrics Row
                      DashboardSection(
                        title: 'Key Metrics',
                        children: [
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_error != null)
                            Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.error, color: Colors.red, size: 48),
                                  const SizedBox(height: 8),
                                  Text('Error: $_error'),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _loadData,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          else if (_productionStats != null) ...[
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isSmallScreen = constraints.maxWidth < 400;
                                final spacing = isSmallScreen ? 8.0 : 16.0;
                                
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: MetricCard(
                                            title: 'Products Today',
                                            value: _productionStats!.productsCreatedToday.toString(),
                                            change: '+12%',
                                            isPositive: true,
                                            icon: Icons.inventory_2,
                                            color: AppTheme.primaryGreen,
                                            animationDelay: const Duration(milliseconds: 100),
                                          ),
                                        ),
                                        SizedBox(width: spacing),
                                        Expanded(
                                          child: MetricCard(
                                            title: 'Active Processes',
                                            value: '3', // Mock data
                                            change: '+8%',
                                            isPositive: true,
                                            icon: Icons.settings,
                                            color: AppTheme.secondaryBlue,
                                            animationDelay: const Duration(milliseconds: 200),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: spacing),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: MetricCard(
                                            title: 'Throughput/Day',
                                            value: _productionStats!.processingThroughputPerDay.toStringAsFixed(1),
                                            change: '+15%',
                                            isPositive: true,
                                            icon: Icons.trending_up,
                                            color: AppTheme.accentOrange,
                                            animationDelay: const Duration(milliseconds: 300),
                                          ),
                                        ),
                                        SizedBox(width: spacing),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Enhanced Yield Trends Section
                      DashboardSection(
                        title: 'Processing Yield Trends',
                        children: [
                          EnhancedYieldTrendsChart(
                            title: 'Processing Performance Analytics',
                            animationDelay: const Duration(milliseconds: 500),
                            showPeriodSelector: true,
                            showMetricSelector: true,
                            fixedRole: 'ProcessingUnit',
                            onRefresh: _refreshData,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Processing Pipeline Section
                      DashboardSection(
                        title: 'Real-Time Processing Pipeline',
                        children: [
                          RealTimeProgressPipeline(
                            title: 'Current Processing Status',
                            onRefresh: _refreshData,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Processing Orders Section
                      if (_orders.isNotEmpty) ...[
                        DashboardSection(
                          title: 'Processing Orders',
                          children: [
                            _buildOrdersList(),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Quick Actions Row
                      DashboardSection(
                        title: 'Quick Actions',
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = Responsive.getGridCrossAxisCount(context);
                              final spacing = Responsive.isMobile(context) ? 12.0 : 16.0;
                              final availableWidth = constraints.maxWidth;
                              final cardWidth = (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
                              
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  SizedBox(
                                    width: cardWidth,
                                    child: InteractiveDashboardCard(
                                      title: 'Create Product',
                                      value: 'New Batch',
                                      icon: Icons.add_business,
                                      color: AppTheme.primaryGreen,
                                      onTap: () => context.go('/create-product'),
                                      animationDelay: const Duration(milliseconds: 900),
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: InteractiveDashboardCard(
                                      title: 'Receive Animals',
                                      value: 'Incoming',
                                      icon: Icons.inventory,
                                      color: AppTheme.secondaryBlue,
                                      onTap: () => context.go('/receive-animals'),
                                      animationDelay: const Duration(milliseconds: 1000),
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: InteractiveDashboardCard(
                                      title: 'View QR Codes',
                                      value: 'Generated',
                                      icon: Icons.qr_code,
                                      color: AppTheme.primaryGreen,
                                      onTap: () => context.go('/processor-qr-codes'),
                                      animationDelay: const Duration(milliseconds: 1150),
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: InteractiveDashboardCard(
                                      title: 'Quality Score',
                                      value: '95%',
                                      icon: Icons.verified,
                                      color: AppTheme.successGreen,
                                      onTap: () => context.go('/quality-reports'),
                                      animationDelay: const Duration(milliseconds: 1200),
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: InteractiveDashboardCard(
                                      title: 'Producer Inventory',
                                      value: 'Manage Products',
                                      icon: Icons.inventory_2,
                                      color: AppTheme.secondaryBlue,
                                      onTap: () => context.go('/producer-inventory'),
                                      animationDelay: const Duration(milliseconds: 1300),
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: InteractiveDashboardCard(
                                      title: 'Create Product Category',
                                      value: 'Manage',
                                      icon: Icons.category,
                                      color: AppTheme.accentOrange,
                                      onTap: () => context.go('/product-categories'),
                                      animationDelay: const Duration(milliseconds: 1400),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Custom Processor Dashboard FAB
          floatingActionButton: const ProcessorDashboardFAB(),
        ),
      ),
    );
  }
}
