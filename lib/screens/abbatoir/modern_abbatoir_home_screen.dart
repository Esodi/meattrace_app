import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/animal_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/livestock/animal_card.dart';
import '../../widgets/livestock/activity_timeline.dart';
import '../../widgets/notification/notification_badge.dart';
import '../common/sync_status_screen.dart';

/// Modern Abbatoir Dashboard with Material Design 3
/// Features: Stats overview, recent animals, quick actions, activity timeline
class ModernAbbatoirHomeScreen extends StatefulWidget {
  const ModernAbbatoirHomeScreen({super.key});

  @override
  State<ModernAbbatoirHomeScreen> createState() =>
      _ModernAbbatoirHomeScreenState();
}

class _ModernAbbatoirHomeScreenState extends State<ModernAbbatoirHomeScreen>
    with TickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _transferredCount = 0;
  bool _isLoadingTransferred = false;
  Timer? _autoRefreshTimer;
  bool _isDataLoading = false;
  bool _hasInitialLoaded = false;

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
      _startAutoRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      debugPrint('🔄 App resumed - refreshing Abbatoir Dashboard');
      _loadData();
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      // Pause auto-refresh when app is in background
      debugPrint('⏸️ App paused - stopping auto-refresh');
      _autoRefreshTimer?.cancel();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only trigger initial load once
    if (!_hasInitialLoaded) {
      _hasInitialLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadData();
        }
      });
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
      if (mounted) {
        debugPrint('🔄 Auto-refreshing Abbatoir Dashboard data...');
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (_isDataLoading) return;
    _isDataLoading = true;
    debugPrint(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );
    debugPrint('🏠 ABBATOIR_DASHBOARD - LOAD_DATA START');
    debugPrint('   Time: ${DateTime.now()}');
    debugPrint('   Widget mounted: $mounted');
    debugPrint('   Context: ${context.hashCode}');
    debugPrint(
      '   Called from: ${StackTrace.current.toString().split('\n').take(3).join('\n')}',
    );
    debugPrint(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );

    try {
      debugPrint('🔍 Attempting to get AnimalProvider...');
      final animalProvider = Provider.of<AnimalProvider>(
        context,
        listen: false,
      );
      debugPrint('✅ AnimalProvider obtained successfully');

      debugPrint('📊 Provider state BEFORE fetch:');
      debugPrint(
        '   - animalProvider.animals.length: ${animalProvider.animals.length}',
      );
      debugPrint('   - animalProvider.isLoading: ${animalProvider.isLoading}');
      debugPrint('   - animalProvider.error: ${animalProvider.error}');

      // Try to get ActivityProvider, but don't fail if it's not available
      ActivityProvider? activityProvider;
      try {
        debugPrint('🔍 Attempting to get ActivityProvider...');
        activityProvider = Provider.of<ActivityProvider>(
          context,
          listen: false,
        );
        debugPrint('✅ ActivityProvider obtained successfully');
        debugPrint(
          '   - activityProvider.activities.length: ${activityProvider.activities.length}',
        );
        debugPrint('   - activityProvider.isLoading: ${activityProvider.isLoading}');
        debugPrint('   - activityProvider instance: ${activityProvider.hashCode}');
      } catch (e, stack) {
        debugPrint('❌ ActivityProvider access FAILED!');
        debugPrint('   Error: $e');
        debugPrint('   Type: ${e.runtimeType}');
        debugPrint('   Stack: ${stack.toString().split('\n').take(10).join('\n')}');
      }

      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );

      debugPrint(
        '📡 Starting parallel fetch of animals, activities, and dashboard...',
      );
      try {
        final apiService = ApiService();
        final futures = <Future>[
          animalProvider.fetchAnimals(
            slaughtered: null,
          ), // Fetch ALL animals (active + slaughtered)
          apiService.fetchDashboard(), // Fetch dashboard data
        ];

        // Only fetch activities if provider is available
        if (activityProvider != null) {
          futures.add(activityProvider.fetchActivities());
          futures.add(apiService.fetchActivities()); // Fetch activity data
        }

        await Future.wait(futures);

        debugPrint(
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        );
        debugPrint('✅ FETCH COMPLETE');
        debugPrint(
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        );
        debugPrint('📊 Provider state AFTER fetch:');
        debugPrint(
          '   - animalProvider.animals.length: ${animalProvider.animals.length}',
        );
        debugPrint('   - animalProvider.isLoading: ${animalProvider.isLoading}');
        debugPrint('   - animalProvider.error: ${animalProvider.error}');
        if (activityProvider != null) {
          debugPrint(
            '   - activityProvider.activities.length: ${activityProvider.activities.length}',
          );
        }
        debugPrint(
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        );
      } catch (e, stackTrace) {
        debugPrint('❌ ERROR in parallel fetch: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }

      debugPrint('🔄 Loading transferred count...');
      await _loadTransferredCount();

      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('� ABBATOIR_DASHBOARD - LOAD_DATA COMPLETE');
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('📊 Final counts:');
      debugPrint('   - Total animals: ${animalProvider.animals.length}');
      debugPrint('   - Transferred count: $_transferredCount');
      if (activityProvider != null) {
        debugPrint('   - Activities: ${activityProvider.activities.length}');
      }
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL ERROR in _loadData: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    } finally {
      _isDataLoading = false;
    }
  }

  Future<void> _loadTransferredCount() async {
    if (!mounted) return;
    setState(() => _isLoadingTransferred = true);

    try {
      final animalProvider = Provider.of<AnimalProvider>(
        context,
        listen: false,
      );
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
                    AppColors.abbatoirPrimary,
                    AppColors.abbatoirPrimary.withValues(alpha: 0.8),
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
                    user?.username ?? 'Abbatoir',
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
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return NotificationBadge(
                count: notificationProvider.unreadCount,
                showZero: false,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  color: AppColors.textPrimary,
                  onPressed: () {
                    context.push('/abbatoir/notifications');
                  },
                ),
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (!auth.isOfflineMode) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: AppTypography.caption(
                        color: AppColors.error,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync_outlined),
            tooltip: 'Sync Status',
            color: AppColors.textPrimary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SyncStatusScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            color: AppColors.textPrimary,
            onPressed: () {
              context.push('/abbatoir/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            color: AppColors.error,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Logout',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                if (context.mounted) {
                  await Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).logout();
                }
              }
            },
          ),
          const SizedBox(width: AppTheme.space8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.abbatoirPrimary,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // Welcome Header with Overview
              Consumer<AnimalProvider>(
                builder: (context, animalProvider, child) {
                  return SliverToBoxAdapter(
                    child: _buildWelcomeHeader(
                      user?.username ?? 'Abbatoir',
                      animalProvider,
                    ),
                  );
                },
              ),

              // Quick Actions
              SliverToBoxAdapter(child: _buildQuickActions()),

              // Recent Activity Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppTheme.space24),
                  child: Builder(
                    builder: (context) {
                      debugPrint(
                        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
                      );
                      debugPrint('🎯 ACTIVITY CONSUMER - BUILD START');
                      debugPrint('   Time: ${DateTime.now()}');
                      debugPrint('   Context: ${context.hashCode}');
                      debugPrint(
                        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
                      );

                      try {
                        debugPrint('🔍 Attempting Consumer<ActivityProvider>...');
                        return Consumer<ActivityProvider>(
                          builder: (context, activityProvider, child) {
                            debugPrint(
                              '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
                            );
                            debugPrint('🎨 ACTIVITY CONSUMER - BUILDER CALLED');
                            debugPrint(
                              '   Provider instance: ${activityProvider.hashCode}',
                            );
                            debugPrint(
                              '   isLoading: ${activityProvider.isLoading}',
                            );
                            debugPrint(
                              '   activities.length: ${activityProvider.activities.length}',
                            );
                            debugPrint('   error: ${activityProvider.error}');
                            debugPrint(
                              '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
                            );

                            if (activityProvider.isLoading &&
                                activityProvider.activities.isEmpty) {
                              debugPrint(
                                '⏭️ Skipping render - provider is loading with no activities',
                              );
                              return const SizedBox.shrink();
                            }

                            debugPrint(
                              '✅ Rendering ActivityTimeline with ${activityProvider.getRecentActivities(limit: 5).length} activities',
                            );
                            return ActivityTimeline(
                              activities: activityProvider.getRecentActivities(
                                limit: 5,
                              ),
                              onViewAll: () {
                                // TODO: Navigate to full activity history
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Activity history coming soon!',
                                    ),
                                  ),
                                );
                                }
                              },
                            );
                          },
                        );
                      } catch (e, stack) {
                        debugPrint(
                          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
                        );
                        debugPrint('❌ ACTIVITY CONSUMER - EXCEPTION CAUGHT!');
                        debugPrint('   Error: $e');
                        debugPrint('   Type: ${e.runtimeType}');
                        debugPrint('   Stack trace:');
                        debugPrint(stack.toString().split('\n').take(15).join('\n'));
                        debugPrint(
                          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
                        );
                        return const SizedBox.shrink();
                      }
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
                        onPressed: () =>
                            context.push('/abbatoir/livestock-history'),
                        child: Text(
                          'View All',
                          style: AppTypography.button().copyWith(
                            color: AppColors.abbatoirPrimary,
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
                  debugPrint(
                    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
                  );
                  debugPrint('� UI CONSUMER - REBUILDING');
                  debugPrint(
                    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
                  );
                  debugPrint('📊 Current provider state:');
                  debugPrint('   - isLoading: ${animalProvider.isLoading}');
                  debugPrint(
                    '   - animals.length: ${animalProvider.animals.length}',
                  );
                  debugPrint('   - error: ${animalProvider.error}');
                  debugPrint(
                    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
                  );

                  if (animalProvider.isLoading &&
                      animalProvider.animals.isEmpty) {
                    debugPrint('⏳ Showing loading indicator (no cached data)');
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.abbatoirPrimary,
                        ),
                      ),
                    );
                  }

                  final recentAnimals = animalProvider.animals.take(5).toList();
                  debugPrint(
                    '📋 Recent animals to display: ${recentAnimals.length}',
                  );
                  if (recentAnimals.isNotEmpty) {
                    debugPrint('📝 First few animals:');
                    for (var i = 0; i < recentAnimals.length && i < 3; i++) {
                      final a = recentAnimals[i];
                      debugPrint(
                        '   [$i] ${a.animalId} - ${a.species} (ID: ${a.id})',
                      );
                    }
                  }

                  if (recentAnimals.isEmpty) {
                    debugPrint('📭 No animals - showing empty state');
                    return SliverToBoxAdapter(child: _buildEmptyState());
                  }

                  debugPrint('✅ Rendering ${recentAnimals.length} animal cards');
                  debugPrint(
                    '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
                  );

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space16,
                      0,
                      AppTheme.space16,
                      AppTheme.space24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index >= recentAnimals.length) {
                          return const SizedBox.shrink();
                        }
                        final animal = recentAnimals[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.space12,
                          ),
                          child: CompactAnimalCard(
                            animalId: animal.animalId,
                            tagNumber: animal.animalName,
                            species: animal.species,
                            healthStatus: animal.computedLifecycleStatus.name,
                            isExternal: animal.isExternal,
                            onTap: () {
                              // Navigate to animal details
                              if (animal.id != null) {
                                context.push('/animals/${animal.id}');
                              }
                            },
                          ),
                        );
                      }, childCount: recentAnimals.length),
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

  Widget _buildWelcomeHeader(String username, AnimalProvider animalProvider) {
    final totalAnimals = animalProvider.animals.length;
    final activeAnimals = animalProvider.animals
        .where((a) => !a.slaughtered && a.transferredTo == null)
        .length;
    final processedAnimals = animalProvider.animals
        .where((a) => a.slaughtered)
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
            80.0,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.abbatoirPrimary, AppColors.abbatoirDark],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.abbatoirPrimary.withValues(alpha: 0.3),
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
                      Icons.account_circle_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),
              Text(
                'Abbatoir Overview',
                style: AppTypography.titleLarge().copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                'You have $activeAnimals active animals today.',
                style: AppTypography.bodySmall().copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
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
                  'Total',
                  totalAnimals.toString(),
                  Icons.pets_outlined,
                  AppColors.abbatoirPrimary,
                ),
                _buildStatDivider(),
                _buildModernStatItem(
                  'Active',
                  activeAnimals.toString(),
                  Icons.eco_outlined,
                  AppColors.success,
                ),
                _buildStatDivider(),
                _buildModernStatItem(
                  'Processed',
                  processedAnimals.toString(),
                  Icons.check_circle_outline,
                  AppColors.secondaryBlue,
                ),
                _buildStatDivider(),
                _buildModernStatItem(
                  'Transferred',
                  _isLoadingTransferred ? '...' : _transferredCount.toString(),
                  Icons.local_shipping_outlined,
                  AppColors.accentOrange,
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

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: CustomIcons.cattle,
        label: 'Register',
        color: AppColors.abbatoirPrimary,
        route: '/register-animal',
      ),
      _QuickAction(
        icon: CustomIcons.slaughter,
        label: 'Slaughter',
        color: AppColors.error,
        route: '/slaughter-animal',
      ),
      _QuickAction(
        icon: CustomIcons.transfer,
        label: 'Transfer',
        color: AppColors.processorPrimary,
        route: '/select-animals-transfer',
      ),
      _QuickAction(
        icon: Icons.inventory_2_outlined,
        label: 'Inventory',
        color: AppColors.success,
        route: '/abbatoir/inventory',
      ),
      _QuickAction(
        icon: Icons.history,
        label: 'History',
        color: AppColors.info,
        route: '/abbatoir/livestock-history',
      ),
      _QuickAction(
        icon: Icons.business_center,
        label: 'Vendors',
        color: AppColors.secondaryBlue,
        route: '/external-vendors',
      ),
      _QuickAction(
        icon: Icons.add_home_work,
        label: 'Stock',
        color: AppColors.abbatoirPrimary,
        route: '/abbatoir/stock',
      ),
      _QuickAction(
        icon: Icons.delete_sweep_outlined,
        label: 'Waste',
        color: AppColors.error,
        route: '/waste-list',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space32,
        AppTheme.space16,
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
                  color: AppColors.abbatoirPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Operations',
                  style: AppTypography.labelSmall().copyWith(
                    color: AppColors.abbatoirPrimary,
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
                  childAspectRatio: 0.85,
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  action.label,
                  style: AppTypography.labelMedium().copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
        icon: Icons.pets,
        message: 'No Animals Yet',
        subtitle:
            'Start by registering your first animal to begin tracking your livestock.',
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
