import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/animal.dart';
import '../services/animal_service.dart';
import '../services/database_helper.dart';
import '../services/dio_client.dart';

class AnimalProvider with ChangeNotifier {
  final AnimalService _animalService = AnimalService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Animal> _animals = [];
  bool _isLoading = false;
  String? _error;
  SharedPreferences? _prefs;

  List<Animal> get animals => _animals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AnimalProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    try {
      _animals = await _dbHelper.getAnimals();
      notifyListeners();
    } catch (e) {
      // If database fails, try shared preferences as fallback
      if (_prefs != null) {
        final cached = _prefs!.getString('animals');
        if (cached != null) {
          try {
            final data = json.decode(cached) as List;
            _animals = data.map((json) => Animal.fromMap(json)).toList();
            notifyListeners();
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

  Future<void> fetchAnimals({String? species, bool? slaughtered, String? search, int? page}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _animalService.getAnimals(
        species: species,
        slaughtered: slaughtered,
        search: search,
        page: page,
      );
      _animals = result['results'] as List<Animal>;
      await _saveToDatabase();
    } catch (e) {
      _error = e.toString();
      // Load offline data if API fails
      await _loadOfflineData();
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<Animal?> createAnimal(Animal animal, {bool isOnline = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Animal? createdAnimal;
      if (isOnline) {
        createdAnimal = await _animalService.createAnimal(animal);
        _animals.add(createdAnimal);
        await _saveToDatabase();
      } else {
        // Save offline with synced = false
        final offlineAnimal = Animal(
          id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
          farmer: animal.farmer,
          species: animal.species,
          age: animal.age,
          weight: animal.weight,
          createdAt: animal.createdAt,
          slaughtered: animal.slaughtered,
          slaughteredAt: animal.slaughteredAt,
          animalId: animal.animalId,
          animalName: animal.animalName,
          breed: animal.breed,
          farmName: animal.farmName,
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
      _error = e.toString();
      // If API fails, try saving offline
      if (e is NetworkException || e is NoInternetException) {
        final offlineAnimal = Animal(
          id: DateTime.now().millisecondsSinceEpoch,
          farmer: animal.farmer,
          species: animal.species,
          age: animal.age,
          weight: animal.weight,
          createdAt: animal.createdAt,
          slaughtered: animal.slaughtered,
          slaughteredAt: animal.slaughteredAt,
          animalId: animal.animalId,
          animalName: animal.animalName,
          breed: animal.breed,
          farmName: animal.farmName,
          healthStatus: animal.healthStatus,
          synced: false,
        );
        _animals.add(offlineAnimal);
        await _dbHelper.insertAnimals([offlineAnimal], synced: false);
        _error = 'Saved offline. Will sync when online.';
        notifyListeners();
        return offlineAnimal;
      }
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> slaughterAnimal(String animalId, dynamic result) async {
    try {
      // Find the animal by animalId string
      final index = _animals.indexWhere((a) => a.animalId == animalId);
      if (index == -1) {
        throw Exception('Animal not found');
      }
      final animal = _animals[index];
      // Call service with int id
      final updatedAnimal = await _animalService.slaughterAnimal(animal.id!);
      // Handle the result (slaughter date)
      final updatedWithDate = Animal(
        id: updatedAnimal.id,
        farmer: updatedAnimal.farmer,
        species: updatedAnimal.species,
        age: updatedAnimal.age,
        weight: updatedAnimal.weight,
        createdAt: updatedAnimal.createdAt,
        slaughtered: updatedAnimal.slaughtered,
        slaughteredAt: result as DateTime?,  // Use the provided date
        animalId: updatedAnimal.animalId,
        breed: updatedAnimal.breed,
        farmName: updatedAnimal.farmName,
        healthStatus: updatedAnimal.healthStatus,
      );
      _animals[index] = updatedWithDate;
      await _saveToDatabase();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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

  Future<Map<String, dynamic>> transferAnimals(List<int?> animalIds, int processingUnitId) async {
    try {
      final response = await _animalService.transferAnimals(animalIds, processingUnitId);
      // Refresh animals list after transfer
      await fetchAnimals();
      return response;
    } catch (e) {
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
}
