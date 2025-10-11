import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:async/async.dart';
import '../providers/auth_provider.dart';
import '../providers/animal_provider.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';
import '../widgets/interactive_dashboard_card.dart';
import '../widgets/data_visualization_widgets.dart';
import '../widgets/enhanced_yield_trends_chart.dart';
import '../widgets/custom_dashboard_fabs.dart';
import '../widgets/responsive_dashboard_layout.dart';
import '../widgets/theme_toggle.dart';
import 'package:flutter/services.dart';
import '../services/weather_service.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> with WidgetsBindingObserver {
  late AnimalProvider _animalProvider;
  int _transferredCount = 0;
  bool _isLoadingTransferred = false;
  WeatherData? _weatherData;
  bool _isWeatherLoading = true;
  CancelableOperation? _weatherOperation;
  CancelableOperation? _transferredOperation;

  @override
  void initState() {
    super.initState();
    _animalProvider = Provider.of<AnimalProvider>(context, listen: false);
    // Delay fetchAnimals until after the build is complete to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animalProvider.fetchAnimals();
      _loadTransferredCount();
      _loadWeatherData();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _weatherOperation?.cancel();
    _transferredOperation?.cancel();
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
    await _loadWeatherData();
  }

  Future<void> _loadTransferredCount() async {
    if (!mounted) return;
    setState(() => _isLoadingTransferred = true);
    _transferredOperation = CancelableOperation.fromFuture(
      _animalProvider.getTransferredAnimalsCount(),
      onCancel: () {
        if (mounted) setState(() => _isLoadingTransferred = false);
      },
    );

    try {
      final transferredAnimals = await _transferredOperation!.value;
      if (mounted) setState(() => _transferredCount = transferredAnimals);
    } catch (e) {
      if (!mounted) return;
      // Keep current count on error
    } finally {
      if (mounted) setState(() => _isLoadingTransferred = false);
    }
  }

  Future<void> _loadWeatherData() async {
    if (!mounted) return;
    setState(() => _isWeatherLoading = true);
    _weatherOperation = CancelableOperation.fromFuture(
      WeatherService().getWeatherData(),
      onCancel: () {
        if (mounted) setState(() => _isWeatherLoading = false);
      },
    );

    try {
      _weatherData = await _weatherOperation!.value;
    } catch (e) {
      if (!mounted) return;
      // Keep default
    } finally {
      if (mounted) setState(() => _isWeatherLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building FarmerHomeScreen');
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return ResponsiveDashboardLayout(
      currentRoute: '/farmer-home',
      content: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, _) async {
          if (!didPop) {
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
              SystemNavigator.pop();
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('FarmHub Dashboard'),
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
                        title: 'Welcome back, ${user?.username ?? 'Farmer'}!',
                        value: 'Farm Overview',
                        icon: Icons.waving_hand,
                        color: AppTheme.primaryGreen,
                        subtitle: 'Monitor your livestock and farm operations',
                        animationDelay: Duration.zero,
                      ),
                      SizedBox(height: Responsive.getPadding(context) * 1.5),

                      // Quick Stats Row
                      DashboardSection(
                        title: 'Key Metrics',
                        children: [
                          Consumer<AnimalProvider>(
                            builder: (context, animalProvider, child) {
                              final totalAnimals = animalProvider.animals.length;
                              final activeAnimals = animalProvider.animals.where((a) => !a.slaughtered).length;
                              final slaughtered = animalProvider.animals.where((a) => a.slaughtered).length;

                              final metricCards = [
                                MetricCard(
                                  title: 'Total Livestock',
                                  value: totalAnimals.toString(),
                                  change: '+12%',
                                  isPositive: true,
                                  icon: Icons.pets,
                                  color: AppTheme.primaryGreen,
                                  animationDelay: const Duration(milliseconds: 100),
                                ),
                                MetricCard(
                                  title: 'Active Animals',
                                  value: activeAnimals.toString(),
                                  change: '+8%',
                                  isPositive: true,
                                  icon: Icons.grass,
                                  color: AppTheme.secondaryBlue,
                                  animationDelay: const Duration(milliseconds: 200),
                                ),
                                MetricCard(
                                  title: 'Processed',
                                  value: slaughtered.toString(),
                                  change: '+15%',
                                  isPositive: true,
                                  icon: Icons.restaurant,
                                  color: AppTheme.accentOrange,
                                  animationDelay: const Duration(milliseconds: 300),
                                ),
                                InteractiveDashboardCard(
                                  title: 'Transferred',
                                  value: _isLoadingTransferred ? '...' : _transferredCount.toString(),
                                  icon: Icons.send,
                                  color: AppTheme.secondaryBurgundy,
                                  onTap: () => context.go('/transferred-animals'),
                                  animationDelay: const Duration(milliseconds: 400),
                                ),
                              ];

                              final crossAxisCount = Responsive.getGridCrossAxisCount(context);
                              final spacing = Responsive.getPadding(context);

                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: spacing,
                                crossAxisSpacing: spacing,
                                children: metricCards,
                              );
                            },
                          ),
                        ],
                      ),

                      SizedBox(height: Responsive.getPadding(context) * 2),

                      // Enhanced Yield Trends Section
                      DashboardSection(
                        title: 'Yield Trends & Analytics',
                        children: [
                          EnhancedYieldTrendsChart(
                            title: 'Farm Performance Trends',
                            animationDelay: const Duration(milliseconds: 500),
                            showPeriodSelector: true,
                            showMetricSelector: true,
                            fixedRole: 'Farmer',
                            onRefresh: _refreshData,
                          ),
                        ],
                      ),

                      SizedBox(height: Responsive.getPadding(context) * 2),

                      // Weather & Progress Section
                      DashboardSection(
                        title: 'Farm Conditions',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: WeatherWidget(
                                  temperature: _isWeatherLoading ? '...' : '${_weatherData?.temperature.toStringAsFixed(0) ?? '28'}°C',
                                  condition: _weatherData?.condition ?? 'Sunny',
                                  weatherIcon: Icons.wb_sunny,
                                  location: _weatherData?.location ?? 'Farm Location',
                                  animationDelay: const Duration(milliseconds: 700),
                                ),
                              ),
                              SizedBox(width: Responsive.getPadding(context)),
                              Expanded(
                                child: ProgressIndicatorCard(
                                  title: 'Soil Moisture',
                                  progress: (_weatherData?.soilMoisture ?? 75.0) / 100.0,
                                  subtitle: 'Optimal levels maintained',
                                  color: AppTheme.infoBlue,
                                  animationDelay: const Duration(milliseconds: 800),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: Responsive.getPadding(context) * 2),

                      // Quick Actions Row
                      DashboardSection(
                        title: 'Quick Actions',
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = Responsive.getGridCrossAxisCount(context);
                              final spacing = Responsive.getPadding(context);

                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: spacing,
                                crossAxisSpacing: spacing,
                                children: [
                                  InteractiveDashboardCard(
                                    title: 'Register Livestock',
                                    value: 'Add New',
                                    icon: Icons.add_circle,
                                    color: AppTheme.primaryGreen,
                                    onTap: () => context.go('/register-animal'),
                                    animationDelay: const Duration(milliseconds: 900),
                                  ),
                                  InteractiveDashboardCard(
                                    title: 'Process Livestock',
                                    value: 'Slaughter',
                                    icon: Icons.restaurant_menu,
                                    color: AppTheme.secondaryBurgundy,
                                    onTap: () => context.go('/slaughter-animal'),
                                    animationDelay: const Duration(milliseconds: 1000),
                                  ),
                                  InteractiveDashboardCard(
                                    title: 'View History',
                                    value: 'Records',
                                    icon: Icons.history,
                                    color: AppTheme.secondaryBlue,
                                    onTap: () => context.go('/livestock-history'),
                                    animationDelay: const Duration(milliseconds: 1100),
                                  ),
                                  InteractiveDashboardCard(
                                    title: 'Transfer Animals',
                                    value: 'Move',
                                    icon: Icons.send,
                                    color: AppTheme.accentOrange,
                                    onTap: () => context.go('/select-animals-transfer'),
                                    animationDelay: const Duration(milliseconds: 1200),
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

          // Custom Farmer Dashboard FAB
          floatingActionButton: const FarmerDashboardFAB(),
        ),
      ),
    );
  }


}







