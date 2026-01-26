import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_progress_provider.dart';
import '../../services/auth_notification_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/logo_with_border.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_text_field.dart';
import '../../widgets/auth/auth_progress_panel.dart';

/// MeatTrace Pro - Modern Login Screen
/// Role-based authentication with enhanced UX

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showProgressPanel = false;
  bool _isProgressExpanded = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    // Ensure auth provider is in a clean state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      debugPrint(
        '📊 [LOGIN_SCREEN] Initial auth state - isLoading: ${authProvider.isLoading}, isLoggedIn: ${authProvider.isLoggedIn}',
      );

      // Clear any stale loading state
      if (authProvider.isLoading) {
        debugPrint('⚠️ [LOGIN_SCREEN] Clearing stale loading state');
        authProvider
            .clearError(); // This will trigger notifyListeners with clean state
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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final progressProvider = Provider.of<AuthProgressProvider>(
      context,
      listen: false,
    );

    // Show progress panel and start WebSocket listener
    setState(() {
      _showProgressPanel = true;
    });

    debugPrint('📡 [LOGIN_SCREEN] Starting auth progress listener...');
    await progressProvider.startListening();
    final sessionId = progressProvider.sessionId;
    debugPrint('🆔 [LOGIN_SCREEN] Session ID: $sessionId');

    // Show loading notification using captured ScaffoldMessenger
    debugPrint('⏳ [LOGIN_SCREEN] Showing loading notification');
    // scaffoldMessenger.showSnackBar(
    //   SnackBar(
    //     content: Row(
    //       children: [
    //         const SizedBox(
    //           width: 20,
    //           height: 20,
    //           child: CircularProgressIndicator(
    //             strokeWidth: 2,
    //             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    //           ),
    //         ),
    //         const SizedBox(width: 12),
    //         const Expanded(
    //           child: Text('Please wait, signing you in...'),
    //         ),
    //       ],
    //     ),
    //     backgroundColor: AppColors.textSecondary,
    //     duration: const Duration(seconds: 30),
    //     behavior: SnackBarBehavior.floating,
    // ),);

    debugPrint(
      '🔄 [LOGIN_SCREEN] Calling authProvider.login() with sessionId...',
    );
    final startTime = DateTime.now();

    try {
      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        sessionId: sessionId,
      );

      final duration = DateTime.now().difference(startTime);
      debugPrint(
        '✅ [LOGIN_SCREEN] authProvider.login() completed in ${duration.inMilliseconds}ms, success: $success',
      );

      // Dismiss loading notification
      scaffoldMessenger.hideCurrentSnackBar();
      debugPrint('🗑️ [LOGIN_SCREEN] Loading notification dismissed');

      if (success && mounted) {
        debugPrint(
          '🎉 [LOGIN_SCREEN] Login successful, showing success notification',
        );

        // Show success notification
        AuthNotificationService.showAuthSuccess(context, 'login');
        debugPrint('✅ [LOGIN_SCREEN] Success notification shown');

        // Small delay to show success message and progress panel
        debugPrint('⏱️ [LOGIN_SCREEN] Waiting 2 seconds before navigating...');
        await Future.delayed(const Duration(seconds: 2));

        // Navigate to appropriate screen based on user status
        final user = authProvider.user;
        if (user != null) {
          // Check if user has pending join request first
          if (user.hasPendingJoinRequest) {
            debugPrint(
              '⏳ [LOGIN_SCREEN] User has pending join request, navigating to pending approval screen',
            );
            debugPrint('📋 [LOGIN_SCREEN] Pending request details:');
            debugPrint('   - Unit: ${user.pendingJoinRequestUnitName}');
            debugPrint('   - Role: ${user.pendingJoinRequestRole}');
            debugPrint('   - Date: ${user.pendingJoinRequestDate}');

            context.go('/pending-approval');
          } else {
            // Navigate to appropriate dashboard based on user role
            final normalizedRole = user.role.toLowerCase();
            debugPrint(
              '🏠 [LOGIN_SCREEN] Navigating to dashboard for role: $normalizedRole',
            );

            if (normalizedRole == 'abbatoir') {
              context.go('/abbatoir-home');
            } else if (normalizedRole == 'processingunit' ||
                normalizedRole == 'processing_unit' ||
                normalizedRole == 'processor') {
              context.go('/processor-home');
            } else if (normalizedRole == 'shop' ||
                normalizedRole == 'shopowner' ||
                normalizedRole == 'shop_owner') {
              context.go('/shop-home');
            } else {
              debugPrint(
                '⚠️ [LOGIN_SCREEN] Unknown role "$normalizedRole", defaulting to abbatoir-home',
              );
              context.go('/abbatoir-home');
            }
          }
        }
      } else if (mounted) {
        debugPrint('❌ [LOGIN_SCREEN] Login failed, showing error notification');
        // Show detailed error notification
        final errorMessage =
            authProvider.error ?? 'Login failed. Please try again.';
        AuthNotificationService.showAuthError(context, errorMessage);

        // Keep progress panel visible to show error details
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() {
            _showProgressPanel = false;
          });
          progressProvider.stopListening();
        }
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint(
        '💥 [LOGIN_SCREEN] Exception during login after ${duration.inMilliseconds}ms: $e',
      );

      // Dismiss loading notification
      scaffoldMessenger.hideCurrentSnackBar();

      if (mounted) {
        debugPrint('❌ [LOGIN_SCREEN] Showing error notification for exception');
        AuthNotificationService.showAuthError(context, 'Login failed: $e');

        // Hide progress panel and stop listener
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() {
            _showProgressPanel = false;
          });
          progressProvider.stopListening();
        }
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkSurface, AppColors.darkBackground]
                : [
                    AppColors.abbatoirPrimary.withValues(alpha: 0.05),
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
                            child: RepaintBoundary(
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
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusLarge,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                        AppTheme.space24,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Welcome Text
                                          Text(
                                            'Welcome Back',
                                            style: AppTypography.headlineSmall(
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),

                                          const SizedBox(
                                            height: AppTheme.space8,
                                          ),

                                          Text(
                                            'Sign in to continue to MeatTrace Pro',
                                            style: AppTypography.bodyMedium(
                                              color: AppColors.textSecondary,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),

                                          const SizedBox(
                                            height: AppTheme.space32,
                                          ),

                                          // Username Field
                                          CustomTextField(
                                            key: const ValueKey(
                                              'username_field',
                                            ),
                                            controller: _usernameController,
                                            focusNode: _usernameFocusNode,
                                            label: 'Username',
                                            hint: 'Enter your username',
                                            prefixIcon: const Icon(
                                              Icons.person_outline,
                                            ),
                                            textInputAction:
                                                TextInputAction.next,
                                            variant: TextFieldVariant.outlined,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter your username';
                                              }
                                              return null;
                                            },
                                          ),

                                          const SizedBox(
                                            height: AppTheme.space16,
                                          ),

                                          // Password Field
                                          CustomTextField(
                                            key: const ValueKey(
                                              'password_field',
                                            ),
                                            controller: _passwordController,
                                            focusNode: _passwordFocusNode,
                                            label: 'Password',
                                            hint: 'Enter your password',
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                            ),
                                            obscureText: true,
                                            textInputAction:
                                                TextInputAction.done,
                                            onSubmitted: (_) => _login(),
                                            variant: TextFieldVariant.outlined,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter your password';
                                              }
                                              return null;
                                            },
                                          ),

                                          const SizedBox(
                                            height: AppTheme.space24,
                                          ),

                                          // Login Button
                                          Consumer<AuthProvider>(
                                            builder: (context, authProvider, child) {
                                              debugPrint(
                                                '🔄 [LOGIN_SCREEN] Button rebuild - isLoading: ${authProvider.isLoading}',
                                              );
                                              return PrimaryButton(
                                                label: 'Sign In',
                                                onPressed:
                                                    authProvider.isLoading
                                                    ? null
                                                    : () {
                                                        debugPrint(
                                                          '🖱️ [LOGIN_SCREEN] Sign In button pressed',
                                                        );
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
                                        onPressed: () =>
                                            context.go('/role-selection'),
                                        child: Text(
                                          'Sign Up',
                                          style: AppTypography.labelLarge(
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Real-time Auth Progress Panel
                                  if (_showProgressPanel) ...[
                                    const SizedBox(height: AppTheme.space16),
                                    Consumer<AuthProgressProvider>(
                                      builder:
                                          (context, progressProvider, child) {
                                            return AuthProgressPanel(
                                              isExpanded: _isProgressExpanded,
                                              onToggle: () {
                                                setState(() {
                                                  _isProgressExpanded =
                                                      !_isProgressExpanded;
                                                });
                                              },
                                            );
                                          },
                                    ),
                                  ],
                                ],
                              ),
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
        // Logo with custom circular border
        const LogoWithBorder(
          size: 90,
          assetPath: 'assets/icons/MEATTRACE_ICON.png',
        ),

        const SizedBox(height: AppTheme.space16),

        // App Name
        Text(
          'MeatTrace Pro',
          style: AppTypography.displaySmall(color: theme.colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppTheme.space8),

        // Subtitle
        Text(
          '(Nyama Tamu App)',
          style: AppTypography.scriptMedium(
            color: AppColors.textSecondary,
          ).copyWith(fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppTheme.space8),

        // Tagline
        Text(
          'Abbatoir to Table Traceability',
          style: AppTypography.bodyLarge(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
