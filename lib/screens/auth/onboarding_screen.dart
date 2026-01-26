import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/core/custom_button.dart';

/// Onboarding screen with introduction to MeatTrace Pro
/// Features: 3 onboarding pages, smooth page transitions, skip option
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Complete Traceability',
      description:
          'Track livestock from abbatoir to table with QR codes and complete chain of custody documentation.',
      icon: CustomIcons.qrCodeScan,
      color: AppColors.abbatoirPrimary,
      gradient: [
        AppColors.abbatoirPrimary,
        AppColors.abbatoirPrimary.withValues(alpha: 0.7),
      ],
    ),
    OnboardingPage(
      title: 'Quality Assurance',
      description:
          'Ensure meat quality with health records, processing standards, and safety compliance tracking.',
      icon: CustomIcons.qualityGrade,
      color: AppColors.processorPrimary,
      gradient: [
        AppColors.processorPrimary,
        AppColors.processorPrimary.withValues(alpha: 0.7),
      ],
    ),
    OnboardingPage(
      title: 'Real-Time Updates',
      description:
          'Stay informed with instant notifications for transfers, product updates, and supply chain events.',
      icon: CustomIcons.healthMonitoring,
      color: AppColors.shopPrimary,
      gradient: [
        AppColors.shopPrimary,
        AppColors.shopPrimary.withValues(alpha: 0.7),
      ],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(
                    'Skip',
                    style: AppTypography.button().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.space24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildPageIndicator(index),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                children: [
                  PrimaryButton(
                    label: _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    onPressed: _nextPage,
                  ),
                  if (_currentPage == _pages.length - 1) ...[
                    const SizedBox(height: AppTheme.space16),
                    SecondaryButton(
                      label: 'Already have an account? Login',
                      onPressed: _navigateToLogin,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: page.gradient,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                page.icon,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: AppTheme.space48),

          // Title
          Text(
            page.title,
            style: AppTypography.displayLarge().copyWith(
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.space16),

          // Description
          Text(
            page.description,
            style: AppTypography.bodyLarge().copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? _pages[_currentPage].color
            : AppColors.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

/// Data model for onboarding page
class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}
