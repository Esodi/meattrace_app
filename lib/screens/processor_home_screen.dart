import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../services/api_service.dart';
import '../models/production_stats.dart';
import 'dart:async';

class ProcessorHomeScreen extends StatefulWidget {
  const ProcessorHomeScreen({super.key});

  @override
  State<ProcessorHomeScreen> createState() => _ProcessorHomeScreenState();
}

class _ProcessorHomeScreenState extends State<ProcessorHomeScreen> {
  final ApiService _apiService = ApiService();
  ProductionStats? _productionStats;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadProductionStats();
    // Refresh stats every 30 seconds for real-time monitoring
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadProductionStats();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProductionStats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stats = await _apiService.fetchProductionStats();

      if (mounted) {
        setState(() {
          _productionStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.username ?? 'Processor'}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be a good processor, Okay?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            // Action buttons grid - 3+1 layout
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Create\nProduct',
                        Icons.add_business,
                        () => context.go('/create-product'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Receive\nCarcasses',
                        Icons.inventory,
                        () => context.go('/receive-animals'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Products\nCategories',
                        Icons.category,
                        () => context.go('/product-categories'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Scan\nQR',
                        Icons.qr_code_scanner,
                        () => context.go('/qr-scanner?source=processor'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Transifer\nProducts',
                        Icons.send,
                        () => context.go('/select-products-transfer'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Container()), // Empty space
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stats section
            const Text(
              'Production Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text('Error loading stats: $_error'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadProductionStats,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_productionStats != null)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Products Today',
                          _productionStats!.productsCreatedToday.toString(),
                          Icons.inventory_2,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Animals Today',
                          _productionStats!.animalsReceivedToday.toString(),
                          Icons.pets,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Throughput/Day',
                          '${_productionStats!.processingThroughputPerDay.toStringAsFixed(1)}',
                          Icons.trending_up,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCardWithAction(
                          context,
                          'Transferred Products',
                          _productionStats!.productsTransferredToday.toString(),
                          Icons.send,
                          _productionStats!.transferSuccessRate > 80 ? Colors.green : Colors.orange,
                          () => _showTransferHistory(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Pending Animals',
                          _productionStats!.pendingAnimalsToProcess.toString(),
                          Icons.schedule,
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Total Products',
                          _productionStats!.totalProductsCreated.toString(),
                          Icons.production_quantity_limits,
                          Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: ${_formatLastUpdated(_productionStats!.lastUpdated)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              const Center(child: Text('No stats available')),
          ],
        ),
      ),

      // FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/create-product'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dividerGray),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, [IconData? icon, Color? iconColor]) {
    return _buildStatCardWithAction(context, title, value, icon, iconColor, null);
  }

  Widget _buildStatCardWithAction(BuildContext context, String title, String value, [IconData? icon, Color? iconColor, VoidCallback? onTap]) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 32, color: iconColor ?? Theme.of(context).primaryColor),
                const SizedBox(height: 8),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: iconColor ?? Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              if (onTap != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Tap for details',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTransferHistory(BuildContext context) {
    if (_productionStats == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer History'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Products Transferred: ${_productionStats!.totalProductsTransferred}'),
              Text('Products Transferred Today: ${_productionStats!.productsTransferredToday}'),
              Text('Transfer Success Rate: ${_productionStats!.transferSuccessRate.toStringAsFixed(1)}%'),
              const SizedBox(height: 16),
              const Text(
                'Historical Data:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // For now, show a simple message. In a real implementation,
              // this would show a chart or detailed history
              const Text('• Daily transfer trends available in full version'),
              const Text('• Transfer success rate over time'),
              const Text('• Peak transfer periods analysis'),
              const SizedBox(height: 16),
              if (_productionStats!.transferSuccessRate < 80) ...[
                const Text(
                  '⚠️ Low transfer success rate detected',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                const Text('Consider reviewing transfer processes.'),
              ] else ...[
                const Text(
                  '✅ Transfer performance is good',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatLastUpdated(String lastUpdated) {
    try {
      final dateTime = DateTime.parse(lastUpdated);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}