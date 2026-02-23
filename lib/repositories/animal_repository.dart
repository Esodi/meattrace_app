import 'dart:io';
import '../models/animal.dart';
import '../models/sync_queue_item.dart';
import '../services/animal_service.dart';
import '../services/database_helper.dart';
import '../services/sync_manager.dart';
import '../utils/constants.dart';
import 'package:flutter/foundation.dart';

class AnimalRepository {
  final AnimalService _animalService = AnimalService();
  final DatabaseHelper _db = DatabaseHelper();
  final SyncManager _syncManager = SyncManager();

  Future<List<Animal>> getAnimals({
    String? species,
    bool? slaughtered,
    String? search,
    int? page,
  }) async {
    try {
      final result = await _animalService.getAnimals(
        species: species,
        slaughtered: slaughtered,
        search: search,
        page: page,
        ordering: '-created_at',
      );
      final animals = result['results'] as List<Animal>;
      await _db.insertAnimals(animals, synced: true);
      return animals;
    } catch (e) {
      debugPrint('⚠️ [AnimalRepository] Remote fetch failed: $e');
      return await _db.getAnimals();
    }
  }

  Future<Animal?> getAnimal(int id) async {
    try {
      final animal = await _animalService.getAnimal(id);
      await _db.insertAnimals([animal], synced: true);
      return animal;
    } catch (e) {
      debugPrint(
        '⚠️ [AnimalRepository] Remote fetch failed for animal $id: $e',
      );
      // No single getAnimal in local DB helper yet, returning from list
      final locals = await _db.getAnimals();
      return locals.firstWhere((a) => a.id == id, orElse: () => throw e);
    }
  }

  Future<Animal> createAnimal(Animal animal, {File? photo}) async {
    final tempId = animal.id ?? DateTime.now().millisecondsSinceEpoch;
    final offlineAnimal = animal.copyWith(id: tempId, synced: false);

    // 1. Save locally
    await _db.insertAnimals([offlineAnimal], synced: false);

    // 2. Queue sync
    await _db.addToSyncQueue(
      SyncQueueItem(
        endpoint: Constants.animalsEndpoint,
        method: SyncMethod.POST,
        body: offlineAnimal.toMap()..remove('id'),
        filePaths: photo != null ? {'photo': photo.path} : null,
        createdAt: DateTime.now(),
      ),
    );

    // 3. Trigger sync
    _syncManager.processQueue();

    return offlineAnimal;
  }

  Future<void> slaughterAnimal(int animalId) async {
    // This is a state change.
    // Simplified: optimistic update local, queue remote.
    final localAnimal = (await _db.getAnimals()).firstWhere(
      (a) => a.id == animalId,
    );
    final updatedAnimal = localAnimal.copyWith(
      slaughtered: true,
      slaughteredAt: DateTime.now(),
    );

    await _db.insertAnimals([updatedAnimal], synced: false);

    await _db.addToSyncQueue(
      SyncQueueItem(
        endpoint: '${Constants.animalsEndpoint}$animalId/slaughter/',
        method: SyncMethod.POST,
        body: {
          'slaughtered_at': updatedAnimal.slaughteredAt?.toIso8601String(),
        },
        createdAt: DateTime.now(),
      ),
    );

    _syncManager.processQueue();
  }

  Future<void> deleteAnimal(int animalId) async {
    // Ideally we'd have a specific delete in DB helper
    await _db.addToSyncQueue(
      SyncQueueItem(
        endpoint: '${Constants.animalsEndpoint}$animalId/',
        method: SyncMethod.DELETE,
        body: {},
        createdAt: DateTime.now(),
      ),
    );
    _syncManager.processQueue();
  }

  Future<List<Animal>> getTransferredAnimals() async {
    return await _animalService.getTransferredAnimals();
  }

  Future<Map<String, dynamic>> transferAnimals(
    List<int?> ids,
    int unitId, {
    List<Map<String, dynamic>>? partTransfers,
  }) async {
    return await _animalService.transferAnimals(
      ids,
      unitId,
      partTransfers: partTransfers,
    );
  }

  Future<Map<String, dynamic>> receiveAnimals(
    List<int?> ids, {
    List<Map<String, dynamic>>? partReceives,
    List<Map<String, dynamic>>? animalRejections,
    List<Map<String, dynamic>>? partRejections,
  }) async {
    return await _animalService.receiveAnimals(
      ids,
      partReceives: partReceives,
      animalRejections: animalRejections,
      partRejections: partRejections,
    );
  }

  // Pass-through for complex operations that we might not want to fully offline yet
  Future<List<Animal>> getTransferredAnimalsForAbbatoir() async =>
      await _animalService.getTransferredAnimalsForAbbatoir();
  Future<List<Map<String, dynamic>>> getProcessingUnits() async =>
      await _animalService.getProcessingUnits();
  Future<void> createCarcassMeasurement(CarcassMeasurement m) async =>
      await _animalService.createCarcassMeasurement(m);

  // Slaughter Parts
  Future<Map<String, dynamic>> getSlaughterParts({
    int? animalId,
    SlaughterPartType? partType,
    String? search,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    return await _animalService.getSlaughterParts(
      animalId: animalId,
      partType: partType,
      search: search,
      ordering: ordering,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<List<SlaughterPart>> getSlaughterPartsList({
    int? animalId,
    SlaughterPartType? partType,
    String? search,
    String? ordering,
  }) async {
    return await _animalService.getSlaughterPartsList(
      animalId: animalId,
      partType: partType,
      search: search,
      ordering: ordering,
    );
  }

  Future<SlaughterPart> createSlaughterPart(SlaughterPart part) async =>
      await _animalService.createSlaughterPart(part);
  Future<SlaughterPart> updateSlaughterPart(SlaughterPart part) async =>
      await _animalService.updateSlaughterPart(part);
  Future<void> deleteSlaughterPart(int id) async =>
      await _animalService.deleteSlaughterPart(id);
  Future<Map<String, dynamic>> transferSlaughterParts(
    List<int?> ids,
    int unitId,
  ) async => await _animalService.transferSlaughterParts(ids, unitId);
  Future<Map<String, dynamic>> receiveSlaughterParts(List<int?> ids) async =>
      await _animalService.receiveSlaughterParts(ids);
}
