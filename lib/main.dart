import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'utils/app_theme.dart'; // New theme system
import 'services/network_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/auth_progress_provider.dart';
import 'providers/meat_trace_provider.dart';
import 'providers/animal_provider.dart';
import 'providers/product_provider.dart';
import 'providers/product_category_provider.dart';
import 'providers/shop_receipt_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/order_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/scan_provider.dart';
import 'providers/yield_trends_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/user_management_provider.dart';
import 'providers/user_context_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/processing_unit_management_provider.dart';
import 'providers/shop_management_provider.dart';
import 'providers/notification_provider.dart';
import 'services/api_service.dart';

// Modern UI screens (actively used)
import 'screens/auth/splash_screen.dart';
import 'screens/auth/modern_login_screen.dart';
import 'screens/auth/modern_signup_screen.dart';
import 'screens/auth/processing_unit_signup_screen.dart';
import 'screens/auth/shop_signup_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/pending_approval_screen.dart';

import 'screens/processing_unit/modern_processor_home_screen.dart';
import 'screens/processing_unit/products_list_screen.dart';
import 'screens/processing_unit/product_detail_screen.dart';
import 'screens/processing_unit/receive_animals_screen.dart';
import 'screens/processing_unit/pending_processing_screen.dart';
import 'screens/processing_unit/create_product_screen.dart';
import 'screens/processing_unit/processor_settings_screen.dart';
import 'screens/processing_unit/processor_qr_codes_screen.dart';
import 'screens/processing_unit/processor_analytics_screen.dart';
import 'screens/processing_unit/processor_inventory_screen.dart';
import 'screens/processing_unit/transfer_products_screen.dart';
import 'screens/processing_unit/unit_registration_screen.dart';
import 'screens/processing_unit/unit_user_management_screen.dart';
import 'screens/processing_unit/product_categories_screen.dart';
import 'screens/processing_unit/processor_notification_screen.dart';
import 'screens/shop/modern_shop_home_screen.dart';
import 'screens/shop/receive_products_screen.dart';
import 'screens/shop/shop_registration_screen.dart';
import 'screens/shop/shop_user_management_screen.dart';
import 'screens/shop/shop_settings_screen.dart';
import 'screens/shop/shop_profile_screen.dart';
import 'screens/shop/shop_inventory_screen.dart';
import 'screens/shop/order_history_screen.dart';
import 'screens/shop/place_order_screen.dart';
import 'screens/shop/order_detail_screen.dart';
import 'screens/shop/sell_screen.dart';
import 'screens/common/enhanced_qr_scanner_screen.dart';
import 'screens/common/camera_screen.dart';
import 'screens/common/printer_settings_screen.dart';
import 'screens/abbatoir/modern_abbatoir_home_screen.dart';
import 'screens/abbatoir/livestock_history_screen.dart';
import 'screens/abbatoir/animal_detail_screen.dart';
import 'screens/abbatoir/register_animal_screen.dart';
import 'screens/abbatoir/edit_animal_screen.dart';
import 'screens/abbatoir/transfer_animals_screen.dart';
import 'screens/abbatoir/slaughter_animal_screen.dart';
import 'screens/abbatoir/abbatoir_settings_screen.dart';
import 'screens/abbatoir/modern_abbatoir_profile_screen.dart';
import 'screens/abbatoir/notification_list_screen.dart';
import 'screens/abbatoir/sick_animals_screen.dart';

import 'screens/common/coming_soon_screen.dart';
import 'screens/common/user_profile_screen.dart';
import 'screens/common/settings_screen.dart';

// Old UI screens from outside lib - need to be referenced differently
// Some screens have been moved to lib/screens for better integration

import 'utils/initialization_helper.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Set up global error handlers to catch ALL framework exceptions
      FlutterError.onError = (FlutterErrorDetails details) {
        debugPrint('💥 FLUTTER FRAMEWORK ERROR');
        debugPrint('Exception: ${details.exception}');
        debugPrint('Stack trace: ${details.stack}');
        FlutterError.presentError(details);
      };

      // Catch errors from the platform dispatcher
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('💥 PLATFORM ERROR: $error');
        debugPrint('Stack trace: $stack');
        return true;
      };

      // Print network diagnostics for debugging (run in background)
      // We don't await this as it's just for logging
      InitializationHelper.runInBackground(() async {
        try {
          await NetworkHelper.printNetworkDiagnostics();
        } catch (e) {
          debugPrint('⚠️ Error printing network diagnostics: $e');
        }
      }, debugLabel: 'Network diagnostics');

      runApp(const MyApp());
    },
    (error, stack) {
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('🔥 UNHANDLED ERROR CAUGHT IN runZonedGuarded');
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('Error: $error');
      debugPrint('Error Type: ${error.runtimeType}');
      debugPrint('Stack trace:');
      debugPrint(stack.toString());
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final GoRouter _router;
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize AuthProvider early so we can use it in the router
    // Note: This matches the providers in MultiProvider
    final userContext = UserContextProvider();
    _authProvider = AuthProvider(userContext);

    _initRouter();
  }

  void _initRouter() {
    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: _authProvider,
      redirect: (context, state) {
        final isLoggedIn = _authProvider.isLoggedIn;
        final isInitialized = _authProvider.isInitialized;
        final isGoingToLogin = state.matchedLocation == '/login';
        final isGoingToSignup =
            state.matchedLocation.startsWith('/signup') ||
            state.matchedLocation == '/role-selection' ||
            state.matchedLocation == '/onboarding';
        final isGoingToSplash = state.matchedLocation == '/';
        final isGoingToPendingApproval =
            state.matchedLocation == '/pending-approval';

        debugPrint('🛣️ [ROUTER_REDIRECT] Location: ${state.matchedLocation}');
        debugPrint('   isLoggedIn: $isLoggedIn, isInitialized: $isInitialized');

        if (!isInitialized && !isGoingToSplash) {
          debugPrint('   ➡️ Redirecting to splash (not initialized)');
          return '/';
        }

        if (isLoggedIn) {
          final user = _authProvider.user;
          if (user != null) {
            if (user.hasPendingJoinRequest) {
              if (!isGoingToPendingApproval) {
                return '/pending-approval';
              }
              return null;
            }
            if (user.hasRejectedJoinRequest) {
              if (!isGoingToPendingApproval) {
                return '/pending-approval';
              }
              return null;
            }
          }
        }

        if (isLoggedIn &&
            (isGoingToLogin || isGoingToSignup || isGoingToSplash)) {
          final user = _authProvider.user;
          if (user != null) {
            return _getDashboardForRole(user.role);
          }
        }

        if (!isLoggedIn &&
            !isGoingToLogin &&
            !isGoingToSignup &&
            !isGoingToSplash) {
          return '/login';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/login',
          builder: (context, state) => const ModernLoginScreen(),
        ),
        GoRoute(
          path: '/pending-approval',
          builder: (context, state) {
            final user = _authProvider.user;
            if (user == null ||
                (!user.hasPendingJoinRequest && !user.hasRejectedJoinRequest)) {
              return const ModernLoginScreen();
            }
            final isShop = user.pendingJoinRequestShopName != null;
            final entityName = isShop
                ? (user.pendingJoinRequestShopName ?? 'Unknown Shop')
                : (user.pendingJoinRequestUnitName ?? 'Unknown Unit');
            return PendingApprovalScreen(
              entityName: entityName,
              requestedRole: user.pendingJoinRequestRole ?? 'worker',
              requestedAt: user.pendingJoinRequestDate ?? DateTime.now(),
              isShop: isShop,
              rejectionReason: user.rejectionReason,
            );
          },
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) {
            final role = state.uri.queryParameters['role'];
            return ModernSignupScreen(initialRole: role);
          },
        ),
        GoRoute(
          path: '/signup-processing-unit',
          builder: (context, state) => const ProcessingUnitSignupScreen(),
        ),
        GoRoute(
          path: '/signup-shop',
          builder: (context, state) => const ShopSignupScreen(),
        ),
        GoRoute(
          path: '/role-selection',
          builder: (context, state) => const RoleSelectionScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/abbatoir-home',
          builder: (context, state) => const ModernAbbatoirHomeScreen(),
        ),
        GoRoute(
          path: '/processor-home',
          builder: (context, state) {
            final user = _authProvider.user;
            if (user != null &&
                (user.hasPendingJoinRequest || user.hasRejectedJoinRequest)) {
              return PendingApprovalScreen(
                entityName: user.pendingJoinRequestUnitName ?? 'Unknown Unit',
                requestedRole: user.pendingJoinRequestRole ?? 'worker',
                requestedAt: user.pendingJoinRequestDate ?? DateTime.now(),
                isShop: false,
                rejectionReason: user.rejectionReason,
              );
            }
            return const ModernProcessorHomeScreen();
          },
        ),
        GoRoute(
          path: '/shop-home',
          builder: (context, state) {
            final user = _authProvider.user;
            if (user != null &&
                (user.hasPendingJoinRequest || user.hasRejectedJoinRequest)) {
              return PendingApprovalScreen(
                entityName: user.pendingJoinRequestShopName ?? 'Unknown Shop',
                requestedRole: user.pendingJoinRequestRole ?? 'worker',
                requestedAt: user.pendingJoinRequestDate ?? DateTime.now(),
                isShop: true,
                rejectionReason: user.rejectionReason,
              );
            }
            final index =
                int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
            return ModernShopHomeScreen(initialIndex: index);
          },
        ),
        GoRoute(
          path: '/qr-scanner',
          builder: (context, state) => EnhancedQrScannerScreen(
            source: state.uri.queryParameters['source'],
          ),
        ),
        GoRoute(
          path: '/camera',
          builder: (context, state) => CameraScreen(
            onImagesSelected: (images) => Navigator.of(context).pop(images),
          ),
        ),
        GoRoute(
          path: '/printer-settings',
          builder: (context, state) => const PrinterSettingsScreen(),
        ),
        GoRoute(
          path: '/abbatoir/livestock-history',
          builder: (context, state) => const LivestockHistoryScreen(),
        ),
        GoRoute(
          path: '/abbatoir/sick-animals',
          builder: (context, state) => const SickAnimalsScreen(),
        ),

        GoRoute(
          path: '/animals/:id',
          builder: (context, state) =>
              AnimalDetailScreen(animalId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/animals/:id/edit',
          builder: (context, state) =>
              EditAnimalScreen(animalId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/register-animal',
          builder: (context, state) => const RegisterAnimalScreen(),
        ),
        GoRoute(
          path: '/select-animals-transfer',
          builder: (context, state) => const TransferAnimalsScreen(),
        ),
        GoRoute(
          path: '/slaughter-animal',
          builder: (context, state) => SlaughterAnimalScreen(
            animalId: state.uri.queryParameters['animalId'],
          ),
        ),
        GoRoute(
          path: '/abbatoir/settings',
          builder: (context, state) => const AbbatoirSettingsScreen(),
        ),
        GoRoute(
          path: '/abbatoir/profile',
          builder: (context, state) => const ModernAbbatoirProfileScreen(),
        ),
        GoRoute(
          path: '/abbatoir/notifications',
          builder: (context, state) => const NotificationListScreen(),
        ),
        GoRoute(
          path: '/processor/products',
          builder: (context, state) => const ProductsListScreen(),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (context, state) =>
              ProductDetailScreen(productId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/receive-animals',
          builder: (context, state) => const ReceiveAnimalsScreen(),
        ),
        GoRoute(
          path: '/pending-processing',
          builder: (context, state) => const PendingProcessingScreen(),
        ),
        GoRoute(
          path: '/create-product',
          builder: (context, state) => const CreateProductScreen(),
        ),
        GoRoute(
          path: '/processor/settings',
          builder: (context, state) => const ProcessorSettingsScreen(),
        ),
        GoRoute(
          path: '/processor-qr-codes',
          builder: (context, state) => const ProcessorQRCodesScreen(),
        ),
        GoRoute(
          path: '/processor/analytics',
          builder: (context, state) => const ProcessorAnalyticsScreen(),
        ),
        GoRoute(
          path: '/producer-inventory',
          builder: (context, state) => const ProcessorInventoryScreen(),
        ),
        GoRoute(
          path: '/product-history',
          builder: (context, state) => const ComingSoonScreen(
            featureName: 'Product History',
            description: 'View complete history...',
            icon: Icons.history,
          ),
        ),
        GoRoute(
          path: '/transfer-products',
          builder: (context, state) => const TransferProductsScreen(),
        ),
        GoRoute(
          path: '/processor/product-categories',
          builder: (context, state) => ProductCategoriesScreen(),
        ),
        GoRoute(
          path: '/processor/notifications',
          builder: (context, state) => const ProcessorNotificationScreen(),
        ),
        GoRoute(
          path: '/processing-unit/register',
          builder: (context, state) => const ProcessingUnitRegistrationScreen(),
        ),
        GoRoute(
          path: '/processing-unit/users',
          builder: (context, state) => ProcessingUnitUserManagementScreen(
            unitId: int.parse(state.uri.queryParameters['unitId'] ?? '0'),
          ),
        ),
        GoRoute(
          path: '/shop/register',
          builder: (context, state) => const ShopRegistrationScreen(),
        ),
        GoRoute(
          path: '/shop/users',
          builder: (context, state) => ShopUserManagementScreen(
            shopId: int.parse(state.uri.queryParameters['shopId'] ?? '0'),
          ),
        ),
        GoRoute(
          path: '/shop/inventory',
          builder: (context, state) => const ShopInventoryScreen(),
        ),
        GoRoute(
          path: '/shop/orders',
          builder: (context, state) => const OrderHistoryScreen(),
        ),
        GoRoute(
          path: '/shop/place-order',
          builder: (context, state) => const PlaceOrderScreen(),
        ),
        GoRoute(
          path: '/shop/sell',
          builder: (context, state) => const SellScreen(),
        ),
        GoRoute(
          path: '/shop/orders/:orderId',
          builder: (context, state) => OrderDetailScreen(
            orderId: int.parse(state.pathParameters['orderId']!),
          ),
        ),
        GoRoute(
          path: '/shop/profile',
          builder: (context, state) => const ShopProfileScreen(),
        ),
        GoRoute(
          path: '/receive-products',
          builder: (context, state) => const ReceiveProductsScreen(),
        ),
        GoRoute(
          path: '/shop/settings',
          builder: (context, state) => const ShopSettingsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const UserProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    _authProvider.dispose();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.updateSystemBrightness(brightness == Brightness.dark);
  }

  String _getDashboardForRole(String role) {
    final normalizedRole = role.toLowerCase();
    if (normalizedRole == 'abbatoir') return '/abbatoir-home';
    if (normalizedRole == 'processingunit' ||
        normalizedRole == 'processing_unit' ||
        normalizedRole == 'processor') {
      return '/processor-home';
    }
    if (normalizedRole == 'shop' ||
        normalizedRole == 'shopowner' ||
        normalizedRole == 'shop_owner') {
      return '/shop-home';
    }
    return '/abbatoir-home';
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MyApp');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: _authProvider.userContext),
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => AuthProgressProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => MeatTraceProvider()),
        ChangeNotifierProvider(create: (_) => AnimalProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ProductCategoryProvider()),
        ChangeNotifierProvider(create: (_) => ShopReceiptProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => YieldTrendsProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => UserManagementProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider(ApiService())),
        ChangeNotifierProvider(
          create: (_) => ProcessingUnitManagementProvider(),
        ),
        ChangeNotifierProvider(create: (_) => ShopManagementProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final userRole = _authProvider.user?.role;
          final effectiveTheme = AppTheme.getThemeForRole(userRole);
          final animationDuration = themeProvider.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 300);

          return AnimatedTheme(
            data: effectiveTheme,
            duration: animationDuration,
            child: MaterialApp.router(
              title: 'Nyama Tamu',
              theme: effectiveTheme,
              themeMode: ThemeMode.light,
              routerConfig: _router,
              debugShowCheckedModeBanner: false,
            ),
          );
        },
      ),
    );
  }
}
