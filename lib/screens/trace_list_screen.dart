import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meat_trace_provider.dart';
import '../widgets/trace_card.dart';
import '../widgets/loading_indicator.dart';
import 'trace_detail_screen.dart';

class TraceListScreen extends StatefulWidget {
  const TraceListScreen({super.key});

  @override
  State<TraceListScreen> createState() => _TraceListScreenState();
}

class _TraceListScreenState extends State<TraceListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeatTraceProvider>().fetchMeatTraces();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with search
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Meat Traces'),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 80, left: 16, right: 16),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search traces...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: Color(0xFF757575)),
                          onPressed: () {
                            context.read<MeatTraceProvider>().fetchMeatTraces(
                              search: _searchController.text,
                            );
                          },
                        ),
                      ),
                      onChanged: (value) {
                        context.read<MeatTraceProvider>().fetchMeatTraces(
                          search: value,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: _showFilterDialog,
                tooltip: 'Filter',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () =>
                    context.read<MeatTraceProvider>().fetchMeatTraces(),
                tooltip: 'Refresh',
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Consumer<MeatTraceProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const SizedBox(
                    height: 200,
                    child: LoadingIndicator(),
                  );
                }

                if (provider.error != null) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Color(0xFFF44336),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${provider.error}',
                            style: const TextStyle(color: Color(0xFF757575)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => provider.fetchMeatTraces(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (provider.meatTraces.isEmpty) {
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No meat traces found',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: const Color(0xFF757575),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pull down to refresh or add a new trace',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF9E9E9E),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Container(); // Will be handled by SliverList below
              },
            ),
          ),

          // Trace List
          Consumer<MeatTraceProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading || provider.error != null || provider.meatTraces.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final meatTrace = provider.meatTraces[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TraceCard(
                          meatTrace: meatTrace,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TraceDetailScreen(meatTrace: meatTrace),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: provider.meatTraces.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TraceDetailScreen(meatTrace: null),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Trace'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Traces'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('By Date'),
              onTap: () {
                Navigator.of(context).pop();
                // Implement date filter
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('By Category'),
              onTap: () {
                Navigator.of(context).pop();
                // Implement category filter
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('By Location'),
              onTap: () {
                Navigator.of(context).pop();
                // Implement location filter
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
