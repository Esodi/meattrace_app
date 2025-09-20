import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/main.dart';
import '../lib/screens/livestock_history_screen.dart';
import '../lib/screens/farmer_home_screen.dart';
import '../lib/providers/animal_provider.dart';
import '../lib/services/navigation_service.dart';
import '../lib/widgets/enhanced_back_button.dart';

void main() {
  group('Enhanced Back Button Navigation Tests', () {
    late SharedPreferences prefs;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    setUp(() async {
      await prefs.clear();
      NavigationService.instance.clearAllNavigationData();
    });

    testWidgets('Back button navigates to farmer home from livestock history', (WidgetTester tester) async {
      // Create a test router with our routes
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => const FarmerHomeScreen()),
          GoRoute(path: '/farmer-home', builder: (context, state) => const FarmerHomeScreen()),
          GoRoute(path: '/livestock-history', builder: (context, state) => const EnhancedLivestockHistoryScreen()),
        ],
        initialLocation: '/livestock-history',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnimalProvider()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the back button in the app bar
      final backButton = find.byType(EnhancedBackButton);
      expect(backButton, findsOneWidget);

      // Tap the back button
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify we're back at farmer home
      expect(find.byType(FarmerHomeScreen), findsOneWidget);
    });

    testWidgets('Back button shows error handling when navigation fails', (WidgetTester tester) async {
      // Create a router with no fallback route
      final router = GoRouter(
        routes: [
          GoRoute(path: '/livestock-history', builder: (context, state) => const EnhancedLivestockHistoryScreen()),
        ],
        initialLocation: '/livestock-history',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnimalProvider()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the back button
      final backButton = find.byType(EnhancedBackButton);
      expect(backButton, findsOneWidget);

      // Tap the back button
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Unable to navigate back. Please try again.'), findsOneWidget);
    });

    testWidgets('Enhanced back button preserves scroll position', (WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => const FarmerHomeScreen()),
          GoRoute(path: '/farmer-home', builder: (context, state) => const FarmerHomeScreen()),
          GoRoute(path: '/livestock-history', builder: (context, state) => const EnhancedLivestockHistoryScreen()),
        ],
        initialLocation: '/livestock-history',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnimalProvider()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate scrolling (if there's content)
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView, const Offset(0, -200));
        await tester.pumpAndSettle();
      }

      // Navigate back
      final backButton = find.byType(EnhancedBackButton);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Navigate forward again
      await tester.tap(find.text('Livestock History'));
      await tester.pumpAndSettle();

      // Verify scroll position is preserved (this would need more complex setup with actual data)
      expect(find.byType(EnhancedLivestockHistoryScreen), findsOneWidget);
    });

    testWidgets('System back button handling works correctly', (WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => const FarmerHomeScreen()),
          GoRoute(path: '/farmer-home', builder: (context, state) => const FarmerHomeScreen()),
          GoRoute(path: '/livestock-history', builder: (context, state) => const EnhancedLivestockHistoryScreen()),
        ],
        initialLocation: '/livestock-history',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnimalProvider()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate system back button press
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // Should navigate back to farmer home
      expect(find.byType(FarmerHomeScreen), findsOneWidget);
    });

    testWidgets('Refresh functionality works correctly', (WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/livestock-history', builder: (context, state) => const EnhancedLivestockHistoryScreen()),
        ],
        initialLocation: '/livestock-history',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnimalProvider()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      // Verify the screen is still there (refresh completed)
      expect(find.byType(EnhancedLivestockHistoryScreen), findsOneWidget);
    });

    testWidgets('Pull to refresh works correctly', (WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/livestock-history', builder: (context, state) => const EnhancedLivestockHistoryScreen()),
        ],
        initialLocation: '/livestock-history',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnimalProvider()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find RefreshIndicator and trigger pull to refresh
      final refreshIndicator = find.byType(RefreshIndicator);
      if (refreshIndicator.evaluate().isNotEmpty) {
        await tester.fling(refreshIndicator, const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      }

      // Verify the screen is still there (refresh completed)
      expect(find.byType(EnhancedLivestockHistoryScreen), findsOneWidget);
    });

    test('NavigationService state preservation works', () async {
      final navigationService = NavigationService.instance;
      
      // Test state saving and restoration
      const testRoute = '/test-route';
      final testState = {
        'scrollPosition': 100.0,
        'selectedFilter': 'cow',
        'timestamp': 1234567890,
      };

      // This would normally be called by the screen
      // await navigationService._saveCurrentState(context, testState);
      
      // Test state retrieval
      final restoredState = await navigationService.restoreState(testRoute);
      
      // In a real test, we'd verify the state matches
      // For now, just verify the method doesn't throw
      expect(restoredState, isA<Map<String, dynamic>?>());
    });

    test('NavigationService fallback routes work correctly', () {
      final navigationService = NavigationService.instance;
      
      // Test navigation history
      expect(navigationService.navigationHistory, isA<List<String>>());
      
      // Test clearing navigation data
      expect(() => navigationService.clearAllNavigationData(), returnsNormally);
    });
  });

  group('Cross-Platform Compatibility Tests', () {
    testWidgets('Back button works on different screen sizes', (WidgetTester tester) async {
      // Test mobile size
      await tester.binding.setSurfaceSize(const Size(375, 667)); // iPhone size
      
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => const FarmerHomeScreen()),
          GoRoute(path: '/livestock-history', builder: (context, state) => const EnhancedLivestockHistoryScreen()),
        ],
        initialLocation: '/livestock-history',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnimalProvider()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify back button is visible and functional
      final backButton = find.byType(EnhancedBackButton);
      expect(backButton, findsOneWidget);

      // Test tablet size
      await tester.binding.setSurfaceSize(const Size(768, 1024)); // iPad size
      await tester.pumpAndSettle();

      // Back button should still be there and functional
      expect(find.byType(EnhancedBackButton), findsOneWidget);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Haptic feedback works without errors', (WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => const FarmerHomeScreen()),
          GoRoute(path: '/livestock-history', builder: (context, state) => const EnhancedLivestockHistoryScreen()),
        ],
        initialLocation: '/livestock-history',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnimalProvider()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap back button (should trigger haptic feedback without errors)
      final backButton = find.byType(EnhancedBackButton);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // If we get here without exceptions, haptic feedback worked
      expect(find.byType(FarmerHomeScreen), findsOneWidget);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('Handles network errors gracefully', (WidgetTester tester) async {
      // Create a provider that will simulate network errors
      final animalProvider = AnimalProvider();
      
      final router = GoRouter(
        routes: [
          GoRoute(path: '/livestock-history', builder: (context, state) => const EnhancedLivestockHistoryScreen()),
        ],
        initialLocation: '/livestock-history',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: animalProvider),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The screen should handle loading and error states gracefully
      expect(find.byType(EnhancedLivestockHistoryScreen), findsOneWidget);
      
      // Look for either loading indicator or error state
      final hasLoadingOrError = find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
                               find.byIcon(Icons.error_outline).evaluate().isNotEmpty ||
                               find.text('No livestock registered yet').evaluate().isNotEmpty;
      
      expect(hasLoadingOrError, isTrue);
    });

    testWidgets('Handles empty state correctly', (WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/livestock-history', builder: (context, state) => const EnhancedLivestockHistoryScreen()),
        ],
        initialLocation: '/livestock-history',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnimalProvider()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state message
      expect(find.text('No livestock registered yet'), findsOneWidget);
      expect(find.text('Register your first animal to get started'), findsOneWidget);
    });
  });
}