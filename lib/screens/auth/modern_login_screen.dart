import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_text_field.dart';

/// MeatTrace Pro - Modern Login Screen
/// Role-based authentication with enhanced UX

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({Key? key}) : super(key: key);

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToRoleBasedHome(String role) {
    switch (role) {
      case 'Farmer':
        context.go('/farmer-home');
        break;
      case 'ProcessingUnit':
        context.go('/processor-home');
        break;
      case 'Shop':
        context.go('/shop-home');
        break;
      default:
        context.go('/farmer-home');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      _navigateToRoleBasedHome(authProvider.user!.role);
    } else if (mounted) {
      _showErrorSnackbar(authProvider.error ?? 'Login failed');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: AppTheme.space12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkSurface,
                    AppColors.darkBackground,
                  ]
                : [
                    AppColors.farmerPrimary.withValues(alpha: 0.05),
                    AppColors.processorPrimary.withValues(alpha: 0.05),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.space24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Logo and Title
                                _buildHeader(),

                                const SizedBox(height: AppTheme.space48),

                                // Login Form Card
                                Card(
                                  elevation: isDark ? 4 : 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppTheme.space24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Welcome Text
                                        Text(
                                          'Welcome Back',
                                          style: AppTypography.headlineSmall(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),

                                        const SizedBox(height: AppTheme.space8),

                                        Text(
                                          'Sign in to continue to MeatTrace Pro',
                                          style: AppTypography.bodyMedium(
                                            color: AppColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),

                                        const SizedBox(height: AppTheme.space32),

                                        // Username Field
                                        CustomTextField(
                                          controller: _usernameController,
                                          label: 'Username',
                                          hint: 'Enter your username',
                                          prefixIcon: const Icon(Icons.person_outline),
                                          textInputAction: TextInputAction.next,
                                          variant: TextFieldVariant.outlined,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your username';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: AppTheme.space16),

                                        // Password Field
                                        CustomTextField(
                                          controller: _passwordController,
                                          label: 'Password',
                                          hint: 'Enter your password',
                                          prefixIcon: const Icon(Icons.lock_outline),
                                          obscureText: true,
                                          textInputAction: TextInputAction.done,
                                          variant: TextFieldVariant.outlined,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            return null;
                                          },
                                          onSubmitted: (_) => _login(),
                                        ),

                                        const SizedBox(height: AppTheme.space24),

                                        // Login Button
                                        Consumer<AuthProvider>(
                                          builder: (context, authProvider, child) {
                                            return PrimaryButton(
                                              label: 'Sign In',
                                              onPressed: authProvider.isLoading ? null : _login,
                                              loading: authProvider.isLoading,
                                              size: ButtonSize.large,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: AppTheme.space24),

                                // Sign Up Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: AppTypography.bodyMedium(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.go('/role-selection'),
                                      child: Text(
                                        'Sign Up',
                                        style: AppTypography.labelLarge(
                                          color: theme.colorScheme.primary,
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
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.space24),
                child: Text(
                  'Climb Up LTD',
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Logo with gradient background
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.farmerPrimary,
                AppColors.processorPrimary,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.farmerPrimary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.qr_code_scanner,
            size: 50,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: AppTheme.space16),
        
        // App Name
        Text(
          'MeatTrace Pro',
          style: AppTypography.displaySmall(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppTheme.space8),

        // Subtitle
        Text(
          '(Nyama Tamu App)',
          style: AppTypography.scriptMedium(
            color: AppColors.textSecondary,
          ).copyWith(
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppTheme.space8),

        // Tagline
        Text(
          'Farm to Table Traceability',
          style: AppTypography.bodyLarge(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

}
