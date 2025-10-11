import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';
import '../providers/weather_provider.dart';

/// Custom Floating Action Button for Farmer Dashboard
class FarmerDashboardFAB extends StatelessWidget {
  const FarmerDashboardFAB({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonSize = Responsive.getButtonHeight(context);
    
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        return SpeedDial(
          icon: Icons.agriculture,
          activeIcon: Icons.close,
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          activeBackgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.8),
          activeForegroundColor: Colors.white,
          buttonSize: Size.square(buttonSize),
          visible: true,
          closeManually: false,
          curve: Curves.bounceIn,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          elevation: 8.0,
          shape: const CircleBorder(),
          tooltip: 'Farm Quick Actions',
          children: [
            SpeedDialChild(
              child: const Icon(Icons.pets, color: Colors.white),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              label: 'Add Animal',
              labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
              labelBackgroundColor: AppTheme.primaryGreen,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/register-animal');
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.restaurant_menu, color: Colors.white),
              backgroundColor: AppTheme.secondaryBurgundy,
              foregroundColor: Colors.white,
              label: 'Process Livestock',
              labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
              labelBackgroundColor: AppTheme.secondaryBurgundy,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/slaughter-animal');
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.send, color: Colors.white),
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
              label: 'Transfer Animals',
              labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
              labelBackgroundColor: AppTheme.accentOrange,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/select-animals-transfer');
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.wb_sunny, color: Colors.white),
              backgroundColor: AppTheme.infoBlue,
              foregroundColor: Colors.white,
              label: 'Weather Info',
              labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
              labelBackgroundColor: AppTheme.infoBlue,
              onTap: () {
                HapticFeedback.lightImpact();
                _showWeatherDialog(context, weatherProvider);
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.history, color: Colors.white),
              backgroundColor: AppTheme.secondaryBlue,
              foregroundColor: Colors.white,
              label: 'View History',
              labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
              labelBackgroundColor: AppTheme.secondaryBlue,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/livestock-history');
              },
            ),
          ],
        );
      },
    );
  }

  void _showWeatherDialog(BuildContext context, WeatherProvider weatherProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.wb_sunny, color: AppTheme.infoBlue),
              const SizedBox(width: 8),
              const Text('Farm Weather Conditions'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeatherRow('Temperature', '${weatherProvider.temperature ?? 28}°C', Icons.thermostat),
              const SizedBox(height: 8),
              _buildWeatherRow('Condition', weatherProvider.condition ?? 'Sunny', Icons.cloud),
              const SizedBox(height: 8),
              _buildWeatherRow('Soil Moisture', '${(weatherProvider.soilMoisture ?? 75.0).toStringAsFixed(1)}%', Icons.water_drop),
              const SizedBox(height: 8),
              _buildWeatherRow('Location', weatherProvider.location ?? 'Farm Location', Icons.location_on),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                weatherProvider.fetchWeatherData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Weather data refreshed')),
                );
              },
              child: const Text('Refresh'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeatherRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }
}

/// Custom Floating Action Button for Processor Dashboard
class ProcessorDashboardFAB extends StatelessWidget {
  const ProcessorDashboardFAB({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonSize = Responsive.getButtonHeight(context);
    
    return SpeedDial(
      icon: Icons.factory,
      activeIcon: Icons.close,
      backgroundColor: AppTheme.secondaryBlue,
      foregroundColor: Colors.white,
      activeBackgroundColor: AppTheme.secondaryBlue.withValues(alpha: 0.8),
      activeForegroundColor: Colors.white,
      buttonSize: Size.square(buttonSize),
      visible: true,
      closeManually: false,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      elevation: 8.0,
      shape: const CircleBorder(),
      tooltip: 'Processing Quick Actions',
      children: [
        SpeedDialChild(
          child: const Icon(Icons.play_arrow, color: Colors.white),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          label: 'Process Batch',
          labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
          labelBackgroundColor: AppTheme.primaryGreen,
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/create-product');
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.inventory_2, color: Colors.white),
          backgroundColor: AppTheme.accentOrange,
          foregroundColor: Colors.white,
          label: 'Producer Inventory',
          labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
          labelBackgroundColor: AppTheme.accentOrange,
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/producer-inventory');
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.inventory, color: Colors.white),
          backgroundColor: AppTheme.infoBlue,
          foregroundColor: Colors.white,
          label: 'Receive Animals',
          labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
          labelBackgroundColor: AppTheme.infoBlue,
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/receive-animals');
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.send, color: Colors.white),
          backgroundColor: AppTheme.warningOrange,
          foregroundColor: Colors.white,
          label: 'Transfer Products',
          labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
          labelBackgroundColor: AppTheme.warningOrange,
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/select-products-transfer');
          },
        ),
      ],
    );
  }
}

/// Custom Floating Action Button for Shop Dashboard
class ShopDashboardFAB extends StatelessWidget {
  const ShopDashboardFAB({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonSize = Responsive.getButtonHeight(context);
    
    return SpeedDial(
      icon: Icons.storefront,
      activeIcon: Icons.close,
      backgroundColor: AppTheme.secondaryBurgundy,
      foregroundColor: Colors.white,
      activeBackgroundColor: AppTheme.secondaryBurgundy.withValues(alpha: 0.8),
      activeForegroundColor: Colors.white,
      buttonSize: Size.square(buttonSize),
      visible: true,
      closeManually: false,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      elevation: 8.0,
      shape: const CircleBorder(),
      tooltip: 'Shop Quick Actions',
      children: [
        SpeedDialChild(
          child: const Icon(Icons.add_business, color: Colors.white),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          label: 'Add Product',
          labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
          labelBackgroundColor: AppTheme.primaryGreen,
          onTap: () {
            HapticFeedback.lightImpact();
            _showAddProductDialog(context);
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.shopping_cart, color: Colors.white),
          backgroundColor: AppTheme.accentOrange,
          foregroundColor: Colors.white,
          label: 'Manage Orders',
          labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
          labelBackgroundColor: AppTheme.accentOrange,
          onTap: () {
            HapticFeedback.lightImpact();
            _showOrderManagementDialog(context);
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.analytics, color: Colors.white),
          backgroundColor: AppTheme.infoBlue,
          foregroundColor: Colors.white,
          label: 'View Sales',
          labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
          labelBackgroundColor: AppTheme.infoBlue,
          onTap: () {
            HapticFeedback.lightImpact();
            _showSalesDialog(context);
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.inventory_2, color: Colors.white),
          backgroundColor: AppTheme.successGreen,
          foregroundColor: Colors.white,
          label: 'Receive Products',
          labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
          labelBackgroundColor: AppTheme.successGreen,
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/receive-products');
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.qr_code_scanner, color: Colors.white),
          backgroundColor: AppTheme.secondaryBlue,
          foregroundColor: Colors.white,
          label: 'Scan QR Code',
          labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
          labelBackgroundColor: AppTheme.secondaryBlue,
          onTap: () {
            HapticFeedback.lightImpact();
            context.go('/qr-scanner?source=shop');
          },
        ),
      ],
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_business, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              const Text('Add Product'),
            ],
          ),
          content: const Text('Choose how you want to add products to your inventory:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/receive-products');
              },
              child: const Text('Receive from Processor'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/inventory');
              },
              child: const Text('Manage Inventory'),
            ),
          ],
        );
      },
    );
  }

  void _showOrderManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.shopping_cart, color: AppTheme.accentOrange),
              const SizedBox(width: 8),
              const Text('Order Management'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_shopping_cart),
                title: const Text('Place New Order'),
                subtitle: const Text('Order products from processors'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/place-order');
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('View All Orders'),
                subtitle: const Text('Check order status and history'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Navigate to orders list screen (would need to be implemented)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Orders view coming soon')),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showSalesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.infoBlue),
              const SizedBox(width: 8),
              const Text('Sales Analytics'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSalesRow('Today\'s Sales', '\$1,250', Icons.today),
              const SizedBox(height: 8),
              _buildSalesRow('This Week', '\$8,750', Icons.date_range),
              const SizedBox(height: 8),
              _buildSalesRow('This Month', '\$32,500', Icons.calendar_month),
              const SizedBox(height: 8),
              _buildSalesRow('Top Product', 'Premium Beef', Icons.star),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to detailed sales screen (would need to be implemented)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Detailed sales report coming soon')),
                );
              },
              child: const Text('View Details'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSalesRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.secondaryBurgundy),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }
}