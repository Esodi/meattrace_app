import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/sync_queue_item.dart';
import 'database_helper.dart';
import 'dio_client.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  final DatabaseHelper _db = DatabaseHelper();
  final DioClient _dioClient = DioClient();

  static const int _maxRetries = 5;
  bool _isProcessing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  factory SyncManager() => _instance;

  SyncManager._internal() {
    _init();
  }

  void _init() {
    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        processQueue();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final queue = await _db.getSyncQueue();
      if (queue.isEmpty) {
        _isProcessing = false;
        return;
      }

      debugPrint(
        '🔄 [SyncManager] Processing ${queue.length} items in sync queue...',
      );

      for (final item in queue) {
        // Drop items that have exceeded the retry limit to prevent queue bloat.
        if (item.retryCount >= _maxRetries) {
          debugPrint(
            '🗑️ [SyncManager] Dropping item ${item.id} after $_maxRetries failed attempts.',
          );
          await _db.removeFromSyncQueue(item.id!);
          continue;
        }

        final success = await _syncItem(item);
        if (success) {
          await _db.removeFromSyncQueue(item.id!);
        } else {
          final updatedItem = SyncQueueItem(
            id: item.id,
            endpoint: item.endpoint,
            method: item.method,
            body: item.body,
            createdAt: item.createdAt,
            retryCount: item.retryCount + 1,
            lastError: item.lastError,
          );
          await _db.updateSyncQueueItem(updatedItem);
        }
      }
    } catch (e) {
      debugPrint('❌ [SyncManager] Error processing queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _syncItem(SyncQueueItem item) async {
    try {
      Response response;
      dynamic data = item.body;

      // Handle multipart data (files)
      if (item.filePaths != null && item.filePaths!.isNotEmpty) {
        Map<String, dynamic> formDataMap = Map<String, dynamic>.from(item.body);
        for (final entry in item.filePaths!.entries) {
          final file = File(entry.value);
          if (await file.exists()) {
            formDataMap[entry.key] = await MultipartFile.fromFile(entry.value);
          } else {
            debugPrint('⚠️ [SyncManager] File not found: ${entry.value}');
          }
        }
        data = FormData.fromMap(formDataMap);
      }

      switch (item.method) {
        case SyncMethod.post:
          response = await _dioClient.dio.post(item.endpoint, data: data);
          break;
        case SyncMethod.put:
          response = await _dioClient.dio.put(item.endpoint, data: data);
          break;
        case SyncMethod.patch:
          response = await _dioClient.dio.patch(item.endpoint, data: data);
          break;
        case SyncMethod.delete:
          response = await _dioClient.dio.delete(item.endpoint, data: data);
          break;
      }

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        debugPrint(
          '✅ [SyncManager] Successfully synced item ${item.id} to ${item.endpoint}',
        );
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint(
        '❌ [SyncManager] Failed to sync item ${item.id}: ${e.message}',
      );
      // Update item with error if needed
      return false;
    } catch (e) {
      debugPrint(
        '❌ [SyncManager] Unexpected error syncing item ${item.id}: $e',
      );
      return false;
    }
  }

  // Allow manual trigger
  Future<void> forceSync() async {
    await processQueue();
  }
}
