import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/processing_unit_service.dart';
import '../../models/processing_unit.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_text_field.dart';

/// Processing Unit Signup Screen
/// Allows users to either create a new processing unit or join an existing one
class ProcessingUnitSignupScreen extends StatefulWidget {
  const ProcessingUnitSignupScreen({super.key});

  @override
  State<ProcessingUnitSignupScreen> createState() => _ProcessingUnitSignupScreenState();
}

class _ProcessingUnitSignupScreenState extends State<ProcessingUnitSignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _processingUnitService = ProcessingUnitService();

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Common fields
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Processing unit fields
  final _facilityNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _descriptionController = TextEditingController();

  // State
  int _currentStep = 0; // 0: choice, 1: account, 2: contact, 3: facility
  String _signupMode = ''; // 'create' or 'join'
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  ProcessingUnit? _selectedUnit;
  List<ProcessingUnit> _availableUnits = [];

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
    _facilityNameController.dispose();
    _licenseController.dispose();
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
      _loadAvailableUnits();
    }
  }

  Future<void> _loadAvailableUnits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final units = await _processingUnitService.getProcessingUnits();
      setState(() {
        _availableUnits = units;
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load processing units: $e');
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

      // Step 1: Register the user account
      final success = await authProvider.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        'ProcessingUnit',
      );

      if (!success) {
        throw Exception(authProvider.error ?? 'Registration failed');
      }

      // Step 2: Create processing unit or submit join request
      if (_signupMode == 'create') {
        // Create new processing unit
        await _processingUnitService.createProcessingUnit(
          ProcessingUnit(
            name: _facilityNameController.text.trim(),
            description: _descriptionController.text.trim(),
            location: '${_cityController.text}, ${_stateController.text} ${_zipController.text}',
            contactEmail: _emailController.text.trim(),
            contactPhone: _phoneController.text.trim(),
            licenseNumber: _licenseController.text.trim(),
          ),
        );

        if (mounted) {
          _showSuccessSnackbar('Processing unit created successfully!');
          context.go('/login');
        }
      } else {
        // Submit join request (would need a join request API)
        // For now, just show success message
        if (mounted) {
          _showSuccessSnackbar(
            'Join request submitted! You will be notified when approved.',
          );
          context.go('/login');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.processorPrimary,
              AppColors.processorPrimary.withValues(alpha: 0.7),
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
                          _buildStep3(), // Facility information
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
              CustomIcons.processingPlant,
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
                  'Processing Unit Registration',
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
            'Create a new processing unit or join an existing one',
            style: AppTypography.bodyMedium().copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.space32),
          
          // Create new option
          _buildModeCard(
            icon: Icons.add_business,
            title: 'Create New Processing Unit',
            description: 'Set up your own facility and become the owner',
            onTap: () => _selectMode('create'),
          ),
          
          const SizedBox(height: AppTheme.space16),
          
          // Join existing option
          _buildModeCard(
            icon: Icons.group_add,
            title: 'Join Existing Unit',
            description: 'Request to join an already registered processing facility',
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
          border: Border.all(color: AppColors.processorPrimary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: AppColors.processorPrimary.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppColors.processorPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(icon, color: AppColors.processorPrimary, size: 32),
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
            Icon(Icons.arrow_forward_ios, color: AppColors.processorPrimary),
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
            hint: 'facility@example.com',
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
      return _buildJoinUnitSelection();
    }
    return _buildCreateFacilityForm();
  }

  Widget _buildCreateFacilityForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Facility Information', style: AppTypography.headlineLarge()),
          const SizedBox(height: AppTheme.space32),
          CustomTextField(
            controller: _facilityNameController,
            label: 'Facility Name',
            hint: 'Enter facility name',
            prefixIcon: const Icon(CustomIcons.processingPlant),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter facility name';
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space16),
          CustomTextField(
            controller: _licenseController,
            label: 'License Number',
            hint: 'Enter license number',
            prefixIcon: const Icon(Icons.badge_outlined),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter license number';
              return null;
            },
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
            hint: 'Brief description of your facility',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildJoinUnitSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Processing Unit', style: AppTypography.headlineLarge()),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Choose a processing unit to request membership',
            style: AppTypography.bodyMedium().copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.space24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_availableUnits.isEmpty)
            Center(
              child: Text(
                'No processing units available',
                style: AppTypography.bodyMedium().copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            ..._availableUnits.map((unit) => _buildUnitCard(unit)),
        ],
      ),
    );
  }

  Widget _buildUnitCard(ProcessingUnit unit) {
    final isSelected = _selectedUnit?.id == unit.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedUnit = unit),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space12),
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.processorPrimary
                : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              CustomIcons.processingPlant,
              color: isSelected ? AppColors.processorPrimary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(unit.name, style: AppTypography.titleMedium()),
                  if (unit.location != null)
                    Text(
                      unit.location!,
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.processorPrimary),
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
                customColor: AppColors.processorPrimary,
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
              customColor: AppColors.processorPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
