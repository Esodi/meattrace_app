import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/animal.dart';
import '../services/animal_service.dart';
import '../services/database_helper.dart';
import '../services/dio_client.dart';
import '../utils/initialization_helper.dart';

class AnimalProvider with ChangeNotifier {
  final AnimalService _animalService = AnimalService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Animal> _animals = [];
  List<Animal> _transferredAnimals = [];
  bool _isLoading = false;
  bool _isCreatingAnimal = false;
  String? _error;
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  double? _headWeight;
  double? _feetWeight;
  double? _wholeCarcassWeight;

  List<Animal> get animals => _animals;
  List<Animal> get transferredAnimals => _transferredAnimals;
  bool get isLoading => _isLoading;
  bool get isCreatingAnimal => _isCreatingAnimal;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  double? get headWeight => _headWeight;
  double? get feetWeight => _feetWeight;
  double? get wholeCarcassWeight => _wholeCarcassWeight;

  // Lazy initializer for background data loading
  late final LazyInitializer<void> _dataInitializer;

  AnimalProvider() {
    _dataInitializer = LazyInitializer(() => _initPrefs());
    // Start initialization in background immediately
    _startBackgroundInitialization();
  }

  Future<void> _startBackgroundInitialization() async {
    try {
      await _dataInitializer.value;
    } catch (e) {
      // Handle initialization errors silently for now
      debugPrint('AnimalProvider initialization error: $e');
    }
  }

  Future<void> _initPrefs() async {
    if (_isInitialized) return; // Already initialized

    try {
      // Initialize SharedPreferences in background isolate
      _prefs = await InitializationHelper.initSharedPreferences();
      await _loadOfflineData();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize AnimalProvider: $e');
      _isInitialized = true; // Mark as initialized even on error
    }
  }

  /// Ensures data is initialized before proceeding
  Future<void> ensureInitialized() async {
    await _dataInitializer.value;
  }

  Future<void> _loadOfflineData() async {
    try {
      _animals = await _dbHelper.getAnimals();
    } catch (e) {
      // If database fails, try shared preferences as fallback
      if (_prefs != null) {
        final cached = _prefs!.getString('animals');
        if (cached != null) {
          try {
            final data = json.decode(cached) as List;
            _animals = data.map((json) => Animal.fromMap(json)).toList();
          } catch (e) {
            // Ignore invalid cache
          }
        }
      }
    }
  }

  Future<void> _saveToDatabase() async {
    await _dbHelper.insertAnimals(_animals);
  }

  /// Clear local animal cache - useful before forcing a fresh fetch from server
  Future<void> clearAnimals() async {
    _animals = [];
    await _dbHelper.clearAnimals();
    debugPrint('AnimalProvider: Local animal cache and database cleared');
  }

  Future<void> fetchAnimals({String? species, bool? slaughtered, String? search, int? page}) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🐄 ANIMAL_PROVIDER - FETCH_ANIMALS START');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('� Parameters:');
    print('   - species: $species');
    print('   - slaughtered: $slaughtered');
    print('   - search: $search');
    print('   - page: $page');
    print('📊 Current state BEFORE fetch:');
    print('   - _animals.length: ${_animals.length}');
    print('   - _isLoading: $_isLoading');
    print('   - _error: $_error');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    print('🔔 notifyListeners() called - isLoading set to true');

    try {
      print('� Calling AnimalService.getAnimals...');
      final result = await _animalService.getAnimals(
        species: species,
        slaughtered: slaughtered,
        search: search,
        page: page,
        ordering: '-created_at', // Order by newest first
      );
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ ANIMAL_SERVICE RESPONSE RECEIVED');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('� Result type: ${result.runtimeType}');
      print('📦 Result keys: ${result.keys.toList()}');
      if (result.containsKey('results')) {
        print('📦 Results type: ${result['results'].runtimeType}');
        print('📦 Results count: ${(result['results'] as List).length}');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      _animals = result['results'] as List<Animal>;
      print('✅ Animals assigned to _animals list. New count: ${_animals.length}');
      
      // Log each animal in detail
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🐮 DETAILED ANIMAL LIST');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      for (var i = 0; i < _animals.length && i < 10; i++) {
        final animal = _animals[i];
        print('[$i] Animal Details:');
        print('    - ID: ${animal.id}');
        print('    - Animal ID: ${animal.animalId}');
        print('    - Species: ${animal.species}');
        print('    - Slaughtered: ${animal.slaughtered}');
        print('    - Transferred To: ${animal.transferredTo}');
        print('    - Received By: ${animal.receivedBy} ${animal.receivedBy != null ? "✅ RECEIVED" : "⏳ PENDING"}');
        print('    - Received At: ${animal.receivedAt}');
        print('    - Farmer ID: ${animal.farmer}');
        print('    - Created: ${animal.createdAt}');
      }
      if (_animals.length > 10) {
        print('... and ${_animals.length - 10} more animals');
      }
      
      // Summary statistics
      final receivedCount = _animals.where((a) => a.receivedBy != null).length;
      final pendingCount = _animals.where((a) => a.transferredTo != null && a.receivedBy == null).length;
      final slaughteredCount = _animals.where((a) => a.slaughtered).length;
      print('');
      print('📊 SUMMARY STATISTICS:');
      print('   ✅ Received animals: $receivedCount');
      print('   ⏳ Pending receipt: $pendingCount');
      print('   🔪 Slaughtered: $slaughteredCount');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      await _saveToDatabase();
      print('💾 Animals saved to database');
      print('✅ FETCH_ANIMALS SUCCESS - Total animals: ${_animals.length}');
    } catch (e, stackTrace) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ ANIMAL_PROVIDER ERROR');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ Error: $e');
      print('❌ Stack trace:');
      print(stackTrace);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _error = e.toString();
      // Load offline data if API fails
      print('🔄 Loading offline data as fallback...');
      await _loadOfflineData();
      print('� Loaded offline data. Animals count: ${_animals.length}');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🏁 ANIMAL_PROVIDER - FETCH_ANIMALS COMPLETE');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('� Final state:');
      print('   - _animals.length: ${_animals.length}');
      print('   - _isLoading: $_isLoading');
      print('   - _error: $_error');
      print('🔔 notifyListeners() called - UI will rebuild');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  Future<List<Animal>> fetchSlaughteredAnimals() async {
    try {
      final result = await _animalService.getAnimals(slaughtered: true);
      return result['results'] as List<Animal>;
    } catch (e) {
      // Try offline data
      return _animals.where((animal) => animal.slaughtered).toList();
    }
  }

  Future<Animal?> createAnimal(Animal animal, {bool isOnline = true, File? photo}) async {
    _isCreatingAnimal = true;
    _error = null;
    notifyListeners();

    try {
      Animal? createdAnimal;
      if (isOnline) {
        print('AnimalProvider.createAnimal - Creating animal online');
        createdAnimal = await _animalService.createAnimal(animal, photo: photo);
        print('AnimalProvider.createAnimal - Animal created: ${createdAnimal.animalId}');
        _animals.add(createdAnimal);
        await _saveToDatabase();
        print('AnimalProvider.createAnimal - Animal added to local list. Total animals: ${_animals.length}');
        notifyListeners(); // Notify listeners immediately after adding
      } else {
        // Save offline with synced = false
        final offlineAnimal = Animal(
          id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
          farmer: animal.farmer,
          species: animal.species,
          age: animal.age,
          liveWeight: animal.liveWeight,
          createdAt: animal.createdAt,
          slaughtered: animal.slaughtered,
          slaughteredAt: animal.slaughteredAt,
          animalId: animal.animalId,
          animalName: animal.animalName,
          breed: animal.breed,
          abbatoirName: animal.abbatoirName,
          healthStatus: animal.healthStatus,
          synced: false,
        );
        _animals.add(offlineAnimal);
        await _dbHelper.insertAnimals([offlineAnimal], synced: false);
        createdAnimal = offlineAnimal;
      }
      notifyListeners();
      return createdAnimal;
    } catch (e) {
      print('AnimalProvider.createAnimal - API call failed: $e');
      print('Animal data: species=${animal.species}, age=${animal.age}, abbatoir=${animal.abbatoirName}');
      print('Connectivity status: ${isOnline ? "online" : "offline"}');
      _error = e.toString();
      // If API fails, try saving offline
      if (e is NetworkException || e is NoInternetException) {
        print('Network error detected, saving offline');
        final offlineAnimal = Animal(
          id: DateTime.now().millisecondsSinceEpoch,
          farmer: animal.farmer,
          species: animal.species,
          age: animal.age,
          liveWeight: animal.liveWeight,
          createdAt: animal.createdAt,
          slaughtered: animal.slaughtered,
          slaughteredAt: animal.slaughteredAt,
          animalId: animal.animalId,
          animalName: animal.animalName,
          breed: animal.breed,
          abbatoirName: animal.abbatoirName,
          healthStatus: animal.healthStatus,
          synced: false,
        );
        _animals.add(offlineAnimal);
        await _dbHelper.insertAnimals([offlineAnimal], synced: false);
        _error = 'Saved offline. Will sync when online.';
        print('Animal saved offline successfully');
        notifyListeners();
        return offlineAnimal;
      }
      print('Non-network error, not saving offline');
      notifyListeners();
      return null;
    } finally {
      _isCreatingAnimal = false;
      notifyListeners();
    }
  }

  Future<void> slaughterAnimal(int animalId) async {
    try {
      // Call the service to slaughter the animal
      final updatedAnimal = await _animalService.slaughterAnimal(animalId);

      // Find the animal in the local list and update it
      final index = _animals.indexWhere((a) => a.id == animalId);
      if (index != -1) {
        _animals[index] = updatedAnimal;
        await _saveToDatabase();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      // Re-throw the exception to be handled by the UI
      rethrow;
    }
  }

  // For backward compatibility
  Future<void> registerAnimal(Animal animal) async {
    await createAnimal(animal);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCarcassWeights() {
    _headWeight = null;
    _feetWeight = null;
    _wholeCarcassWeight = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> transferAnimals(
    List<int?> animalIds, 
    int processingUnitId, {
    List<Map<String, dynamic>>? partTransfers,
  }) async {
    // Store original state for rollback
    final originalAnimals = List<Animal>.from(_animals);
    
    try {
      print('PROVIDER_TRANSFER_START - Animal IDs: $animalIds, Processing Unit ID: $processingUnitId');
      if (partTransfers != null && partTransfers.isNotEmpty) {
        print('PROVIDER_TRANSFER_PARTS - Part transfers: $partTransfers');
      }
      print('PROVIDER_TRANSFER_ANIMAL_COUNT - Count: ${animalIds.length}');
      print('PROVIDER_TRANSFER_FILTERED_IDS - Filtered: ${animalIds.where((id) => id != null).toList()}');

      // OPTIMISTIC UPDATE: Immediately update UI before API call
      final transferredIds = animalIds.where((id) => id != null).cast<int>().toSet();
      _animals = _animals.where((animal) => !transferredIds.contains(animal.id)).toList();
      print('PROVIDER_TRANSFER_OPTIMISTIC_UPDATE - Removed ${transferredIds.length} animals from local list');
      notifyListeners(); // Update UI immediately
      
      // Make API call in background
      final response = await _animalService.transferAnimals(
        animalIds, 
        processingUnitId,
        partTransfers: partTransfers,
      );
      print('PROVIDER_TRANSFER_SUCCESS - Response: $response');

      // Refresh from server to get accurate state
      print('PROVIDER_TRANSFER_REFRESH_START - Refreshing animal list');
      await fetchAnimals();
      print('PROVIDER_TRANSFER_REFRESH_COMPLETE - Animal list refreshed');
      return response;
    } catch (e) {
      print('PROVIDER_TRANSFER_ERROR - Exception: $e');
      print('PROVIDER_TRANSFER_ERROR_TYPE - Type: ${e.runtimeType}');
      
      // ROLLBACK: Restore original state on error
      _animals = originalAnimals;
      print('PROVIDER_TRANSFER_ROLLBACK - Restored original animal list');
      notifyListeners(); // Update UI with rolled-back state
      
      _error = e.toString();
      rethrow;
    }
  }

  Future<List<Animal>> fetchTransferredAnimals() async {
    debugPrint('🔍 [AnimalProvider] fetchTransferredAnimals called');
    try {
      debugPrint('🔍 [AnimalProvider] Calling _animalService.getTransferredAnimals()');
      final result = await _animalService.getTransferredAnimals();
      debugPrint('🔍 [AnimalProvider] Fetched ${result.length} transferred animals');
      return result;
    } catch (e) {
      debugPrint('🔍 [AnimalProvider] Error in fetchTransferredAnimals: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> receiveAnimals(
    List<int?> animalIds, {
    List<Map<String, dynamic>>? partReceives,
    List<Map<String, dynamic>>? animalRejections,
    List<Map<String, dynamic>>? partRejections,
  }) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🌐 [ANIMAL_PROVIDER] Calling receiveAnimals API...');
      print('  Animal IDs: $animalIds');
      print('  Part receives: ${partReceives?.length ?? 0}');
      print('  Animal rejections: ${animalRejections?.length ?? 0}');
      print('  Part rejections: ${partRejections?.length ?? 0}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final response = await _animalService.receiveAnimals(
        animalIds,
        partReceives: partReceives,
        animalRejections: animalRejections,
        partRejections: partRejections,
      );
      
      print('✅ [ANIMAL_PROVIDER] receiveAnimals API response: $response');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      return response;
    } catch (e) {
      print('❌ [ANIMAL_PROVIDER] receiveAnimals error: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> syncUnsyncedAnimals() async {
    final unsynced = await _dbHelper.getUnsyncedAnimals();
    for (final animal in unsynced) {
      try {
        final syncedAnimal = await _animalService.createAnimal(animal);
        // Update local with server ID and mark as synced
        final index = _animals.indexWhere((a) => a.id == animal.id);
        if (index != -1) {
          _animals[index] = syncedAnimal;
        }
        await _dbHelper.markAnimalAsSynced(syncedAnimal.id!);
        await _saveToDatabase();
      } catch (e) {
        // If still fails, keep as unsynced
        _error = 'Failed to sync some animals: $e';
      }
    }
    notifyListeners();
  }

  Future<List<Animal>> fetchTransferredAnimalsForFarmer() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _transferredAnimals = await _animalService.getTransferredAnimalsForFarmer();
      return _transferredAnimals;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> getTransferredAnimalsCount() async {
    try {
      final transferredAnimals = await _animalService.getTransferredAnimalsForFarmer();
      return transferredAnimals.length;
    } catch (e) {
      // If API fails, try to count from local data (though it won't have transferred animals)
      return _animals.where((a) => a.transferredTo != null).length;
    }
  }

  Future<void> deleteAnimal(int animalId) async {
    try {
      await _animalService.deleteAnimal(animalId);
      _animals.removeWhere((animal) => animal.id == animalId);
      await _saveToDatabase();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getProcessingUnits() async {
    try {
      return await _animalService.getProcessingUnits();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createCarcassMeasurement(CarcassMeasurement measurement) async {
    try {
      // Extract the new fields from the measurement
      _headWeight = measurement.measurements['head_weight']?['value'];
      _feetWeight = measurement.measurements['feet_weight']?['value'];
      _wholeCarcassWeight = measurement.measurements['whole_carcass_weight']?['value'];

      final createdMeasurement = await _animalService.createCarcassMeasurement(measurement);

      // Find the animal in the local list and update it
      final index = _animals.indexWhere((a) => a.id == measurement.animalId);
      if (index != -1) {
        // Since the slaughter action happens on the backend, we need to refetch the animal
        // to get the updated `slaughtered` status and slaughter parts.
        final updatedAnimal = await _animalService.getAnimal(measurement.animalId);
        _animals[index] = updatedAnimal;
        await _saveToDatabase();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Slaughter Parts Methods
  Future<Map<String, dynamic>> getSlaughterParts({
    int? animalId,
    SlaughterPartType? partType,
    String? search,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    try {
      return await _animalService.getSlaughterParts(
        animalId: animalId,
        partType: partType,
        search: search,
        ordering: ordering,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<SlaughterPart>> getSlaughterPartsList({
    int? animalId,
    SlaughterPartType? partType,
    String? search,
    String? ordering,
  }) async {
    try {
      return await _animalService.getSlaughterPartsList(
        animalId: animalId,
        partType: partType,
        search: search,
        ordering: ordering,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<SlaughterPart> createSlaughterPart(SlaughterPart part) async {
    try {
      return await _animalService.createSlaughterPart(part);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<SlaughterPart> updateSlaughterPart(SlaughterPart part) async {
    try {
      return await _animalService.updateSlaughterPart(part);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSlaughterPart(int id) async {
    try {
      await _animalService.deleteSlaughterPart(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> transferSlaughterParts(List<int?> partIds, int processingUnitId) async {
    try {
      return await _animalService.transferSlaughterParts(partIds, processingUnitId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> receiveSlaughterParts(List<int?> partIds) async {
    try {
      return await _animalService.receiveSlaughterParts(partIds);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}








