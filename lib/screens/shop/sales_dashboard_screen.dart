import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/sale_provider.dart';
import 'invoice_list_screen.dart';
import 'sales_history_screen.dart';
import 'create_invoice_screen.dart';

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    
    await Future.wait([
      invoiceProvider.loadInvoices(),
      invoiceProvider.loadStats(),
      saleProvider.fetchSales(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & Invoices Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildInvoiceStats(),
            const SizedBox(height: 24),
            _buildSalesStats(),
            const SizedBox(height: 24),
            _buildRecentInvoices(),
            const SizedBox(height: 24),
            _buildRecentSales(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
                      );
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('New Invoice'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SalesHistoryScreen()),
                      );
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text('All Invoices'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceStats() {
    return Consumer<InvoiceProvider>(
      builder: (context, provider, child) {
        final stats = provider.stats;
        if (stats == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final currencyFormatter = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Invoice Statistics',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InvoiceListScreen()),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Invoices',
                        stats['total_invoices']?.toString() ?? '0',
                        Icons.receipt_long,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Pending',
                        stats['pending']?.toString() ?? '0',
                        Icons.hourglass_empty,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Paid',
                        stats['paid']?.toString() ?? '0',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Overdue',
                        stats['overdue']?.toString() ?? '0',
                        Icons.warning,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildValueRow(
                  'Total Value',
                  currencyFormatter.format(stats['total_value'] ?? 0),
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildValueRow(
                  'Total Paid',
                  currencyFormatter.format(stats['total_paid'] ?? 0),
                  Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalesStats() {
    return Consumer<SaleProvider>(
      builder: (context, provider, child) {
        final sales = provider.sales;
        final totalSales = sales.length;
        final totalRevenue = sales.fold<double>(
          0.0,
          (sum, sale) => sum + sale.totalAmount,
        );

        final currencyFormatter = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sales Statistics',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SalesHistoryScreen()),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Sales',
                        totalSales.toString(),
                        Icons.shopping_cart,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.attach_money, color: Colors.green, size: 20),
                                const SizedBox(width: 4),
                                const Text(
                                  'Revenue',
                                  style: TextStyle(fontSize: 12, color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyFormatter.format(totalRevenue),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentInvoices() {
    return Consumer<InvoiceProvider>(
      builder: (context, provider, child) {
        final recentInvoices = provider.invoices.take(5).toList();
        final currencyFormatter = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Invoices',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (recentInvoices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('No invoices yet')),
                  )
                else
                  ...recentInvoices.map((invoice) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(invoice.status).withOpacity(0.2),
                        child: Icon(
                          Icons.receipt_long,
                          color: _getStatusColor(invoice.status),
                          size: 20,
                        ),
                      ),
                      title: Text(invoice.invoiceNumber),
                      subtitle: Text(
                        invoice.customerContact ?? 'No contact',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormatter.format(invoice.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            invoice.statusDisplay,
                            style: TextStyle(
                              fontSize: 11,
                              color: _getStatusColor(invoice.status),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InvoiceListScreen(),
                          ),
                        );
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentSales() {
    return Consumer<SaleProvider>(
      builder: (context, provider, child) {
        final recentSales = provider.sales.take(5).toList();
        final currencyFormatter = NumberFormat.currency(symbol: 'TZS ', decimalDigits: 0);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Sales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (recentSales.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('No sales yet')),
                  )
                else
                  ...recentSales.map((sale) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                      ),
                      title: Text(sale.customerName ?? 'Walk-in Customer'),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(sale.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        currencyFormatter.format(sale.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SalesHistoryScreen()),
                        );
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
