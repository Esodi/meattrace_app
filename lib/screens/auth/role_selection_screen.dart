import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart' as custom_icons;

/// MeatTrace Pro - Role Selection Screen
/// Allows users to choose their role before signup

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> with TickerProviderStateMixin {
  String? _selectedRole;
  late AnimationController _animationController;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;

  final List<RoleData> _roles = [
    RoleData(
      id: 'farmer',
      title: 'Farmer',
      description: 'Register and manage livestock, track animal health, and transfer to processors',
      icon: custom_icons.CustomIcons.cattle,
      color: AppColors.farmerPrimary,
      features: [
        'Register animals with QR codes',
        'Track animal health status',
        'Transfer animals to processors',
        'View complete animal history',
      ],
    ),
    RoleData(
      id: 'processing_unit',
      title: 'Processing Unit',
      description: 'Receive animals, process meat products, and manage quality certifications',
      icon: custom_icons.CustomIcons.processingPlant,
      color: AppColors.processorPrimary,
      features: [
        'Receive and process animals',
        'Create meat products',
        'Manage quality grades',
        'Transfer to retail shops',
      ],
    ),
    RoleData(
      id: 'shop',
      title: 'Retail Shop',
      description: 'Receive products, manage inventory, and provide product traceability to customers',
      icon: custom_icons.CustomIcons.shop,
      color: AppColors.shopPrimary,
      features: [
        'Receive meat products',
        'Manage shop inventory',
        'Generate customer QR codes',
        'Track product origins',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardControllers = List.generate(
      _roles.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );

    _cardAnimations = _cardControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    _animationController.forward();
    
    // Stagger card animations
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _cardControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectRole(String roleId) {
    setState(() {
      _selectedRole = roleId;
    });
  }

  void _continue() {
    if (_selectedRole != null) {
      // Navigate to appropriate signup screen based on role
      switch (_selectedRole) {
        case 'farmer':
          context.go('/signup?role=farmer');
          break;
        case 'processing_unit':
          context.go('/signup-processing-unit');
          break;
        case 'shop':
          context.go('/signup-shop');
          break;
        default:
          context.go('/signup?role=$_selectedRole');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.darkBackground,
                    AppColors.darkSurface,
                  ]
                : [
                    Colors.white,
                    AppColors.backgroundGray,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/login'),
                    ),
                    Expanded(
                      child: Text(
                        'Choose Your Role',
                        style: AppTypography.headlineSmall(
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
                child: Text(
                  'Select the role that best describes your business',
                  style: AppTypography.bodyMedium(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppTheme.space32),

              // Role Cards
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    return FadeTransition(
                      opacity: _cardAnimations[index],
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_cardAnimations[index]),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.space16),
                          child: _buildRoleCard(_roles[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Continue Button
              Container(
                padding: EdgeInsets.only(
                  left: AppTheme.space24,
                  right: AppTheme.space24,
                  bottom: MediaQuery.of(context).padding.bottom + AppTheme.space16,
                  top: AppTheme.space16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedRole != null ? _continue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      elevation: _selectedRole != null ? 2 : 0,
                    ),
                    child: Text(
                      'Continue',
                      style: AppTypography.labelLarge(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(RoleData role) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedRole == role.id;

    return GestureDetector(
      onTap: () => _selectRole(role.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected
                ? role.color
                : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: role.color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: role.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Icon(
                      role.icon,
                      size: 32,
                      color: role.color,
                    ),
                  ),
                  
                  const SizedBox(width: AppTheme.space16),
                  
                  // Title and Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.title,
                          style: AppTypography.titleLarge(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          role.description,
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Selection Indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? role.color : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? role.color
                            : (isDark ? AppColors.darkDivider : AppColors.divider),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.space16),
              
              // Features List
              ...role.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: role.color.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(
                      child: Text(
                        feature,
                        style: AppTypography.bodySmall(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleData {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;

  const RoleData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
  });
}
