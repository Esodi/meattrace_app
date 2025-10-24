
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
    debugPrint('🚀 [LOGIN_SCREEN] Screen initialized');
    _initAnimations();
    
    // Ensure auth provider is in a clean state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      debugPrint('📊 [LOGIN_SCREEN] Initial auth state - isLoading: ${authProvider.isLoading}, isLoggedIn: ${authProvider.isLoggedIn}');
      
      // Clear any stale loading state
      if (authProvider.isLoading) {
        debugPrint('⚠️ [LOGIN_SCREEN] Clearing stale loading state');
        authProvider.clearError(); // This will trigger notifyListeners with clean state
      }
    });
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
    switch (role.toLowerCase()) {
      case 'farmer':
        context.go('/farmer-home');
        break;
      case 'processingunit':
      case 'processing_unit':
        context.go('/processor-home');
        break;
      case 'shop':
        context.go('/shop-home');
        break;
      default:
        context.go('/farmer-home');
    }
  }

  Future<void> _login() async {
    debugPrint('🔐 [LOGIN_SCREEN] Starting login process...');

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ [LOGIN_SCREEN] Form validation failed');
      AuthNotificationService.showWarning(
        context,
        'Please fill in all required fields',
        title: 'Validation Error',
      );
      return;
    }

    debugPrint('✅ [LOGIN_SCREEN] Form validation passed');

    // Capture the context before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show loading notification using captured ScaffoldMessenger
    debugPrint('⏳ [LOGIN_SCREEN] Showing loading notification');
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Please wait, signing you in...'),
            ),
          ],
        ),
        backgroundColor: AppColors.textSecondary,
        duration: const Duration(seconds: 30),
        behavior: SnackBarBehavior.floating,
      ),
    );

    debugPrint('🔄 [LOGIN_SCREEN] Calling authProvider.login()...');
    final startTime = DateTime.now();

    try {
      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ [LOGIN_SCREEN] authProvider.login() completed in ${duration.inMilliseconds}ms, success: $success');

      // Dismiss loading notification
      scaffoldMessenger.hideCurrentSnackBar();
      debugPrint('🗑️ [LOGIN_SCREEN] Loading notification dismissed');

      if (success && mounted) {
        debugPrint('🎉 [LOGIN_SCREEN] Login successful, showing success notification');
        
        // Show success notification
        AuthNotificationService.showAuthSuccess(context, 'login');
        debugPrint('✅ [LOGIN_SCREEN] Success notification shown');

        // Small delay to show success message before navigation
        debugPrint('⏱️ [LOGIN_SCREEN] Waiting 500ms before navigation...');
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          debugPrint('🏠 [LOGIN_SCREEN] Navigating to role-based home: ${authProvider.user!.role}');
          _navigateToRoleBasedHome(authProvider.user!.role);
          debugPrint('✅ [LOGIN_SCREEN] Navigation completed');
        }
      } else if (mounted) {
        debugPrint('❌ [LOGIN_SCREEN] Login failed, showing error notification');
        // Show detailed error notification
        final errorMessage = authProvider.error ?? 'Login failed. Please try again.';
        AuthNotificationService.showAuthError(context, errorMessage);
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('💥 [LOGIN_SCREEN] Exception during login after ${duration.inMilliseconds}ms: $e');

      // Dismiss loading notification
      scaffoldMessenger.hideCurrentSnackBar();

      if (mounted) {
        debugPrint('❌ [LOGIN_SCREEN] Showing error notification for exception');
        AuthNotificationService.showAuthError(context, 'Login failed: $e');
      }
    }
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
                                            debugPrint('🔄 [LOGIN_SCREEN] Button rebuild - isLoading: ${authProvider.isLoading}');
                                            return PrimaryButton(
                                              label: 'Sign In',
                                              onPressed: authProvider.isLoading ? null : () {
                                                debugPrint('🖱️ [LOGIN_SCREEN] Sign In button pressed');
                                                _login();
                                              },
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
        // Logo with custom image
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.farmerPrimary,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.farmerPrimary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icons/MEATTRACE_ICON.png',
              width: 94,
              height: 94,
              fit: BoxFit.cover,
            ),
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
