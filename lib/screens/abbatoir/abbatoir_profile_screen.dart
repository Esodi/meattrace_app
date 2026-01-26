import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/animal_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../utils/responsive.dart';
import '../../models/activity.dart';
import 'package:intl/intl.dart';

/// Abbatoir Profile Screen
/// Features: User profile, statistics, recent activities, settings
class AbbatoirProfileScreen extends StatefulWidget {
  const AbbatoirProfileScreen({super.key});

  @override
  State<AbbatoirProfileScreen> createState() => _AbbatoirProfileScreenState();
}

class _AbbatoirProfileScreenState extends State<AbbatoirProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isEditing = false;

  // Profile data
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _farmNameController = TextEditingController();
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
    _loadProfileData();
    _loadStatistics();
    _loadRecentActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _farmNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final data = await apiService.fetchProfile();

      if (mounted) {
        setState(() {
          _firstNameController.text = data['first_name'] ?? '';
          _lastNameController.text = data['last_name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _farmNameController.text = data['organization'] ?? '';
          _locationController.text = data['location'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final animalProvider = Provider.of<AnimalProvider>(
        context,
        listen: false,
      );
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      await apiService.updateProfile({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'organization': _farmNameController.text.trim(),
        'location': _locationController.text.trim(),
      });

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
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
      backgroundColor: isDark
          ? const Color(0xFF1A1A1A)
          : AppTheme.backgroundGray,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryRed,
                        AppTheme.primaryRed.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Hero(
                          tag: 'profile_avatar',
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(user?.username ?? 'F'),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryRed,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.username ?? 'Abbatoir',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black45,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => setState(() => _isEditing = true),
                    tooltip: 'Edit Profile',
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _updateProfile,
                    tooltip: 'Save Changes',
                  ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/abbatoir/settings'),
                  tooltip: 'Settings',
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: isDark
                      ? AppTheme.primaryRed
                      : AppTheme.primaryRed,
                  unselectedLabelColor: isDark
                      ? Colors.white.withOpacity(0.6)
                      : Colors.black54,
                  indicatorColor: AppTheme.primaryRed,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
                    Tab(
                      icon: Icon(Icons.bar_chart_outlined),
                      text: 'Statistics',
                    ),
                    Tab(icon: Icon(Icons.history_outlined), text: 'Activity'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
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
      padding: EdgeInsets.all(Responsive.getPadding(context)),
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
                _buildSectionTitle('Personal Information', isDark),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                  enabled: _isEditing,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                  enabled: _isEditing,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  enabled: _isEditing,
                  isDark: isDark,
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
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  enabled: _isEditing,
                  isDark: isDark,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Abbatoir Information', isDark),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _farmNameController,
                  label: 'Abbatoir Name',
                  icon: Icons.agriculture_outlined,
                  enabled: _isEditing,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_on_outlined,
                  enabled: _isEditing,
                  isDark: isDark,
                ),
                const SizedBox(height: 32),
                if (_isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _isEditing = false);
                            _loadProfileData();
                          },
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _updateProfile,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsTab(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.getPadding(context)),
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
              _buildSectionTitle('Livestock Overview', isDark),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    title: 'Total Animals',
                    value: _totalAnimals.toString(),
                    icon: Icons.pets,
                    color: AppTheme.primaryGreen,
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    title: 'Active',
                    value: _activeAnimals.toString(),
                    icon: Icons.check_circle_outline,
                    color: AppTheme.successGreen,
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    title: 'Slaughtered',
                    value: _slaughteredAnimals.toString(),
                    icon: Icons.restaurant_menu,
                    color: AppTheme.secondaryBurgundy,
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    title: 'Transferred',
                    value: _transferredAnimals.toString(),
                    icon: Icons.send,
                    color: AppTheme.accentOrange,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Quick Actions', isDark),
              const SizedBox(height: 16),
              _buildQuickActionButton(
                title: 'View All Animals',
                icon: Icons.list_alt,
                onTap: () => context.go('/abbatoir/livestock-history'),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildQuickActionButton(
                title: 'Register New Animal',
                icon: Icons.add_circle_outline,
                onTap: () => context.go('/register-animal'),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildQuickActionButton(
                title: 'Transfer Animals',
                icon: Icons.send_outlined,
                onTap: () => context.go('/select-animals-transfer'),
                isDark: isDark,
              ),
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
                  size: 80,
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black26,
                ),
                const SizedBox(height: 16),
                Text(
                  'No recent activities',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black45,
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
          child: ListView.builder(
            padding: EdgeInsets.all(Responsive.getPadding(context)),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildActivityCard(activity, isDark),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: enabled
            ? (isDark ? const Color(0xFF2D2D2D) : Colors.white)
            : (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : AppTheme.dividerGray,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : AppTheme.dividerGray,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryRed, width: 2),
        ),
        labelStyle: TextStyle(
          color: isDark
              ? Colors.white.withOpacity(0.7)
              : AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isDark
                ? Border.all(color: Colors.white.withOpacity(0.1))
                : null,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryRed, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Activity activity, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                if (activity.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    activity.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(activity.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : AppTheme.textSecondary.withOpacity(0.7),
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
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.registration:
        return Icons.add_circle_outline;
      case ActivityType.transfer:
        return Icons.send_outlined;
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
        return AppTheme.primaryGreen;
      case ActivityType.transfer:
        return AppTheme.accentOrange;
      case ActivityType.slaughter:
        return AppTheme.secondaryBurgundy;
      case ActivityType.healthUpdate:
        return AppTheme.infoBlue;
      case ActivityType.weightUpdate:
        return AppTheme.secondaryBlue;
      case ActivityType.vaccination:
        return AppTheme.successGreen;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
