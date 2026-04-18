import '../models/sale.dart';
import '../models/sync_queue_item.dart';
import '../services/database_helper.dart';
import '../services/sale_service.dart';
import '../services/sync_manager.dart';
import '../utils/constants.dart';
import 'package:flutter/foundation.dart';

class SaleRepository {
  final SaleService _saleService = SaleService();
  final DatabaseHelper _db = DatabaseHelper();
  final SyncManager _syncManager = SyncManager();

  Future<List<Sale>> getSales() async {
    try {
      // Try to fetch from remote and update local cache
      final remoteSales = await _saleService.getSales();
      for (final sale in remoteSales) {
        await _db.insertSale(sale, synced: 1);
      }
      return remoteSales;
    } catch (e) {
      debugPrint(
        '⚠️ [SaleRepository] Remote fetch failed, using local cache: $e',
      );
      return await _db.getSales();
    }
  }

  Future<Sale?> getSale(int id) async {
    try {
      final remoteSale = await _saleService.getSale(id);
      await _db.insertSale(remoteSale, synced: 1);
      return remoteSale;
    } catch (e) {
      debugPrint('⚠️ [SaleRepository] Remote fetch failed for sale $id: $e');
      return await _db.getSale(id);
    }
  }

  Future<Sale> createSale(Sale sale) async {
    // Generate a temporary ID if one doesn't exist
    final tempSale = sale.id == null
        ? sale.copyWith(id: -DateTime.now().millisecondsSinceEpoch)
        : sale;

    // 1. Save locally immediately
    await _db.insertSale(tempSale, synced: 0);

    // 2. Add to sync queue
    await _db.addToSyncQueue(
      SyncQueueItem(
        endpoint: Constants.salesEndpoint,
        method: SyncMethod.post,
        body: tempSale.toJson()..remove('id'), // Server generates ID
        createdAt: DateTime.now(),
      ),
    );

    // 3. Trigger sync attempt
    _syncManager.processQueue();

    return tempSale;
  }

  Future<void> deleteSale(int id) async {
    // 1. Remove locally
    await _db.deleteSale(id);

    // 2. Queue remote deletion (only if it wasn't a local-only record)
    if (id > 0) {
      await _db.addToSyncQueue(
        SyncQueueItem(
          endpoint: '${Constants.salesEndpoint}$id/',
          method: SyncMethod.delete,
          body: {},
          createdAt: DateTime.now(),
        ),
      );
      _syncManager.processQueue();
    }
  }
}
