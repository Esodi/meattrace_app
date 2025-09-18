import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'services/network_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/meat_trace_provider.dart';
import 'providers/animal_provider.dart';
import 'providers/product_provider.dart';
import 'providers/shop_receipt_provider.dart';
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
import 'screens/home_screen.dart';
import 'screens/receive_product_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/scan_history_screen.dart';
import 'screens/api_test_screen.dart';
import 'screens/network_debug_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize network connectivity and find working backend URL
  await Constants.initializeBaseUrl();
  
  // Print network diagnostics for debugging
  await NetworkHelper.printNetworkDiagnostics();
  
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
        GoRoute(path: '/livestock-history', builder: (context, state) => const LivestockHistoryScreen()),
        GoRoute(path: '/slaughter-animal', builder: (context, state) => const SlaughterAnimalScreen()),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
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
          builder: (context, state) => const QrScannerScreen(),
        ),
        GoRoute(
          path: '/scan-history',
          builder: (context, state) => const ScanHistoryScreen(),
        ),
        GoRoute(
          path: '/api-test',
          builder: (context, state) => const ApiTestScreen(),
        ),
        GoRoute(
          path: '/network-debug',
          builder: (context, state) => const NetworkDebugScreen(),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MeatTraceProvider()),
        ChangeNotifierProvider(create: (_) => AnimalProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ShopReceiptProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
      ],
      child: MaterialApp.router(
        title: 'MeatTrace App',
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }
}
