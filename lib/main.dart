import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'utils/app_theme.dart'; // New theme system
import 'services/network_helper.dart';
import 'services/navigation_service.dart';
import 'providers/auth_provider.dart';
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
import 'providers/activity_provider.dart';
import 'providers/processing_unit_management_provider.dart';
import 'providers/shop_management_provider.dart';
import 'services/api_service.dart';

// Modern UI screens (actively used)
import 'screens/auth/splash_screen.dart';
import 'screens/auth/modern_login_screen.dart';
import 'screens/auth/modern_signup_screen.dart';
import 'screens/auth/processing_unit_signup_screen.dart';
import 'screens/auth/shop_signup_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/onboarding_screen.dart';

import 'screens/processing_unit/modern_processor_home_screen.dart';
import 'screens/processing_unit/products_list_screen.dart';
import 'screens/processing_unit/product_detail_screen.dart';
import 'screens/processing_unit/receive_animals_screen.dart';
import 'screens/processing_unit/create_product_screen.dart';
import 'screens/processing_unit/processor_settings_screen.dart';
import 'screens/processing_unit/processor_qr_codes_screen.dart';
import 'screens/processing_unit/processor_analytics_screen.dart';
import 'screens/processing_unit/processor_inventory_screen.dart';
import 'screens/processing_unit/transfer_products_screen.dart';
import 'screens/processing_unit/unit_registration_screen.dart';
import 'screens/processing_unit/unit_user_management_screen.dart';
import 'screens/processing_unit/product_categories_screen.dart';
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
import 'screens/farmer/modern_farmer_home_screen.dart';
import 'screens/farmer/livestock_history_screen.dart';
import 'screens/farmer/animal_detail_screen.dart';
import 'screens/farmer/register_animal_screen.dart';
import 'screens/farmer/edit_animal_screen.dart';
import 'screens/farmer/transfer_animals_screen.dart';
import 'screens/farmer/slaughter_animal_screen.dart';
import 'screens/farmer/settings_screen.dart';
import 'screens/farmer/farmer_profile_screen.dart';
import 'screens/common/coming_soon_screen.dart';
import 'screens/common/user_profile_screen.dart';
import 'screens/common/settings_screen.dart';

// Old UI screens from outside lib - need to be referenced differently
// Some screens have been moved to lib/screens for better integration

import 'utils/initialization_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print network diagnostics for debugging (run in background)
  InitializationHelper.runInBackground(
    () => NetworkHelper.printNetworkDiagnostics(),
    debugLabel: 'Network diagnostics',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.updateSystemBrightness(brightness == Brightness.dark);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MyApp');

    return MultiProvider(
      providers: [
        // Critical providers - loaded immediately
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),

        // Non-critical providers - lazy loaded in background
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
        
        // User Management providers
        ChangeNotifierProvider(create: (_) => ProcessingUnitManagementProvider()),
        ChangeNotifierProvider(create: (_) => ShopManagementProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, _) {
          // Create the router here so route builders run with a BuildContext
          // that includes the providers placed above (MultiProvider).
          final router = GoRouter(
            routes: [
              // Initial splash screen with session check
              GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
              
              // Modern UI routes (actively used)
              GoRoute(path: '/login', builder: (context, state) => const ModernLoginScreen()),
              GoRoute(
                path: '/signup',
                builder: (context, state) {
                  final role = state.uri.queryParameters['role'];
                  return ModernSignupScreen(initialRole: role);
                },
              ),
              GoRoute(path: '/signup-processing-unit', builder: (context, state) => const ProcessingUnitSignupScreen()),
              GoRoute(path: '/signup-shop', builder: (context, state) => const ShopSignupScreen()),
              GoRoute(path: '/role-selection', builder: (context, state) => const RoleSelectionScreen()),
              GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
              GoRoute(path: '/farmer-home', builder: (context, state) => const ModernFarmerHomeScreen()),
              GoRoute(path: '/processor-home', builder: (context, state) => const ModernProcessorHomeScreen()),
              GoRoute(
                path: '/shop-home',
                builder: (context, state) {
                  final index = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
                  return ModernShopHomeScreen(initialIndex: index);
                },
              ),
              GoRoute(
                path: '/qr-scanner',
                builder: (context, state) {
                  final source = state.uri.queryParameters['source'];
                  return EnhancedQrScannerScreen(source: source);
                },
              ),
              GoRoute(
                path: '/camera',
                builder: (context, state) => CameraScreen(
                  onImagesSelected: (images) {
                    Navigator.of(context).pop(images);
                  },
                ),
              ),
              GoRoute(
                path: '/printer-settings',
                builder: (context, state) => const PrinterSettingsScreen(),
              ),
              
              // Farmer routes
              GoRoute(
                path: '/farmer/livestock-history',
                builder: (context, state) => const LivestockHistoryScreen(),
              ),
              GoRoute(
                path: '/animals/:id',
                builder: (context, state) {
                  final animalId = state.pathParameters['id']!;
                  return AnimalDetailScreen(animalId: animalId);
                },
              ),
              GoRoute(
                path: '/animals/:id/edit',
                builder: (context, state) {
                  final animalId = state.pathParameters['id']!;
                  return EditAnimalScreen(animalId: animalId);
                },
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
                builder: (context, state) {
                  final animalId = state.uri.queryParameters['animalId'];
                  return SlaughterAnimalScreen(animalId: animalId);
                },
              ),
              GoRoute(
                path: '/farmer/settings',
                builder: (context, state) => const FarmerSettingsScreen(),
              ),
              GoRoute(
                path: '/farmer/profile',
                builder: (context, state) => const FarmerProfileScreen(),
              ),
              
              // Processor routes
              GoRoute(
                path: '/processor/products',
                builder: (context, state) => const ProductsListScreen(),
              ),
              GoRoute(
                path: '/products/:id',
                builder: (context, state) {
                  final productId = state.pathParameters['id']!;
                  return ProductDetailScreen(productId: productId);
                },
              ),
              GoRoute(
                path: '/receive-animals',
                builder: (context, state) => const ReceiveAnimalsScreen(),
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
                  description: 'View complete history of all products created and transferred.',
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
              
              // User Management routes
              GoRoute(
                path: '/processing-unit/register',
                builder: (context, state) => const ProcessingUnitRegistrationScreen(),
              ),
              GoRoute(
                path: '/processing-unit/users',
                builder: (context, state) {
                  final unitId = int.parse(state.uri.queryParameters['unitId'] ?? '0');
                  return ProcessingUnitUserManagementScreen(unitId: unitId);
                },
              ),
              GoRoute(
                path: '/shop/register',
                builder: (context, state) => const ShopRegistrationScreen(),
              ),
              GoRoute(
                path: '/shop/users',
                builder: (context, state) {
                  final shopId = int.parse(state.uri.queryParameters['shopId'] ?? '0');
                  return ShopUserManagementScreen(shopId: shopId);
                },
              ),
              
              // Shop routes
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
                builder: (context, state) {
                  final orderId = int.parse(state.pathParameters['orderId']!);
                  return OrderDetailScreen(orderId: orderId);
                },
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
                path: '/product-inventory',
                builder: (context, state) => const ComingSoonScreen(
                  featureName: 'Product Inventory',
                  description: 'Manage shop product inventory, stock levels, and pricing.',
                  icon: Icons.inventory_2,
                ),
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

          final userRole = authProvider.user?.role;

          // Compute effective theme based on theme mode and system brightness
          final brightness = themeProvider.themeMode == ThemeMode.system
              ? MediaQuery.platformBrightnessOf(context)
              : (themeProvider.themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light);
          final effectiveTheme = AppTheme.getThemeForRole(userRole);

          // Animation duration respects reduce motion accessibility preference
          final animationDuration = themeProvider.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 300);

          return AnimatedTheme(
            data: effectiveTheme,
            duration: animationDuration,
            child: MaterialApp.router(
              title: 'Nyama Tamu',
              theme: effectiveTheme,
              darkTheme: null, // AnimatedTheme handles theme transitions
              themeMode: ThemeMode.light,
              routerConfig: router,
            ),
          );
        },
      ),
    );
  }
}








