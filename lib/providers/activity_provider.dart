import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/activity.dart';
import '../services/api_service.dart';

/// Activity Provider
/// Manages abbatoir activity feed with backend synchronization
class ActivityProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Activity> _activities = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetchTime;

  ActivityProvider(this._apiService) {
    debugPrint(
      '━━━━━━━━━━━━━━━━━━━━━━XXXXXX━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );
    debugPrint('🎯 ActivityProvider: Constructor START');
    debugPrint('   - ApiService instance: ${_apiService.hashCode}');
    debugPrint('   - Provider instance: $hashCode');
    debugPrint('   - Thread: ${DateTime.now().millisecondsSinceEpoch}');

    try {
      // Initialize with empty state to prevent provider creation errors
      _activities = [];
      _isLoading = false;
      _error = null;
      _lastFetchTime = null;

      debugPrint('✅ ActivityProvider: Constructor completed successfully');
      debugPrint('   - _activities.length: ${_activities.length}');
      debugPrint('   - _isLoading: $_isLoading');
    } catch (e, stack) {
      debugPrint('❌ ActivityProvider: Constructor FAILED');
      debugPrint('   Error: $e');
      debugPrint('   Stack trace:');
      debugPrint('$stack');
      rethrow;
    }
    debugPrint(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );
  }

  // Getters
  List<Activity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetchTime => _lastFetchTime;

  /// Fetch activities from backend
  Future<void> fetchActivities({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }

    if (!forceRefresh &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 5 &&
        _activities.isNotEmpty) {
      return;
    }

    Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });

    try {
      final data = await _apiService.fetchActivities();
      final List<dynamic> activitiesList = data['activities'] ?? data ?? [];

      _activities = activitiesList
          .map((json) => Activity.fromJson(json as Map<String, dynamic>))
          .toList();

      _lastFetchTime = DateTime.now();
      await _saveActivitiesToCache();
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      _error = 'Network error: $e';
      await _loadActivitiesFromCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new activity (local + backend)
  Future<void> addActivity(Activity activity) async {
    try {
      // Add locally first for instant feedback
      Future.microtask(() {
        _activities.insert(0, activity);
        notifyListeners();
      });

      // Send to backend
      final response = await _apiService.post(
        '/activities/',
        data: activity.toJson(),
      );

      // Update with server response (includes ID)
      final serverActivity = Activity.fromJson(response.data);

      // Replace the local activity with server version
      final index = _activities.indexWhere(
        (a) => a.timestamp == activity.timestamp,
      );
      if (index != -1) {
        _activities[index] = serverActivity;
      }

      await _saveActivitiesToCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding activity: $e');
      // Keep the local version even if backend fails
    }
  }

  /// Get recent activities (last N items)
  List<Activity> getRecentActivities({int limit = 5}) {
    return _activities.take(limit).toList();
  }

  /// Get activities by type
  List<Activity> getActivitiesByType(ActivityType type) {
    return _activities.where((a) => a.type == type).toList();
  }

  /// Get activities for a specific entity (e.g., animal)
  List<Activity> getActivitiesForEntity(String entityId) {
    return _activities.where((a) => a.entityId == entityId).toList();
  }

  /// Clear all activities
  void clearActivities() {
    _activities = [];
    _lastFetchTime = null;
    _error = null;
    notifyListeners();
    _clearActivitiesCache();
  }

  /// Generate sample activities for testing
  void generateSampleActivities() {
    final now = DateTime.now();
    _activities = [
      ActivityFactory.registration(
        animalId: '1',
        animalTag: 'COW-2024-001',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      ActivityFactory.transfer(
        count: 5,
        processorName: 'Premium Meats Co.',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      ActivityFactory.healthUpdate(
        animalId: '2',
        animalTag: 'COW-2024-002',
        newStatus: 'Healthy',
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      ActivityFactory.weightUpdate(
        animalId: '3',
        animalTag: 'PIG-2024-015',
        weight: 85.5,
        timestamp: now.subtract(const Duration(days: 3)),
      ),
      ActivityFactory.vaccination(
        animalId: '4',
        animalTag: 'COW-2024-003',
        vaccineName: 'Foot-and-Mouth Disease',
        timestamp: now.subtract(const Duration(days: 5)),
      ),
    ];
    _lastFetchTime = now;
    notifyListeners();
  }

  /// Save activities to local cache
  Future<void> _saveActivitiesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = _activities.map((a) => a.toJson()).toList();
      await prefs.setString('cached_activities', json.encode(activitiesJson));
      await prefs.setString(
        'activities_last_fetch',
        _lastFetchTime?.toIso8601String() ?? '',
      );
    } catch (e) {
      debugPrint('Error saving activities to cache: $e');
    }
  }

  /// Load activities from local cache
  Future<void> _loadActivitiesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_activities');
      final lastFetch = prefs.getString('activities_last_fetch');

      if (cachedData != null) {
        final List<dynamic> activitiesList = json.decode(cachedData);
        _activities = activitiesList
            .map((json) => Activity.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      if (lastFetch != null && lastFetch.isNotEmpty) {
        _lastFetchTime = DateTime.parse(lastFetch);
      }
    } catch (e) {
      debugPrint('Error loading activities from cache: $e');
      // Don't rethrow - ensure we have a valid state even if cache fails
      _activities = [];
      _lastFetchTime = null;
    }
  }

  /// Clear activities cache
  Future<void> _clearActivitiesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_activities');
      await prefs.remove('activities_last_fetch');
    } catch (e) {
      debugPrint('Error clearing activities cache: $e');
    }
  }

  /// Log a registration activity
  Future<void> logRegistration({
    required String animalId,
    required String animalTag,
  }) async {
    final activity = ActivityFactory.registration(
      animalId: animalId,
      animalTag: animalTag,
      timestamp: DateTime.now(),
    );
    await addActivity(activity);
  }

  /// Log a transfer activity
  Future<void> logTransfer({
    required int count,
    required String processorName,
    String? batchId,
  }) async {
    final activity = Activity(
      type: ActivityType.transfer,
      title:
          'Transferred $count animal${count > 1 ? 's' : ''} to $processorName',
      description:
          'Successfully transferred $count animal${count > 1 ? 's' : ''} to $processorName for processing',
      timestamp: DateTime.now(),
      entityId: batchId,
      entityType: 'transfer',
      metadata: {
        'count': count,
        'processor': processorName,
        'batch_id': batchId,
      },
      targetRoute: '/abbatoir/livestock-history',
    );
    await addActivity(activity);
  }

  /// Log a part transfer activity (for split carcass parts)
  Future<void> logPartTransfer({
    required String animalId,
    required String animalTag,
    required List<String> partTypes,
    required String processorName,
    String? batchId,
  }) async {
    final partsList = partTypes.join(', ');
    final activity = Activity(
      type: ActivityType.transfer,
      title:
          'Transferred ${partTypes.length} part${partTypes.length > 1 ? 's' : ''} from $animalTag to $processorName',
      description: 'Parts: $partsList',
      timestamp: DateTime.now(),
      entityId: animalId,
      entityType: 'animal',
      metadata: {
        'processor': processorName,
        'parts': partTypes,
        'part_count': partTypes.length,
        'transfer_type': 'parts',
        'batch_id': batchId,
      },
      targetRoute: '/animals/$animalId',
    );
    await addActivity(activity);
  }

  /// Log a mixed transfer activity (whole animals + parts)
  Future<void> logMixedTransfer({
    required int wholeAnimalCount,
    required int partTransferCount,
    required String processorName,
    String? batchId,
  }) async {
    final activity = Activity(
      type: ActivityType.transfer,
      title:
          'Transferred $wholeAnimalCount whole animal${wholeAnimalCount > 1 ? 's' : ''} and $partTransferCount part transfer${partTransferCount > 1 ? 's' : ''} to $processorName',
      description:
          'Mixed transfer: $wholeAnimalCount whole animal${wholeAnimalCount > 1 ? 's' : ''} and $partTransferCount carcass part${partTransferCount > 1 ? 's' : ''} sent to $processorName',
      timestamp: DateTime.now(),
      entityId: batchId,
      entityType: 'transfer',
      metadata: {
        'processor': processorName,
        'whole_animals': wholeAnimalCount,
        'part_transfers': partTransferCount,
        'transfer_type': 'mixed',
        'batch_id': batchId,
      },
      targetRoute: '/abbatoir/livestock-history',
    );
    await addActivity(activity);
  }

  /// Log a receive activity (for processors)
  Future<void> logReceive({required int count, String? batchId}) async {
    final activity = Activity(
      type: ActivityType.transfer,
      title: 'Received $count animal${count > 1 ? 's' : ''}',
      description:
          'Received and inspected $count animal${count > 1 ? 's' : ''} at processing facility',
      timestamp: DateTime.now(),
      entityId: batchId,
      entityType: 'receive',
      metadata: {'count': count, 'action': 'receive'},
      targetRoute: '/processor/inventory',
    );
    await addActivity(activity);
  }

  /// Log a part receive activity (for processors receiving split carcass parts)
  Future<void> logPartReceive({
    required String animalId,
    required String animalTag,
    required List<String> partTypes,
    String? batchId,
  }) async {
    final partsList = partTypes.join(', ');
    final activity = Activity(
      type: ActivityType.transfer,
      title:
          'Received ${partTypes.length} part${partTypes.length > 1 ? 's' : ''} from $animalTag',
      description: 'Parts: $partsList',
      timestamp: DateTime.now(),
      entityId: animalId,
      entityType: 'animal',
      metadata: {
        'parts': partTypes,
        'part_count': partTypes.length,
        'action': 'receive',
        'receive_type': 'parts',
        'batch_id': batchId,
      },
      targetRoute: '/processor/inventory',
    );
    await addActivity(activity);
  }

  /// Log a mixed receive activity (whole animals + parts)
  Future<void> logMixedReceive({
    required int wholeAnimalCount,
    required int partReceiveCount,
    String? batchId,
  }) async {
    final activity = Activity(
      type: ActivityType.transfer,
      title:
          'Received $wholeAnimalCount whole animal${wholeAnimalCount > 1 ? 's' : ''} and $partReceiveCount part receive${partReceiveCount > 1 ? 's' : ''}',
      description:
          'Mixed reception: $wholeAnimalCount whole animal${wholeAnimalCount > 1 ? 's' : ''} and $partReceiveCount carcass part${partReceiveCount > 1 ? 's' : ''} received at facility',
      timestamp: DateTime.now(),
      entityId: batchId,
      entityType: 'receive',
      metadata: {
        'whole_animals': wholeAnimalCount,
        'part_receives': partReceiveCount,
        'action': 'receive',
        'receive_type': 'mixed',
        'batch_id': batchId,
      },
      targetRoute: '/processor/inventory',
    );
    await addActivity(activity);
  }

  /// Log a slaughter activity
  Future<void> logSlaughter({
    required String animalId,
    required String animalTag,
  }) async {
    final activity = Activity(
      type: ActivityType.slaughter,
      title: 'Animal $animalTag Slaughtered',
      description: 'Animal with tag $animalTag has been marked as slaughtered.',
      timestamp: DateTime.now(),
      entityId: animalId,
      entityType: 'animal',
      metadata: {'animal_tag': animalTag},
      targetRoute: '/animals/$animalId',
    );
    await addActivity(activity);
  }

  /// Log a health update activity
  Future<void> logHealthUpdate({
    required String animalId,
    required String animalTag,
    required String newStatus,
  }) async {
    final activity = ActivityFactory.healthUpdate(
      animalId: animalId,
      animalTag: animalTag,
      newStatus: newStatus,
      timestamp: DateTime.now(),
    );
    await addActivity(activity);
  }

  /// Log a weight update activity
  Future<void> logWeightUpdate({
    required String animalId,
    required String animalTag,
    required double weight,
  }) async {
    final activity = ActivityFactory.weightUpdate(
      animalId: animalId,
      animalTag: animalTag,
      weight: weight,
      timestamp: DateTime.now(),
    );
    await addActivity(activity);
  }

  /// Log a vaccination activity
  Future<void> logVaccination({
    required String animalId,
    required String animalTag,
    required String vaccineName,
  }) async {
    final activity = ActivityFactory.vaccination(
      animalId: animalId,
      animalTag: animalTag,
      vaccineName: vaccineName,
      timestamp: DateTime.now(),
    );
    await addActivity(activity);
  }
}
