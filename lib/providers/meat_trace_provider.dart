import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/meat_trace.dart';
import '../services/api_service.dart';

class MeatTraceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<MeatTrace> _meatTraces = [];
  bool _isLoading = false;
  String? _error;
  SharedPreferences? _prefs;

  List<MeatTrace> get meatTraces => _meatTraces;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MeatTraceProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    if (_prefs == null) return;
    final cached = _prefs!.getString('meat_traces');
    if (cached != null) {
      try {
        final data = json.decode(cached) as List;
        _meatTraces = data.map((json) => MeatTrace.fromJson(json)).toList();
        notifyListeners();
      } catch (e) {
        // Ignore invalid cache
      }
    }
  }

  Future<void> _saveToCache() async {
    if (_prefs == null) return;
    final data = _meatTraces.map((trace) => trace.toJson()).toList();
    await _prefs!.setString('meat_traces', json.encode(data));
  }

  Future<void> fetchMeatTraces({String? search, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _meatTraces = await _apiService.fetchMeatTraces(
        search: search,
        status: status,
      );
      await _saveToCache();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createMeatTrace(MeatTrace meatTrace) async {
    try {
      final newTrace = await _apiService.createMeatTrace(meatTrace);
      _meatTraces.add(newTrace);
      await _saveToCache();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateMeatTrace(MeatTrace meatTrace) async {
    try {
      final updatedTrace = await _apiService.updateMeatTrace(meatTrace);
      final index = _meatTraces.indexWhere((t) => t.id == meatTrace.id);
      if (index != -1) {
        _meatTraces[index] = updatedTrace;
        await _saveToCache();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMeatTrace(int id) async {
    try {
      await _apiService.deleteMeatTrace(id);
      _meatTraces.removeWhere((t) => t.id == id);
      await _saveToCache();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
