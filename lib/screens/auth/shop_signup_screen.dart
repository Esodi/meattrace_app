import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/shop_service.dart';
import '../../models/shop.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_text_field.dart';

/// Shop Signup Screen
/// Allows users to either create a new shop or join an existing one
class ShopSignupScreen extends StatefulWidget {
  const ShopSignupScreen({super.key});

  @override
  State<ShopSignupScreen> createState() => _ShopSignupScreenState();
}

class _ShopSignupScreenState extends State<ShopSignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _shopService = ShopService();

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Common fields
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Shop fields
  final _storeNameController = TextEditingController();
  final _businessLicenseController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _descriptionController = TextEditingController();

  // State
  int _currentStep = 0; // 0: choice, 1: account, 2: contact, 3: shop
  String _signupMode = ''; // 'create' or 'join'
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Shop? _selectedShop;
  List<Shop> _availableShops = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
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
    _storeNameController.dispose();
    _businessLicenseController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _selectMode(String mode) {
    setState(() {
      _signupMode = mode;
      _currentStep = 1;
    });
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    if (mode == 'join') {
      _loadAvailableShops();
    }
  }

  Future<void> _loadAvailableShops() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use public endpoint that doesn't require authentication
      final shops = await _shopService.getPublicShops();
      setState(() {
        _availableShops = shops;
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load shops: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _nextStep() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_currentStep < 3) {
        setState(() {
          _currentStep++;
        });
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submitForm();
      }
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
    } else {
      context.go('/role-selection');
    }
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_signupMode == 'create') {
        // For creating a new shop:
        // The backend register endpoint will automatically create the shop
        // We pass the shop details as part of the registration
        
        final success = await authProvider.register(
          _usernameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          'Shop',
          additionalData: {
            'shop_name': _storeNameController.text.trim(),
            'location': '${_addressController.text}, ${_cityController.text}, ${_stateController.text} ${_zipController.text}',
            'phone': _phoneController.text.trim(),
            'business_license': _businessLicenseController.text.trim(),
            'description': _descriptionController.text.trim(),
          },
        );

        if (!success) {
          throw Exception(authProvider.error ?? 'Registration failed');
        }

        if (mounted) {
          _showSuccessSnackbar('Shop created successfully! Welcome to MeatTrace Pro.');
          _navigateToRoleBasedHome('Shop');
        }
      } else {
        // For joining an existing shop:
        // Step 1: Register the user account first
        final success = await authProvider.register(
          _usernameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          'Shop',
          additionalData: {
            'shop_id': _selectedShop?.id,
            'requested_role': 'worker', // Default role
            'message': 'I would like to join this shop',
          },
        );

        if (!success) {
          throw Exception(authProvider.error ?? 'Registration failed');
        }

        // Step 2: Submit join request (would need a join request API)
        // For now, just show success message
        if (mounted) {
          _showSuccessSnackbar(
            'Join request submitted! You will be notified when approved.',
          );
          _navigateToRoleBasedHome('Shop');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Registration failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToRoleBasedHome(String role) {
    final normalizedRole = role.toLowerCase();
    debugPrint('🚀 [SHOP_SIGNUP] Navigating to home for role: "$role" (normalized: "$normalizedRole")');
    
    // Handle all possible role variations
    if (normalizedRole == 'farmer') {
      debugPrint('   ➡️ Going to: /farmer-home');
      context.go('/farmer-home');
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
              AppColors.shopPrimary,
              AppColors.shopPrimary.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                if (_currentStep > 0) _buildProgressIndicator(),
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
                          _buildModeSelection(),
                          _buildStep1(), // Account credentials
                          _buildStep2(), // Contact information
                          _buildStep3(), // Shop information
                        ],
                      ),
                    ),
                  ),
                ),
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
            onPressed: _previousStep,
          ),
          const SizedBox(width: AppTheme.space12),
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Icon(
              CustomIcons.shop,
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
                  'Shop Registration',
                  style: AppTypography.headlineMedium().copyWith(color: Colors.white),
                ),
                if (_currentStep > 0)
                  Text(
                    'Step $_currentStep of 3',
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
          final isActive = index < _currentStep;
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

  Widget _buildModeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose an Option',
            style: AppTypography.headlineLarge(),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Create a new shop or join an existing one',
            style: AppTypography.bodyMedium().copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.space32),
          
          // Create new option
          _buildModeCard(
            icon: Icons.add_business,
            title: 'Create New Shop',
            description: 'Register your retail store and become the owner',
            onTap: () => _selectMode('create'),
          ),
          
          const SizedBox(height: AppTheme.space16),
          
          // Join existing option
          _buildModeCard(
            icon: Icons.group_add,
            title: 'Join Existing Shop',
            description: 'Request to join an already registered shop',
            onTap: () => _selectMode('join'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space20),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.shopPrimary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: AppColors.shopPrimary.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppColors.shopPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(icon, color: AppColors.shopPrimary, size: 32),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium()),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    description,
                    style: AppTypography.bodySmall().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.shopPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create Account', style: AppTypography.headlineLarge()),
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
            prefixIcon: const Icon(Icons.person_outline),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter username';
              if (value.length < 3) return 'Username must be at least 3 characters';
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space16),
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline),
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter password';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space16),
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            prefixIcon: const Icon(Icons.lock_outline),
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please confirm password';
              if (value != _passwordController.text) return 'Passwords do not match';
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
          Text('Contact Information', style: AppTypography.headlineLarge()),
          const SizedBox(height: AppTheme.space32),
          CustomTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'shop@example.com',
            prefixIcon: const Icon(Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter email';
              if (!value.contains('@')) return 'Please enter valid email';
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space16),
          CustomTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '(555) 123-4567',
            prefixIcon: const Icon(Icons.phone_outlined),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter phone number';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    if (_signupMode == 'join') {
      return _buildJoinShopSelection();
    }
    return _buildCreateShopForm();
  }

  Widget _buildCreateShopForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shop Information', style: AppTypography.headlineLarge()),
          const SizedBox(height: AppTheme.space32),
          CustomTextField(
            controller: _storeNameController,
            label: 'Store Name',
            hint: 'Enter your store name',
            prefixIcon: const Icon(CustomIcons.shop),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter store name';
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space16),
          CustomTextField(
            controller: _businessLicenseController,
            label: 'Business License (Optional)',
            hint: 'Enter business license number',
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          const SizedBox(height: AppTheme.space16),
          CustomTextField(
            controller: _addressController,
            label: 'Street Address',
            hint: '123 Main Street',
            prefixIcon: const Icon(Icons.location_on_outlined),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter address';
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
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: CustomTextField(
                  controller: _stateController,
                  label: 'State',
                  hint: 'ST',
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: CustomTextField(
                  controller: _zipController,
                  label: 'ZIP',
                  hint: '12345',
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          CustomTextField(
            controller: _descriptionController,
            label: 'Description (Optional)',
            hint: 'Brief description of your shop',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildJoinShopSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Shop', style: AppTypography.headlineLarge()),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Choose a shop to request membership',
            style: AppTypography.bodyMedium().copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.space24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_availableShops.isEmpty)
            Center(
              child: Text(
                'No shops available',
                style: AppTypography.bodyMedium().copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            ..._availableShops.map((shop) => _buildShopCard(shop)),
        ],
      ),
    );
  }

  Widget _buildShopCard(Shop shop) {
    final isSelected = _selectedShop?.id == shop.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedShop = shop),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space12),
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.shopPrimary
                : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              CustomIcons.shop,
              color: isSelected ? AppColors.shopPrimary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.name, style: AppTypography.titleMedium()),
                  if (shop.location != null)
                    Text(
                      shop.location!,
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.shopPrimary),
          ],
        ),
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
                customColor: AppColors.shopPrimary,
              ),
            ),
            const SizedBox(width: AppTheme.space16),
          ],
          Expanded(
            flex: _currentStep > 0 ? 1 : 2,
            child: CustomButton(
              label: _currentStep == 3 ? 'Complete Registration' : 'Continue',
              onPressed: _isLoading ? null : (_currentStep == 0 ? null : _nextStep),
              variant: ButtonVariant.primary,
              fullWidth: true,
              loading: _isLoading,
              customColor: AppColors.shopPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
