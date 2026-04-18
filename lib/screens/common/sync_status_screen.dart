import 'package:flutter/material.dart';
import '../../models/sync_queue_item.dart';
import '../../services/database_helper.dart';
import '../../services/sync_manager.dart';
import 'package:intl/intl.dart';

class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final SyncManager _syncManager = SyncManager();
  List<SyncQueueItem> _queue = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshQueue();
  }

  Future<void> _refreshQueue() async {
    setState(() => _isLoading = true);
    final queue = await _db.getSyncQueue();
    setState(() {
      _queue = queue;
      _isLoading = false;
    });
  }

  Future<void> _triggerSync() async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting synchronization...')),
    );
    }
    await _syncManager.processQueue();
    await _refreshQueue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Center'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshQueue),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _queue.isEmpty
          ? _buildEmptyState()
          : _buildQueueList(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _queue.isEmpty ? null : _triggerSync,
          icon: const Icon(Icons.sync),
          label: const Text('Sync Now'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'All data is synced',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Your changes are safe on the server.'),
        ],
      ),
    );
  }

  Widget _buildQueueList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _queue.length,
      itemBuilder: (context, index) {
        final item = _queue[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: _getMethodIcon(item.method),
            title: Text(
              item.endpoint
                  .split('/')
                  .lastWhere((s) => s.isNotEmpty, orElse: () => 'Operation'),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Queued: ${DateFormat('MMM dd, HH:mm').format(item.createdAt)}',
                ),
                if (item.retryCount > 0)
                  Text(
                    'Retries: ${item.retryCount}',
                    style: const TextStyle(color: Colors.orange),
                  ),
                if (item.lastError != null)
                  Text(
                    'Error: ${item.lastError}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: const Icon(Icons.pending_actions, color: Colors.blue),
            isThreeLine: item.lastError != null || item.retryCount > 0,
          ),
        );
      },
    );
  }

  Widget _getMethodIcon(SyncMethod method) {
    switch (method) {
      case SyncMethod.post:
        return const Icon(Icons.add_circle, color: Colors.green);
      case SyncMethod.put:
      case SyncMethod.patch:
        return const Icon(Icons.edit, color: Colors.orange);
      case SyncMethod.delete:
        return const Icon(Icons.delete_forever, color: Colors.red);
    }
  }
}
