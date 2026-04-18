import 'package:flutter/material.dart';
import '../models/waste.dart';
import '../services/dio_client.dart';
import '../utils/constants.dart';

class WasteProvider with ChangeNotifier {
  final DioClient _dioClient = DioClient();
  List<Waste> _wasteRecords = [];
  bool _isLoading = false;
  String? _error;

  List<Waste> get wasteRecords => _wasteRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWasteRecords({
    String? wasteType,
    String? stage,
    int? animal,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (wasteType != null) queryParams['waste_type'] = wasteType;
      if (stage != null) queryParams['stage'] = stage;
      if (animal != null) queryParams['animal'] = animal;

      final response = await _dioClient.dio.get(
        Constants.wasteEndpoint,
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data is Map && response.data.containsKey('results')
          ? response.data['results']
          : response.data;

      _wasteRecords = data.map((json) => Waste.fromJson(json)).toList();
    } catch (e) {
      _error = 'Failed to fetch waste records: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> recordWaste(Waste waste) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dioClient.dio.post(
        Constants.wasteEndpoint,
        data: waste.toJson(),
      );
      await fetchWasteRecords();
      return true;
    } catch (e) {
      _error = 'Failed to record waste: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
