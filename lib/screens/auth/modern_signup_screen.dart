import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_notification_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_text_field.dart';

/// Modern signup screen with role-specific forms
/// Supports three roles: Abbatoir, Processing Unit, Shop
/// Features: Multi-step wizard, role-specific fields, validation, animations
class ModernSignupScreen extends StatefulWidget {
  final String? initialRole;

  const ModernSignupScreen({
    super.key,
    this.initialRole,
  });

  @override
  State<ModernSignupScreen> createState() => _ModernSignupScreenState();
}

class _ModernSignupScreenState extends State<ModernSignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Common fields
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Role-specific fields
  final _abbatoirNameController = TextEditingController();
  final _facilityNameController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  String _selectedRole = '';
  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? 'abbatoir';

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _abbatoirNameController.dispose();
    _facilityNameController.dispose();
    _storeNameController.dispose();
    _licenseController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Color _getRoleColor() {
    switch (_selectedRole) {
      case 'abbatoir':
        return AppColors.abbatoirPrimary;
      case 'processing_unit':
        return AppColors.processorPrimary;
      case 'shop':
        return AppColors.shopPrimary;
      default:
        return AppColors.abbatoirPrimary;
    }
  }

  String _getRoleTitle() {
    switch (_selectedRole) {
      case 'abbatoir':
        return 'Abbatoir Registration';
      case 'processing_unit':
        return 'Processing Unit Registration';
      case 'shop':
        return 'Shop Registration';
      default:
        return 'Registration';
    }
  }

  IconData _getRoleIcon() {
    switch (_selectedRole) {
      case 'abbatoir':
        return CustomIcons.cattle;
      case 'processing_unit':
        return CustomIcons.processingPlant;
      case 'shop':
        return CustomIcons.shop;
      default:
        return CustomIcons.cattle;
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() {
          _currentStep++;
        });
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _submitForm();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      AuthNotificationService.showWarning(
        context,
        'Please fill in all required fields correctly',
        title: 'Validation Error',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Show loading notification
    // AuthNotificationService.showLoading(
    //   context,
    //   'Creating your account...',
    //   title: 'Please Wait',
    // );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Build registration data based on role
      final Map<String, dynamic> userData = {
        'username': _usernameController.text,
        'password': _passwordController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'role': _selectedRole,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zip': _zipController.text,
      };

      // Add role-specific fields
      if (_selectedRole == 'abbatoir') {
        userData['abbatoir_name'] = _abbatoirNameController.text;
      } else if (_selectedRole == 'processing_unit') {
        userData['facility_name'] = _facilityNameController.text;
        userData['license_number'] = _licenseController.text;
      } else if (_selectedRole == 'shop') {
        userData['store_name'] = _storeNameController.text;
      }

      // Call signup API with backend
      // Convert lowercase role to capitalized format expected by backend
      String backendRole;
      switch (_selectedRole) {
        case 'abbatoir':
          backendRole = 'Abbatoir';
          break;
        case 'processing_unit':
          backendRole = 'ProcessingUnit';
          break;
        case 'shop':
          backendRole = 'Shop';
          break;
        default:
          backendRole = 'Abbatoir';
      }

      final success = await authProvider.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        backendRole,
      );

      // Dismiss loading notification
      if (mounted) {
        AuthNotificationService.dismissAll(context);
      }

      if (mounted) {
        if (success) {
          // Show success notification
          AuthNotificationService.showAuthSuccess(
            context,
            'register',
            customMessage: 'Your account has been created successfully! Welcome to MeatTrace Pro.',
          );

          // Small delay to show success message before navigation
          await Future.delayed(const Duration(milliseconds: 800));

          if (mounted) {
            // Navigate to role-based dashboard
            _navigateToRoleBasedHome(backendRole);
          }
        } else {
          // Show detailed error notification
          final errorMessage = authProvider.error ?? 'Registration failed. Please try again.';
          AuthNotificationService.showAuthError(context, errorMessage);
        }
      }
    } catch (e) {
      // Dismiss loading notification
      if (mounted) {
        AuthNotificationService.dismissAll(context);
        
        // Show error notification
        AuthNotificationService.showError(
          context,
          'An unexpected error occurred during registration. Please try again.',
          title: 'Registration Error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToRoleBasedHome(String role) {
    final normalizedRole = role.toLowerCase();
    debugPrint('🚀 [SIGNUP] Navigating to home for role: "$role" (normalized: "$normalizedRole")');
    
    // Handle all possible role variations
    if (normalizedRole == 'abbatoir') {
      debugPrint('   ➡️ Going to: /abbatoir-home');
      context.go('/abbatoir-home');
    } else if (normalizedRole == 'processingunit' || 
               normalizedRole == 'processing_unit' ||
               normalizedRole == 'processor') {
      debugPrint('   ➡️ Going to: /processor-home');
      context.go('/processor-home');
    } else if (normalizedRole == 'shop' || 
               normalizedRole == 'shopowner' || 
               normalizedRole == 'shop_owner') {
      debugPrint('   ➡️ Going to: /shop-home');
      context.go('/shop-home');
    } else {
      debugPrint('   ⚠️ Unknown role "$role", going to login');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getRoleColor(),
              _getRoleColor().withValues(alpha: 0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Progress indicator
                _buildProgressIndicator(),

                // Form content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: AppTheme.space16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.radiusXLarge),
                        topRight: Radius.circular(AppTheme.radiusXLarge),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1(), // Account credentials
                          _buildStep2(), // Contact information
                          _buildStep3(), // Role-specific information
                        ],
                      ),
                    ),
                  ),
                ),

                // Navigation buttons
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _currentStep > 0 ? _previousStep : () => context.go('/role-selection'),
          ),
          const SizedBox(width: AppTheme.space12),
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              _getRoleIcon(),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getRoleTitle(),
                  style: AppTypography.headlineMedium().copyWith(color: Colors.white),
                ),
                Text(
                  'Step ${_currentStep + 1} of 3',
                  style: AppTypography.bodyMedium().copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index < 2 ? AppTheme.space8 : 0,
              ),
              height: 4,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Account',
            style: AppTypography.headlineLarge(),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Choose a username and secure password',
            style: AppTypography.bodyMedium().copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.space32),
          CustomTextField(
            controller: _usernameController,
            label: 'Username',
            hint: 'Enter your username',
            prefixIcon: Icon(Icons.person_outline),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter username';
              }
              if (value.length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space16),
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: Icon(Icons.lock_outline),
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space16),
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            prefixIcon: Icon(Icons.lock_outline),
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: AppTypography.headlineLarge(),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'How can we reach you?',
            style: AppTypography.bodyMedium().copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.space32),
          CustomTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'example@email.com',
            prefixIcon: Icon(Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter email';
              }
              if (!value.contains('@')) {
                return 'Please enter valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space16),
          CustomTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '(555) 123-4567',
            prefixIcon: Icon(Icons.phone_outlined),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space16),
          CustomTextField(
            controller: _addressController,
            label: 'Street Address',
            hint: '123 Main Street',
            prefixIcon: Icon(Icons.location_on_outlined),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter address';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _cityController,
                  label: 'City',
                  hint: 'City',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: CustomTextField(
                  controller: _stateController,
                  label: 'State',
                  hint: 'ST',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: CustomTextField(
                  controller: _zipController,
                  label: 'ZIP',
                  hint: '12345',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedRole == 'abbatoir'
                ? 'Abbatoir Information'
                : _selectedRole == 'processing_unit'
                    ? 'Facility Information'
                    : 'Store Information',
            style: AppTypography.headlineLarge(),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            _selectedRole == 'abbatoir'
                ? 'Tell us about your abbatoir'
                : _selectedRole == 'processing_unit'
                    ? 'Tell us about your processing facility'
                    : 'Tell us about your shop',
            style: AppTypography.bodyMedium().copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.space32),
          if (_selectedRole == 'abbatoir') ...[
            CustomTextField(
              controller: _abbatoirNameController,
              label: 'Abbatoir Name',
              hint: 'Enter your abbatoir name',
              prefixIcon: Icon(CustomIcons.cattle),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter abbatoir name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.space16),
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppColors.abbatoirPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppColors.abbatoirPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.abbatoirPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        'Abbatoir Features',
                        style: AppTypography.titleMedium().copyWith(
                          color: AppColors.abbatoirPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                  _buildFeatureItem('Register and manage animals'),
                  _buildFeatureItem('Track animal health and medications'),
                  _buildFeatureItem('Transfer animals to processing units'),
                  _buildFeatureItem('View complete animal history'),
                ],
              ),
            ),
          ] else if (_selectedRole == 'processing_unit') ...[
            CustomTextField(
              controller: _facilityNameController,
              label: 'Facility Name',
              hint: 'Enter facility name',
              prefixIcon: Icon(CustomIcons.processingPlant),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter facility name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.space16),
            CustomTextField(
              controller: _licenseController,
              label: 'License Number',
              hint: 'Enter your facility license number',
              prefixIcon: Icon(Icons.badge_outlined),
            validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter license number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.space16),
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppColors.processorPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppColors.processorPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.processorPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        'Processing Unit Features',
                        style: AppTypography.titleMedium().copyWith(
                          color: AppColors.processorPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                  _buildFeatureItem('Receive animals from abbatoirs'),
                  _buildFeatureItem('Process and create meat products'),
                  _buildFeatureItem('Manage quality control'),
                  _buildFeatureItem('Transfer products to shops'),
                ],
              ),
            ),
          ] else if (_selectedRole == 'shop') ...[
            CustomTextField(
              controller: _storeNameController,
              label: 'Store Name',
              hint: 'Enter your store name',
              prefixIcon: Icon(CustomIcons.shop),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter store name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.space16),
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppColors.shopPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppColors.shopPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.shopPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        'Shop Features',
                        style: AppTypography.titleMedium().copyWith(
                          color: AppColors.shopPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                  _buildFeatureItem('Receive products from processors'),
                  _buildFeatureItem('Manage product inventory'),
                  _buildFeatureItem('Generate customer QR codes'),
                  _buildFeatureItem('Track product origins'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: _getRoleColor(),
            size: 18,
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: CustomButton(
                label: 'Back',
                onPressed: _previousStep,
                variant: ButtonVariant.secondary,
                fullWidth: true,
                customColor: _getRoleColor(),
              ),
            ),
            const SizedBox(width: AppTheme.space16),
          ],
          Expanded(
            flex: _currentStep > 0 ? 1 : 2,
            child: CustomButton(
              label: _currentStep == 2 ? 'Create Account' : 'Continue',
              onPressed: _isLoading ? null : _nextStep,
              variant: ButtonVariant.primary,
              fullWidth: true,
              loading: _isLoading,
              customColor: _getRoleColor(),
            ),
          ),
        ],
      ),
    );
  }
}
