import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart';

/// Splash Screen with Session-Based Authentication Check
/// 
/// This screen is displayed on app launch and performs the following:
/// 1. Checks for existing session token
/// 2. Validates token and fetches user profile
/// 3. Redirects to appropriate dashboard if session is valid
/// 4. Redirects to login screen if session is invalid/expired
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  String _statusMessage = 'Initializing...';
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkAuthenticationStatus();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Update status
      if (mounted) {
        setState(() {
          _statusMessage = 'Checking session...';
        });
      }

      // Ensure auth provider is initialized
      await authProvider.ensureInitialized();

      // Small delay for smooth UX (allow animations to complete)
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // Check if user is logged in
      if (authProvider.isLoggedIn && authProvider.user != null) {
        // Valid session found - redirect to appropriate dashboard
        if (mounted) {
          setState(() {
            _statusMessage = 'Welcome back, ${authProvider.user!.username}!';
          });
        }

        // Small delay to show welcome message
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          _navigateToRoleBasedHome(authProvider.user!.role);
        }
      } else {
        // No valid session - redirect to login
        if (mounted) {
          setState(() {
            _statusMessage = 'Redirecting to login...';
          });
        }

        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          context.go('/login');
        }
      }
    } catch (e) {
      // Error during session check - fallback to login
      debugPrint('❌ Session check failed: $e');
      
      if (mounted) {
        setState(() {
          _statusMessage = 'Session expired. Please login.';
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        context.go('/login');
      }
    }
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
        // Fallback to login if role is unknown
        context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                ? [
                    AppColors.darkSurface,
                    AppColors.darkBackground,
                  ]
                : [
                    AppColors.farmerPrimary.withValues(alpha: 0.1),
                    AppColors.processorPrimary.withValues(alpha: 0.1),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Main centered content
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Logo
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildLogo(),
                      ),
                    ),

                    const SizedBox(height: AppTheme.space32),

                    // App Name
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'MeatTrace Pro',
                        style: AppTypography.displaySmall(
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: AppTheme.space8),

                    // Subtitle
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        '(Nyama Tamu App)',
                        style: AppTypography.scriptMedium(
                          color: AppColors.textSecondary,
                        ).copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: AppTheme.space8),

                    // Tagline
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Farm to Table Traceability',
                        style: AppTypography.bodyLarge(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: AppTheme.space48),

                    // Loading Indicator
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    ),

                    const SizedBox(height: AppTheme.space24),

                    // Status Message
                    Text(
                      _statusMessage,
                      style: AppTypography.bodyMedium(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer positioned at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: Text(
                    'Climb Up LTD',
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.farmerPrimary,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.farmerPrimary.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icons/MEATTRACE_ICON.png',
          width: 112,
          height: 112,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
