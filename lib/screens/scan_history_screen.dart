import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../models/scan_history.dart';
import '../services/scan_history_service.dart';
import 'product_display_screen.dart';
import '../widgets/enhanced_back_button.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final ScanHistoryService _scanHistoryService = ScanHistoryService();
  List<ScanHistoryItem> _scanHistory = [];
  List<ScanHistoryItem> _filteredHistory = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    setState(() {
      _isLoading = true;
    });

    final history = await _scanHistoryService.getScanHistory();
    setState(() {
      _scanHistory = history;
      _filteredHistory = history;
      _isLoading = false;
    });
  }

  void _filterHistory(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredHistory = _scanHistory;
      } else {
        _filteredHistory = _scanHistory.where((item) {
          return item.productId.contains(query) ||
              (item.productName?.toLowerCase().contains(query.toLowerCase()) ??
                  false);
        }).toList();
      }
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all scan history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _scanHistoryService.clearHistory();
      _loadScanHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F5F5), Color(0xFFE3F2FD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              leading: const EnhancedBackButton(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Scan History'),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF4CAF50)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.history,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.file_download, color: Colors.white),
                  onPressed: _exportHistory,
                  tooltip: 'Export History',
                ),
                IconButton(
                  icon: const Icon(Icons.clear_all, color: Colors.white),
                  onPressed: _clearHistory,
                  tooltip: 'Clear History',
                ),
              ],
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by Product ID or Name',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF757575)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Color(0xFF757575)),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _filteredHistory = _scanHistory;
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: _filterHistory,
                  ),
                ),
              ),
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Scans',
                        _scanHistory.length.toString(),
                        Icons.qr_code_scanner,
                        const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Success Rate',
                        '${_calculateSuccessRate()}%',
                        Icons.check_circle,
                        const Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // History Timeline
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _isLoading
                  ? const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  : _filteredHistory.isEmpty
                  ? SliverToBoxAdapter(
                      child: SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isEmpty
                                    ? Icons.history
                                    : Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No scan history yet'
                                    : 'No results found',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: const Color(0xFF757575),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Start scanning products to see history'
                                    : 'Try different search terms',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _filteredHistory[index];
                          final isFirst = index == 0;
                          final isLast = index == _filteredHistory.length - 1;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TimelineTile(
                              alignment: TimelineAlign.manual,
                              lineXY: 0.15,
                              isFirst: isFirst,
                              isLast: isLast,
                              indicatorStyle: IndicatorStyle(
                                width: 24,
                                height: 24,
                                indicator: Container(
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(item.status),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getStatusIcon(item.status),
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                              beforeLineStyle: LineStyle(
                                color: _getStatusColor(item.status),
                                thickness: 3,
                              ),
                              endChild: Container(
                                margin: const EdgeInsets.only(left: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.productName ?? 'Product ${item.productId}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF212121),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(item.status).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            item.status?.toUpperCase() ?? 'UNKNOWN',
                                            style: TextStyle(
                                              color: _getStatusColor(item.status),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ID: ${item.productId}',
                                      style: const TextStyle(
                                        color: Color(0xFF757575),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Color(0xFF9E9E9E),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDateTime(item.scannedAt),
                                          style: const TextStyle(
                                            color: Color(0xFF9E9E9E),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ProductDisplayScreen(
                                                    productId: item.productId,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.visibility, size: 16),
                                            label: const Text('View'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFF2196F3),
                                              side: const BorderSide(color: Color(0xFF2196F3)),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              textStyle: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () async {
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Scan'),
                                                content: const Text('Remove this scan from history?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(true),
                                                    child: const Text('Delete'),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: const Color(0xFFF44336),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirmed == true) {
                                              await _scanHistoryService.removeScan(item.productId);
                                              _loadScanHistory();
                                            }
                                          },
                                          icon: const Icon(Icons.delete, size: 16),
                                          color: const Color(0xFFF44336),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _filteredHistory.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Batch delete functionality
          _showBatchDeleteDialog();
        },
        icon: const Icon(Icons.delete_sweep),
        label: const Text('Batch Delete'),
        backgroundColor: const Color(0xFFF44336),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
        return const Color(0xFF4CAF50);
      case 'error':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFFFF9800);
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
        return Icons.check;
      case 'error':
        return Icons.error;
      default:
        return Icons.warning;
    }
  }

  int _calculateSuccessRate() {
    if (_scanHistory.isEmpty) return 0;
    final successCount = _scanHistory.where((item) => item.status == 'success').length;
    return ((successCount / _scanHistory.length) * 100).round();
  }

  void _exportHistory() {
    // Mock export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality not implemented yet')),
    );
  }

  void _showBatchDeleteDialog() {
    // Mock batch delete functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Batch delete functionality not implemented yet')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}








