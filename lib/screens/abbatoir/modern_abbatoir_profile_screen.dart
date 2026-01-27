import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/animal_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_button.dart';
import '../../models/activity.dart';
import 'package:intl/intl.dart';

class ModernAbbatoirProfileScreen extends StatefulWidget {
  const ModernAbbatoirProfileScreen({super.key});

  @override
  State<ModernAbbatoirProfileScreen> createState() =>
      _ModernAbbatoirProfileScreenState();
}

class _ModernAbbatoirProfileScreenState
    extends State<ModernAbbatoirProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isEditing = false;
  final ScrollController _scrollController = ScrollController();

  // Profile data
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _abbatoirNameController = TextEditingController();
  final _locationController = TextEditingController();

  // Statistics
  int _totalAnimals = 0;
  int _activeAnimals = 0;
  int _slaughteredAnimals = 0;
  int _transferredAnimals = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Add microtask to prevent build errors during initial load
    Future.microtask(() {
      _loadProfileData();
      _loadStatistics();
      _loadRecentActivities();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _abbatoirNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      // Only wrapping necessary logic in try-catch
      final data = await apiService.fetchProfile();

      if (mounted) {
        setState(() {
          _firstNameController.text = data['first_name'] ?? '';
          _lastNameController.text = data['last_name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _abbatoirNameController.text = data['organization'] ?? '';
          _locationController.text = data['location'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStatistics() async {
    if (!mounted) return;
    try {
      final animalProvider = Provider.of<AnimalProvider>(
        context,
        listen: false,
      );
      // Ensure we don't trigger unnecessary rebuilds or loops
      await animalProvider.fetchAnimals(slaughtered: null);

      if (mounted) {
        setState(() {
          _totalAnimals = animalProvider.animals.length;
          _activeAnimals = animalProvider.animals
              .where((a) => !a.slaughtered && a.transferredTo == null)
              .length;
          _slaughteredAnimals = animalProvider.animals
              .where((a) => a.slaughtered)
              .length;
          _transferredAnimals = animalProvider.animals
              .where((a) => a.transferredTo != null)
              .length;
        });
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  Future<void> _loadRecentActivities() async {
    if (!mounted) return;
    try {
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );
      await activityProvider.fetchActivities();
    } catch (e) {
      debugPrint('Error loading activities: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      await apiService.updateProfile({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'organization': _abbatoirNameController.text.trim(),
        'location': _locationController.text.trim(),
      });

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.user;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.abbatoirPrimary,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient Background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.abbatoirPrimary,
                            AppColors.abbatoirDark,
                          ],
                        ),
                      ),
                    ),
                    // Pattern Overlay (Optional)
                    Opacity(
                      opacity: 0.1,
                      child: CustomPaint(painter: GridPainter()),
                    ),
                    // Content
                    Positioned(
                      bottom:
                          60, // Leave space for TabBar or heavy bottom padding
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Text(
                                _getInitials(user?.username ?? 'U'),
                                style: AppTypography.headlineLarge().copyWith(
                                  color: AppColors.abbatoirPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space12),
                          Text(
                            user?.username ?? 'Abbatoir User',
                            style: AppTypography.headlineMedium().copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: AppTypography.bodySmall().copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.white,
                    onPressed: () => setState(() => _isEditing = true),
                    tooltip: 'Edit Profile',
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.check),
                    color: Colors.white,
                    onPressed: _updateProfile,
                    tooltip: 'Save Changes',
                  ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  color: Colors.white,
                  onPressed: () => context.push('/abbatoir/settings'),
                  tooltip: 'Settings',
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.abbatoirPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.abbatoirPrimary,
                  indicatorWeight: 3,
                  labelStyle: AppTypography.labelLarge(),
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Statistics'),
                    Tab(text: 'Activity'),
                  ],
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
              pinned: true,
            ),
          ];
        },
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.abbatoirPrimary,
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(isDark),
                  _buildStatisticsTab(isDark),
                  _buildActivityTab(isDark),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Form(
        key: _formKey,
        child: AnimationLimiter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                _buildSectionTitle('Personal Information'),
                const SizedBox(height: AppTheme.space16),
                _buildModernTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                  enabled: _isEditing,
                ),
                const SizedBox(height: AppTheme.space16),
                _buildModernTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                  enabled: _isEditing,
                ),
                const SizedBox(height: AppTheme.space16),
                _buildModernTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  enabled: _isEditing,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.space16),
                _buildModernTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppTheme.space32),
                _buildSectionTitle('Abbatoir Information'),
                const SizedBox(height: AppTheme.space16),
                _buildModernTextField(
                  controller: _abbatoirNameController,
                  label: 'Abbatoir Name',
                  icon: Icons.agriculture_outlined,
                  enabled: _isEditing,
                ),
                const SizedBox(height: AppTheme.space16),
                _buildModernTextField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_on_outlined,
                  enabled: _isEditing,
                ),
                if (_isEditing) ...[
                  const SizedBox(height: AppTheme.space32),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Cancel',
                          variant: ButtonVariant.secondary,
                          onPressed: () {
                            setState(() => _isEditing = false);
                            _loadProfileData(); // Reset data
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.space16),
                      Expanded(
                        child: CustomButton(
                          label: 'Save Changes',
                          customColor: AppColors.abbatoirPrimary,
                          onPressed: _updateProfile,
                        ),
                      ),
                    ],
                  ),
                ],
                // Bottom padding
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: AnimationLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              _buildSectionTitle('Livestock Overview'),
              const SizedBox(height: AppTheme.space16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppTheme.space16,
                crossAxisSpacing: AppTheme.space16,
                childAspectRatio: 1.1,
                children: [
                  _buildModernStatCard(
                    title: 'Total Animals',
                    value: _totalAnimals.toString(),
                    icon: Icons.pets,
                    color: AppColors.abbatoirPrimary,
                  ),
                  _buildModernStatCard(
                    title: 'Active',
                    value: _activeAnimals.toString(),
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                  _buildModernStatCard(
                    title: 'Slaughtered',
                    value: _slaughteredAnimals.toString(),
                    icon: Icons.restaurant_menu,
                    color: AppColors.error,
                  ),
                  _buildModernStatCard(
                    title: 'Transferred',
                    value: _transferredAnimals.toString(),
                    icon: Icons.send,
                    color: AppColors.accentOrange,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space32),
              _buildSectionTitle('Quick Actions'),
              const SizedBox(height: AppTheme.space16),
              _buildQuickActionTile(
                title: 'View All Animals',
                subtitle: 'Manage livestock inventory',
                icon: Icons.list_alt,
                onTap: () => context.push('/abbatoir/livestock-history'),
              ),
              _buildQuickActionTile(
                title: 'Register New Animal',
                subtitle: 'Add new livestock to the system',
                icon: Icons.add_circle_outline,
                onTap: () => context.push('/register-animal'),
              ),
              _buildQuickActionTile(
                title: 'Transfer Animals',
                subtitle: 'Move animals to processing',
                icon: Icons.local_shipping_outlined,
                onTap: () => context.push('/select-animals-transfer'),
              ),
              // Bottom padding
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTab(bool isDark) {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        final activities = activityProvider.getRecentActivities(limit: 20);

        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 64,
                  color: AppColors.textTertiary.withOpacity(0.5),
                ),
                const SizedBox(height: AppTheme.space16),
                Text(
                  'No recent activities',
                  style: AppTypography.bodyLarge().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your recent actions will appear here',
                  style: AppTypography.bodySmall().copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await activityProvider.fetchActivities(forceRefresh: true);
          },
          color: AppColors.abbatoirPrimary,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppTheme.space16),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildModernActivityCard(activity),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleLarge().copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTypography.bodyMedium().copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled:
            true, // Only fill when enabled for better contrast? Or always light fill
        fillColor: enabled
            ? Colors.transparent
            : AppColors.backgroundGray.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: AppColors.abbatoirPrimary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: AppColors.divider.withOpacity(0.5)),
        ),
        labelStyle: AppTypography.bodyMedium().copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTypography.headlineMedium().copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.bodySmall().copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: AppColors.divider.withOpacity(0.5)),
      ),
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.abbatoirPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.abbatoirPrimary, size: 24),
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium()),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernActivityCard(Activity activity) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: _getActivityColor(activity.type),
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: AppTypography.titleSmall().copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (activity.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    activity.description!,
                    style: AppTypography.bodySmall().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(activity.timestamp),
                  style: AppTypography.labelSmall().copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('MMM d, y • h:mm a').format(dt);
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.registration:
        return Icons.add_circle_outline;
      case ActivityType.transfer:
        return Icons.local_shipping_outlined;
      case ActivityType.slaughter:
        return Icons.restaurant_menu_outlined;
      case ActivityType.healthUpdate:
        return Icons.health_and_safety_outlined;
      case ActivityType.weightUpdate:
        return Icons.monitor_weight_outlined;
      case ActivityType.vaccination:
        return Icons.vaccines_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.registration:
        return AppColors.success;
      case ActivityType.transfer:
        return AppColors.accentOrange;
      case ActivityType.slaughter:
        return AppColors.error;
      case ActivityType.healthUpdate:
        return AppColors.info;
      case ActivityType.weightUpdate:
        return AppColors.secondaryBlue;
      case ActivityType.vaccination:
        return AppColors.secondaryBlue; // fallback for purple
      default:
        return AppColors.textSecondary;
    }
  }
}

// Minimal Grid Painter for background texture
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    const double spacing = 20.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, {required this.backgroundColor});

  final TabBar _tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
