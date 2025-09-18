import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = true;
  ConnectivityResult _connectivityResult = ConnectivityResult.wifi;

  bool get isOnline => _isOnline;
  ConnectivityResult get connectivityResult => _connectivityResult;

  ConnectivityProvider() {
    _initConnectivity();
    _listenToConnectivityChanges();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateConnectivityStatus(results);
    } catch (e) {
      _isOnline = false;
      notifyListeners();
    }
  }

  void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateConnectivityStatus(results);
    });
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    // Use the first result or check if any connection is available
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _connectivityResult = result;
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();
  }

  Future<void> checkConnectivity() async {
    await _initConnectivity();
  }
}
