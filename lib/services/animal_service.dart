import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../utils/constants.dart';
import 'dio_client.dart';

// Add slaughter parts endpoint constant
const String slaughterPartsEndpoint = '/slaughter-parts/';

class AnimalService {
  static final AnimalService _instance = AnimalService._internal();
  final DioClient _dioClient = DioClient();

  factory AnimalService() {
    return _instance;
  }

  AnimalService._internal();

  Future<Map<String, dynamic>> getAnimals({
    String? species,
    bool? slaughtered,
    String? search,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (species != null) queryParams['species'] = species;
      // Only add slaughtered param if it's explicitly set (not null)
      if (slaughtered != null) {
        queryParams['slaughtered'] = slaughtered.toString();
      }
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (page != null) queryParams['page'] = page;
      // Set a large page size to get all animals (or use the provided pageSize)
      queryParams['page_size'] = pageSize ?? 1000;

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📡 ANIMAL_SERVICE - GET_ANIMALS REQUEST');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔵 Endpoint: ${Constants.animalsEndpoint}');
      print('🔵 Query params: $queryParams');
      print('🔵 Full URL: ${Constants.baseUrl}${Constants.animalsEndpoint}');

      // Get current auth token for debugging
      final dio = _dioClient.dio;
      final authHeader = dio.options.headers['Authorization'];
      if (authHeader != null) {
        print(
          '🔵 Auth header present: ${authHeader.toString().substring(0, 30)}...',
        );
      } else {
        print('⚠️ WARNING: No auth header!');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await _dioClient.dio.get(
        Constants.animalsEndpoint,
        queryParameters: queryParams,
      );

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📡 ANIMAL_SERVICE - GET_ANIMALS RESPONSE');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ Response status: ${response.statusCode}');
      print('📦 RAW DATA: ${response.data}');

      final data = response.data;

      if (data is Map) {
        print('📋 Response is Map with keys: ${data.keys.toList()}');
        if (data.containsKey('count')) {
          print('📊 Total count from server: ${data['count']}');
        }
        if (data.containsKey('results')) {
          final resultsList = data['results'] as List;
          print('📦 Results array length: ${resultsList.length}');
          // Log each animal ID and animal_id for debugging
          for (var i = 0; i < resultsList.length; i++) {
            final animalData = resultsList[i];
            print(
              '   [$i] ID: ${animalData['id']}, Tag: ${animalData['animal_id']}, Species: ${animalData['species']}, Abbatoir: ${animalData['abbatoir']}',
            );
          }
        }
      } else if (data is List) {
        print('📦 Response is List with length: ${data.length}');
        for (var i = 0; i < data.length; i++) {
          final animalData = data[i];
          print(
            '   [$i] ID: ${animalData['id']}, Tag: ${animalData['animal_id']}, Species: ${animalData['species']}, Abbatoir: ${animalData['abbatoir']}',
          );
        }
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Handle both paginated and unpaginated responses
      if (data is List) {
        // Direct list response (no pagination)
        print('🔄 PARSING ANIMALS FROM LIST (UNPAGINATED)');
        final animals = <Animal>[];
        for (var i = 0; i < data.length; i++) {
          try {
            animals.add(Animal.fromMap(data[i]));
          } catch (e) {
            print('❌ Parse error at index $i: $e');
            print('❌ Problematic data: ${data[i]}');
            continue;
          }
        }
        return {
          'results': animals,
          'count': animals.length,
          'next': null,
          'previous': null,
        };
      } else if (data is Map && data.containsKey('results')) {
        final resultsList = data['results'] as List;
        print('🔄 PARSING ANIMALS FROM PAGINATED RESPONSE');
        final animals = <Animal>[];
        for (var i = 0; i < resultsList.length; i++) {
          try {
            animals.add(Animal.fromMap(resultsList[i]));
          } catch (e) {
            print('❌ Parse error at index $i: $e');
            print('❌ Problematic data: ${resultsList[i]}');
            continue;
          }
        }
        return {
          'results': animals,
          'count': data['count'],
          'next': data['next'],
          'previous': data['previous'],
        };
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print('❌ ANIMAL_SERVICE - GET_ANIMALS ERROR: $e');
      throw Exception('Failed to fetch animals: $e');
    }
  }

  // For backward compatibility
  Future<List<Animal>> getAnimalsList({
    String? species,
    bool? slaughtered,
    String? search,
    String? ordering,
  }) async {
    final result = await getAnimals(
      species: species,
      slaughtered: slaughtered,
      search: search,
      ordering: ordering,
    );
    return result['results'] as List<Animal>;
  }

  Future<Animal> getAnimal(int id) async {
    try {
      final response = await _dioClient.dio.get(
        '${Constants.animalsEndpoint}$id/',
      );
      return Animal.fromMap(response.data);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        throw Exception('Animal not found');
      }
      throw Exception('Failed to fetch animal: $e');
    }
  }

  Future<Animal> createAnimal(Animal animal, {File? photo}) async {
    try {
      print('AnimalService.createAnimal - Starting animal creation');
      print(
        'Animal data: species=${animal.species}, age=${animal.age}, abbatoir=${animal.abbatoirName}',
      );
      print('Photo provided: ${photo != null}');

      final formData = FormData.fromMap(animal.toMapForCreate());

      // Add photo if provided
      if (photo != null) {
        final fileName = photo.path.split('/').last;
        formData.files.add(
          MapEntry(
            'photo',
            await MultipartFile.fromFile(photo.path, filename: fileName),
          ),
        );
        print('Photo added to form data: $fileName');
      }

      print('Making POST request to ${Constants.animalsEndpoint}');
      final response = await _dioClient.dio.post(
        Constants.animalsEndpoint,
        data: formData,
      );
      print('Response received: status=${response.statusCode}');
      print('Response data: ${response.data}');
      return Animal.fromMap(response.data);
    } catch (e) {
      print('AnimalService.createAnimal - Exception occurred: $e');
      print('Exception type: ${e.runtimeType}');
      if (e is DioException) {
        print('DioException details:');
        print('  - Status code: ${e.response?.statusCode}');
        print('  - Response data: ${e.response?.data}');
        print('  - Request URL: ${e.requestOptions.uri}');
        print('  - Request method: ${e.requestOptions.method}');
        print('  - Request data: ${e.requestOptions.data}');
      }
      throw Exception('Failed to create animal: $e');
    }
  }

  Future<Animal> updateAnimal(Animal animal) async {
    try {
      final response = await _dioClient.dio.put(
        '${Constants.animalsEndpoint}${animal.id}/',
        data: animal.toMap(),
      );
      return Animal.fromMap(response.data);
    } catch (e) {
      throw Exception('Failed to update animal: $e');
    }
  }

  Future<void> deleteAnimal(int id) async {
    try {
      await _dioClient.dio.delete('${Constants.animalsEndpoint}$id/');
    } catch (e) {
      throw Exception('Failed to delete animal: $e');
    }
  }

  Future<Animal> slaughterAnimal(int id) async {
    try {
      final response = await _dioClient.dio.patch(
        '${Constants.animalsEndpoint}$id/slaughter/',
      );
      return Animal.fromMap(response.data);
    } catch (e) {
      throw Exception('Failed to slaughter animal: $e');
    }
  }

  Future<Map<String, dynamic>> transferAnimals(
    List<int?> animalIds,
    int processingUnitId, {
    List<Map<String, dynamic>>? partTransfers,
  }) async {
    try {
      final filteredAnimalIds = animalIds.where((id) => id != null).toList();
      print(
        'SERVICE_TRANSFER_START - Filtered Animal IDs: $filteredAnimalIds, Processing Unit ID: $processingUnitId',
      );

      final requestData = <String, dynamic>{
        'processing_unit_id': processingUnitId,
      };

      // Add animal_ids only if there are whole animal transfers
      if (filteredAnimalIds.isNotEmpty) {
        requestData['animal_ids'] = filteredAnimalIds;
      }

      // Add part_transfers if provided (for split carcass workflow)
      if (partTransfers != null && partTransfers.isNotEmpty) {
        requestData['part_transfers'] = partTransfers;
        print(
          'SERVICE_TRANSFER_PART_TRANSFERS - Part transfers: $partTransfers',
        );
      }

      print('SERVICE_TRANSFER_REQUEST_DATA - Data: $requestData');

      final response = await _dioClient.dio.post(
        '${Constants.animalsEndpoint}transfer/',
        data: requestData,
      );

      print(
        'SERVICE_TRANSFER_SUCCESS - Status: ${response.statusCode}, Response: ${response.data}',
      );
      return response.data;
    } catch (e) {
      print('SERVICE_TRANSFER_ERROR - Exception: $e');
      print('SERVICE_TRANSFER_ERROR_TYPE - Type: ${e.runtimeType}');
      if (e is DioException) {
        print(
          'SERVICE_TRANSFER_DIO_ERROR - Status: ${e.response?.statusCode}, Response: ${e.response?.data}',
        );
        print(
          'SERVICE_TRANSFER_DIO_ERROR_REQUEST - URL: ${e.requestOptions.uri}',
        );
        print(
          'SERVICE_TRANSFER_DIO_ERROR_REQUEST_METHOD - Method: ${e.requestOptions.method}',
        );
        print(
          'SERVICE_TRANSFER_DIO_ERROR_REQUEST_DATA - Data: ${e.requestOptions.data}',
        );
        print(
          'SERVICE_TRANSFER_DIO_ERROR_REQUEST_HEADERS - Headers: ${e.requestOptions.headers}',
        );
      }
      throw Exception('Failed to transfer animals: $e');
    }
  }

  Future<List<Animal>> getTransferredAnimals() async {
    debugPrint('🔍 [AnimalService] getTransferredAnimals called');
    try {
      debugPrint(
        '🔍 [AnimalService] Making GET request to ${Constants.animalsEndpoint}transferred_animals/',
      );
      final response = await _dioClient.dio.get(
        '${Constants.animalsEndpoint}transferred_animals/',
      );
      debugPrint('🔍 [AnimalService] Response status: ${response.statusCode}');
      debugPrint(
        '🔍 [AnimalService] Response data type: ${response.data.runtimeType}',
      );
      debugPrint('🔍 [AnimalService] Raw response data: ${response.data}');

      final data = response.data;
      List<Animal> animals = [];

      if (data is Map && data.containsKey('animals')) {
        debugPrint('🔍 [AnimalService] Response is Map with animals key');
        final animalsData = data['animals'] as List;
        debugPrint(
          '🔍 [AnimalService] Animals list has ${animalsData.length} items',
        );
        animals = animalsData.map((json) => Animal.fromMap(json)).toList();
        debugPrint('🔍 [AnimalService] Count from response: ${data['count']}');
      } else if (data is List) {
        debugPrint(
          '🔍 [AnimalService] Response is List with ${data.length} items',
        );
        animals = data.map((json) => Animal.fromMap(json)).toList();
      } else if (data is Map && data.containsKey('results')) {
        debugPrint('🔍 [AnimalService] Response is Map with results key');
        final results = data['results'] as List;
        debugPrint(
          '🔍 [AnimalService] Results list has ${results.length} items',
        );
        animals = results.map((json) => Animal.fromMap(json)).toList();
      } else {
        debugPrint('🔍 [AnimalService] Unexpected response format: $data');
        throw Exception('Unexpected response format: $data');
      }

      debugPrint(
        '🔍 [AnimalService] Successfully parsed ${animals.length} animals',
      );
      return animals;
    } catch (e) {
      debugPrint('🔍 [AnimalService] Error in getTransferredAnimals: $e');
      throw Exception('Failed to fetch transferred animals: $e');
    }
  }

  Future<List<Animal>> getTransferredAnimalsForFarmer() async {
    try {
      final response = await _dioClient.dio.get(
        '${Constants.animalsEndpoint}my_transferred_animals/',
      );

      final data = response.data;
      if (data is List) {
        return data.map((json) => Animal.fromMap(json)).toList();
      } else if (data is Map && data.containsKey('results')) {
        return (data['results'] as List)
            .map((json) => Animal.fromMap(json))
            .toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Failed to fetch transferred animals for abbatoir: $e');
    }
  }

  Future<Map<String, dynamic>> receiveAnimals(
    List<int?> animalIds, {
    List<Map<String, dynamic>>? partReceives,
    List<Map<String, dynamic>>? animalRejections,
    List<Map<String, dynamic>>? partRejections,
  }) async {
    try {
      final requestData = <String, dynamic>{};

      // Add animal_ids only if there are whole animal receives
      final filteredAnimalIds = animalIds.where((id) => id != null).toList();
      if (filteredAnimalIds.isNotEmpty) {
        requestData['animal_ids'] = filteredAnimalIds;
      }

      // Add part_receives if provided (for split carcass workflow)
      if (partReceives != null && partReceives.isNotEmpty) {
        requestData['part_receives'] = partReceives;
        print('SERVICE_RECEIVE_PART_RECEIVES - Part receives: $partReceives');
      }

      // Add animal rejections if provided
      if (animalRejections != null && animalRejections.isNotEmpty) {
        requestData['animal_rejections'] = animalRejections;
        print(
          'SERVICE_RECEIVE_ANIMAL_REJECTIONS - Animal rejections: $animalRejections',
        );
      }

      // Add part rejections if provided
      if (partRejections != null && partRejections.isNotEmpty) {
        requestData['part_rejections'] = partRejections;
        print(
          'SERVICE_RECEIVE_PART_REJECTIONS - Part rejections: $partRejections',
        );
      }

      print('SERVICE_RECEIVE_REQUEST_DATA - Data: $requestData');

      final response = await _dioClient.dio.post(
        '${Constants.animalsEndpoint}receive_animals/',
        data: requestData,
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to receive animals: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProcessingUnits() async {
    try {
      final response = await _dioClient.dio.get(
        Constants.processingUnitsEndpoint,
      );

      final data = response.data;
      if (data is Map && data.containsKey('results')) {
        // Transform ProcessingUnit entities to the expected format for farmers
        final processingUnits = List<Map<String, dynamic>>.from(
          data['results'],
        );
        return processingUnits.map((pu) {
          // Add null safety checks for the owner field
          final owner = pu['owner'];
          if (owner == null || owner is! Map<String, dynamic>) {
            // If owner is null or not a map, skip this processing unit or provide default values
            return {
              'id': pu['id'] ?? 0,
              'username': pu['name'] ?? 'Unknown Processing Unit',
              'email': 'N/A',
              'role': 'ProcessingUnit',
              'processing_unit_name': pu['name'] ?? 'Unknown',
              'processing_unit_id': pu['id'] ?? 0,
            };
          }

          return {
            'id': owner['id'] ?? pu['id'] ?? 0,
            'username':
                owner['username'] ?? pu['name'] ?? 'Unknown Processing Unit',
            'email': owner['email'] ?? 'N/A',
            'role': 'ProcessingUnit',
            'processing_unit_name': pu['name'] ?? 'Unknown',
            'processing_unit_id': pu['id'] ?? 0,
          };
        }).toList();
      } else if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Failed to fetch processing units: $e');
    }
  }

  Future<CarcassMeasurement> createCarcassMeasurement(
    CarcassMeasurement measurement,
  ) async {
    final timestamp = DateTime.now().toIso8601String();
    print(
      '[$timestamp] ANIMAL_SERVICE_CARCASS_MEASUREMENT_CREATE_START - Animal ID: ${measurement.animalId}, Carcass Type: ${measurement.carcassType.name}',
    );

    try {
      final requestData = measurement.toMapForCreate();
      print(
        '[$timestamp] ANIMAL_SERVICE_CARCASS_MEASUREMENT_DATA_PREP - Request data prepared: $requestData',
      );
      print(
        '[$timestamp] ANIMAL_SERVICE_CARCASS_MEASUREMENT_MEASUREMENTS - Measurements count: ${measurement.measurements.length}',
      );

      for (final entry in measurement.measurements.entries) {
        print(
          '[$timestamp] ANIMAL_SERVICE_CARCASS_MEASUREMENT_DETAIL - Field: ${entry.key}, Value: ${entry.value['value']}, Unit: ${entry.value['unit']}',
        );
      }

      print(
        '[$timestamp] ANIMAL_SERVICE_CARCASS_MEASUREMENT_API_CALL_START - Making POST request to ${Constants.carcassMeasurementsEndpoint}',
      );
      // Increase timeout for carcass measurement API call
      final dioExtended = _dioClient.dio;
      dioExtended.options.connectTimeout = const Duration(seconds: 60);
      dioExtended.options.sendTimeout = const Duration(seconds: 60);
      dioExtended.options.receiveTimeout = const Duration(seconds: 60);
      final response = await dioExtended.post(
        Constants.carcassMeasurementsEndpoint,
        data: requestData,
      );

      print(
        '[$timestamp] ANIMAL_SERVICE_CARCASS_MEASUREMENT_API_CALL_SUCCESS - Response status: ${response.statusCode}',
      );
      print(
        '[$timestamp] ANIMAL_SERVICE_CARCASS_MEASUREMENT_RESPONSE_DATA - Response data: ${response.data}',
      );

      final createdMeasurement = CarcassMeasurement.fromMap(response.data);
      print(
        '[$timestamp] ANIMAL_SERVICE_CARCASS_MEASUREMENT_OBJECT_CREATED - Created measurement ID: ${createdMeasurement.id}',
      );

      return createdMeasurement;
    } catch (e) {
      print(
        '[$timestamp] ANIMAL_SERVICE_CARCASS_MEASUREMENT_ERROR - Exception occurred: $e',
      );
      print(
        '[$timestamp] ANIMAL_SERVICE_CARCASS_MEASUREMENT_ERROR_TYPE - Exception type: ${e.runtimeType}',
      );

      if (e is DioException) {
        print(
          '[$timestamp] ANIMAL_SERVICE_CARCASS_MEASUREMENT_DIO_ERROR - DioException details:',
        );
        print('  - Status code: ${e.response?.statusCode}');
        print('  - Response data: ${e.response?.data}');
        print('  - Request URL: ${e.requestOptions.uri}');
        print('  - Request method: ${e.requestOptions.method}');
        print('  - Request data: ${e.requestOptions.data}');
      }

      throw Exception('Failed to create carcass measurement: $e');
    }
  }

  Future<CarcassMeasurement?> getCarcassMeasurementForAnimal(
    int animalId,
  ) async {
    try {
      final response = await _dioClient.dio.get(
        Constants.carcassMeasurementsEndpoint,
        queryParameters: {'animal': animalId},
      );

      final data = response.data;
      if (data is Map &&
          data.containsKey('results') &&
          (data['results'] as List).isNotEmpty) {
        return CarcassMeasurement.fromMap((data['results'] as List).first);
      } else if (data is List && data.isNotEmpty) {
        return CarcassMeasurement.fromMap(data.first);
      } else {
        return null; // No carcass measurement found
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return null; // No carcass measurement found
      }
      throw Exception('Failed to fetch carcass measurement: $e');
    }
  }

  Future<CarcassMeasurement> updateCarcassMeasurement(
    CarcassMeasurement measurement,
  ) async {
    try {
      final response = await _dioClient.dio.put(
        '${Constants.carcassMeasurementsEndpoint}${measurement.id}/',
        data: measurement.toMap(),
      );
      return CarcassMeasurement.fromMap(response.data);
    } catch (e) {
      throw Exception('Failed to update carcass measurement: $e');
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
      final queryParams = <String, dynamic>{};
      if (animalId != null) queryParams['animal'] = animalId;
      if (partType != null) queryParams['part_type'] = partType.value;
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _dioClient.dio.get(
        slaughterPartsEndpoint,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return {
          'results': data.map((json) => SlaughterPart.fromMap(json)).toList(),
          'count': data.length,
          'next': null,
          'previous': null,
        };
      } else if (data is Map && data.containsKey('results')) {
        return {
          'results': (data['results'] as List)
              .map((json) => SlaughterPart.fromMap(json))
              .toList(),
          'count': data['count'],
          'next': data['next'],
          'previous': data['previous'],
        };
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      throw Exception('Failed to fetch slaughter parts: $e');
    }
  }

  Future<List<SlaughterPart>> getSlaughterPartsList({
    int? animalId,
    SlaughterPartType? partType,
    String? search,
    String? ordering,
  }) async {
    final result = await getSlaughterParts(
      animalId: animalId,
      partType: partType,
      search: search,
      ordering: ordering,
    );
    return result['results'] as List<SlaughterPart>;
  }

  Future<SlaughterPart> getSlaughterPart(int id) async {
    try {
      final response = await _dioClient.dio.get('$slaughterPartsEndpoint$id/');
      return SlaughterPart.fromMap(response.data);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        throw Exception('Slaughter part not found');
      }
      throw Exception('Failed to fetch slaughter part: $e');
    }
  }

  Future<SlaughterPart> createSlaughterPart(SlaughterPart part) async {
    try {
      final response = await _dioClient.dio.post(
        slaughterPartsEndpoint,
        data: part.toMapForCreate(),
      );
      return SlaughterPart.fromMap(response.data);
    } catch (e) {
      throw Exception('Failed to create slaughter part: $e');
    }
  }

  Future<SlaughterPart> updateSlaughterPart(SlaughterPart part) async {
    try {
      final response = await _dioClient.dio.put(
        '$slaughterPartsEndpoint${part.id}/',
        data: part.toMap(),
      );
      return SlaughterPart.fromMap(response.data);
    } catch (e) {
      throw Exception('Failed to update slaughter part: $e');
    }
  }

  Future<void> deleteSlaughterPart(int id) async {
    try {
      await _dioClient.dio.delete('$slaughterPartsEndpoint$id/');
    } catch (e) {
      throw Exception('Failed to delete slaughter part: $e');
    }
  }

  Future<Map<String, dynamic>> transferSlaughterParts(
    List<int?> partIds,
    int processingUnitId,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        '${Constants.animalsEndpoint}transfer_parts/',
        data: {
          'part_ids': partIds.where((id) => id != null).toList(),
          'processing_unit_id': processingUnitId,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to transfer slaughter parts: $e');
    }
  }

  Future<Map<String, dynamic>> receiveSlaughterParts(List<int?> partIds) async {
    try {
      final response = await _dioClient.dio.post(
        '${Constants.animalsEndpoint}receive_parts/',
        data: {'part_ids': partIds.where((id) => id != null).toList()},
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to receive slaughter parts: $e');
    }
  }
}
