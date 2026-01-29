import 'package:flutter/material.dart';
import '../../services/traceability_service.dart';
import '../../models/traceability_entry.dart';
import '../../utils/app_colors.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/custom_button.dart';

class ProcessingTraceabilityScreen extends StatefulWidget {
  const ProcessingTraceabilityScreen({super.key});

  @override
  State<ProcessingTraceabilityScreen> createState() =>
      _ProcessingTraceabilityScreenState();
}

class _ProcessingTraceabilityScreenState
    extends State<ProcessingTraceabilityScreen> {
  final TraceabilityService _traceabilityService = TraceabilityService();
  List<TraceabilityEntry> _entries = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedSpecies = 'all';

  // Stats
  double _totalInitialWeight = 0;
  double _totalProcessedWeight = 0;
  int _activeBatches = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final entries = await _traceabilityService.getTraceabilityReport(
        species: _selectedSpecies == 'all' ? null : _selectedSpecies,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        _entries = entries;
        _calculateStats();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    _totalInitialWeight = 0;
    _totalProcessedWeight = 0;
    _activeBatches = 0;

    for (var entry in _entries) {
      _totalInitialWeight += entry.initialWeight;
      _totalProcessedWeight += entry.processedWeight;
      if (entry.remainingWeight > 0.1) {
        _activeBatches++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: const Text(
          'Traceability Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.processorPrimary, AppColors.processorLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showOnboardingDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildSummarySection()),
            SliverToBoxAdapter(child: _buildFilterSection()),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_entries.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTraceabilityCard(_entries[index]),
                    childCount: _entries.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final yieldPercent = _totalInitialWeight > 0
        ? (_totalProcessedWeight / _totalInitialWeight * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Unit Utilization Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Tooltip(
                message: 'Aggregated stats for the current period',
                child: Icon(
                  Icons.help_outline,
                  size: 20,
                  color: AppColors.processorPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSummaryItem(
                label: 'Received',
                value: '${_totalInitialWeight.toStringAsFixed(1)} kg',
                icon: Icons.inventory_2_outlined,
                color: Colors.blue,
              ),
              _buildSummaryItem(
                label: 'Total Yield',
                value: '${yieldPercent.toStringAsFixed(1)}%',
                icon: Icons.analytics_outlined,
                color: Colors.green,
              ),
              _buildSummaryItem(
                label: 'Active Batches',
                value: _activeBatches.toString(),
                icon: Icons.timer_outlined,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (val) {
              _searchQuery = val;
              _loadData(); // Debounce in prod
            },
            decoration: InputDecoration(
              hintText: 'Search by ID or Name...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['all', 'cow', 'pig', 'goat', 'sheep', 'chicken']
                .map(
                  (species) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(species.toUpperCase()),
                      selected: _selectedSpecies == species,
                      onSelected: (selected) {
                        setState(() => _selectedSpecies = species);
                        _loadData();
                      },
                      selectedColor: AppColors.processorPrimary.withValues(
                        alpha: 0.2,
                      ),
                      checkmarkColor: AppColors.processorPrimary,
                      labelStyle: TextStyle(
                        color: _selectedSpecies == species
                            ? AppColors.processorPrimary
                            : Colors.black54,
                        fontWeight: _selectedSpecies == species
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTraceabilityCard(TraceabilityEntry entry) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        title: Row(
          children: [
            _buildSpeciesIcon(entry.species),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.itemId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    entry.name,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            _buildUtilizationIndicator(entry.utilizationRate),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Received: ${entry.formattedReceivedDate}',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ),
        children: [const Divider(height: 1), _buildCardDetails(entry)],
      ),
    );
  }

  Widget _buildSpeciesIcon(String species) {
    IconData icon;
    Color color;
    switch (species.toLowerCase()) {
      case 'cow':
        icon = Icons.pets;
        color = Colors.brown;
        break;
      case 'pig':
        icon = Icons.pets;
        color = Colors.pink;
        break;
      case 'goat':
        icon = Icons.pets;
        color = Colors.grey;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.blueGrey;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildUtilizationIndicator(double rate) {
    Color color = rate > 90
        ? Colors.green
        : (rate > 50 ? Colors.blue : Colors.orange);

    return Column(
      children: [
        SizedBox(
          height: 40,
          width: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: rate / 100,
                strokeWidth: 4,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Text(
                '${rate.toInt()}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Text(
          'YIELD',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCardDetails(TraceabilityEntry entry) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('From Abattoir', entry.origin, Icons.business),
          _buildDetailRow(
            'Initial Weight',
            '${entry.initialWeight.toStringAsFixed(1)} kg',
            Icons.scale,
          ),
          _buildDetailRow(
            'Weight Remained',
            '${entry.remainingWeight.toStringAsFixed(1)} kg',
            Icons.balance,
          ), // Fix: use variable Name
          _buildDetailRow(
            'Processed Weight',
            '${entry.processedWeight.toStringAsFixed(1)} kg',
            Icons.auto_awesome,
          ),

          const SizedBox(height: 20),
          const Text(
            'Utilization History',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          if (entry.utilizationHistory.isEmpty)
            Text(
              'No products created from this batch yet.',
              style: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...entry.utilizationHistory.map((u) => _buildUtilizationItem(u)),
        ],
      ),
    );
  }

  // Custom getter due to typo fix
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilizationItem(UtilizationHistory u) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  u.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                u.formattedDate,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Batch: ${u.batchNumber}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Text(
                '${u.weight} ${u.weightUnit}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (u.transferredTo != null) ...[
            const Divider(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 14,
                  color: Colors.blue,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Transferred to: ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ),
                Text(
                  u.transferredTo!,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Still in Stock',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Traceability Data Found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by receiving animals from abattoirs.',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Refresh Report',
            onPressed: _loadData,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  void _showOnboardingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Feature: Traceability Dashboard'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Track how your raw materials are used:'),
            SizedBox(height: 12),
            _BulletPoint(
              'Yield: The percentage of the animal processed into products.',
            ),
            _BulletPoint(
              'Active Batches: Animals still in your processed inventory.',
            ),
            _BulletPoint(
              'Lineage: Trace every product back to its source animal.',
            ),
            _BulletPoint(
              'Distribution: See which shops received products from specific animals.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
