import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_history.dart';

class ScanHistoryService {
  static const String _scanHistoryKey = 'scan_history';
  static const int _maxHistoryItems = 100;

  Future<void> addScan(
    String productId, {
    String? productName,
    String? status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getScanHistory();

    // Remove existing entry for same productId if exists
    history.removeWhere((item) => item.productId == productId);

    // Add new entry at the beginning
    history.insert(
      0,
      ScanHistoryItem(
        productId: productId,
        scannedAt: DateTime.now(),
        productName: productName,
        status: status ?? 'success',
      ),
    );

    // Keep only the most recent items
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    // Save to storage
    final historyJson = history.map((item) => item.toJson()).toList();
    await prefs.setString(_scanHistoryKey, jsonEncode(historyJson));
  }

  Future<List<ScanHistoryItem>> getScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_scanHistoryKey);

    if (historyJson == null) return [];

    try {
      final historyList = jsonDecode(historyJson) as List;
      return historyList.map((item) => ScanHistoryItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scanHistoryKey);
  }

  Future<void> removeScan(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getScanHistory();
    history.removeWhere((item) => item.productId == productId);

    final historyJson = history.map((item) => item.toJson()).toList();
    await prefs.setString(_scanHistoryKey, jsonEncode(historyJson));
  }
}








