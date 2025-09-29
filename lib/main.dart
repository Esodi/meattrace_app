import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'utils/system_navigation_handler.dart';
import 'services/network_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/meat_trace_provider.dart';
import 'providers/animal_provider.dart';
import 'providers/product_provider.dart';
import 'providers/product_category_provider.dart';
import 'providers/shop_receipt_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/order_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/scan_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/farmer_home_screen.dart';
import 'screens/processor_home_screen.dart';
import 'screens/shop_home_screen.dart';
import 'screens/livestock_history_screen.dart';
import 'screens/slaughter_animal_screen.dart';
import 'screens/register_animal_screen.dart';
// import 'screens/home_screen.dart';
import 'screens/receive_product_screen.dart';
import 'screens/receive_animals_screen.dart';
import 'screens/create_product_screen.dart';
import 'screens/product_category_screen.dart';
import 'screens/products_dashboard_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/scan_history_screen.dart';
import 'screens/select_animals_transfer_screen.dart';
import 'screens/select_processing_unit_screen.dart';
import 'screens/select_products_transfer_screen.dart';
import 'screens/select_shop_transfer_screen.dart';
import 'screens/receive_products_screen.dart';
import 'screens/inventory_management_screen.dart';
import 'screens/place_order_screen.dart';
// import 'screens/api_test_screen.dart';
import 'screens/network_debug_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print network diagnostics for debugging
  await NetworkHelper.printNetworkDiagnostics();

  // Initialize system navigation handler
  SystemNavigationHandler.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
        GoRoute(path: '/farmer-home', builder: (context, state) => const FarmerHomeScreen()),
        GoRoute(path: '/processor-home', builder: (context, state) => const ProcessorHomeScreen()),
        GoRoute(path: '/shop-home', builder: (context, state) => const ShopHomeScreen()),
        GoRoute(path: '/livestock-history', builder: (context, state) => const EnhancedLivestockHistoryScreen()),
        GoRoute(path: '/slaughter-animal', builder: (context, state) => const SlaughterAnimalScreen()),
        // GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/receive-product',
          builder: (context, state) => const ReceiveProductScreen(),
        ),
        GoRoute(
          path: '/product-detail/:id',
          builder: (context, state) {
            final productId = int.parse(state.pathParameters['id']!);
            return ProductDetailScreen(productId: productId);
          },
        ),
        GoRoute(
          path: '/qr-scanner',
          builder: (context, state) {
            final source = state.uri.queryParameters['source'];
            return QrScannerScreen(source: source);
          },
        ),
        GoRoute(
          path: '/scan-history',
          builder: (context, state) => const ScanHistoryScreen(),
        ),
        // GoRoute(
        //   path: '/api-test',
        //   builder: (context, state) => const ApiTestScreen(),
        // ),
        GoRoute(
          path: '/network-debug',
          builder: (context, state) => const NetworkDebugScreen(),
        ),
        GoRoute(
          path: '/register-animal',
          builder: (context, state) => const RegisterAnimalScreen(),
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
          path: '/product-categories',
          builder: (context, state) => const ProductCategoryScreen(),
        ),
        GoRoute(
          path: '/products-dashboard',
          builder: (context, state) => const ProductsDashboardScreen(),
        ),
        GoRoute(
          path: '/select-animals-transfer',
          builder: (context, state) => const SelectAnimalsTransferScreen(),
        ),
        GoRoute(
          path: '/select-processing-unit',
          builder: (context, state) => const SelectProcessingUnitScreen(),
        ),
        GoRoute(
          path: '/select-products-transfer',
          builder: (context, state) => const SelectProductsTransferScreen(),
        ),
        GoRoute(
          path: '/select-shop-transfer',
          builder: (context, state) => const SelectShopTransferScreen(),
        ),
        GoRoute(
          path: '/receive-products',
          builder: (context, state) => const ReceiveProductsScreen(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryManagementScreen(),
        ),
        GoRoute(
          path: '/place-order',
          builder: (context, state) => const PlaceOrderScreen(),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MeatTraceProvider()),
        ChangeNotifierProvider(create: (_) => AnimalProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ProductCategoryProvider()),
        ChangeNotifierProvider(create: (_) => ShopReceiptProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
      ],
      child: MaterialApp.router(
        title: 'Nyama Tamu',
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }
}
