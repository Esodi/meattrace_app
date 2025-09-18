import 'package:dio/dio.dart';
import '../models/animal.dart';
import 'dio_client.dart';
import '../utils/constants.dart';

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
      if (slaughtered != null) queryParams['slaughtered'] = slaughtered;
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _dioClient.dio.get(
        Constants.animalsEndpoint,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return {
          'results': data.map((json) => Animal.fromMap(json)).toList(),
          'count': data.length,
          'next': null,
          'previous': null,
        };
      } else if (data is Map && data.containsKey('results')) {
        return {
          'results': (data['results'] as List).map((json) => Animal.fromMap(json)).toList(),
          'count': data['count'],
          'next': data['next'],
          'previous': data['previous'],
        };
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch animals: ${e.message}');
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
      final response = await _dioClient.dio.get('${Constants.animalsEndpoint}$id/');
      return Animal.fromMap(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Animal not found');
      }
      throw Exception('Failed to fetch animal: ${e.message}');
    }
  }

  Future<Animal> createAnimal(Animal animal) async {
    try {
      final response = await _dioClient.dio.post(
        Constants.animalsEndpoint,
        data: animal.toMapForCreate(),
      );
      return Animal.fromMap(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to create animal: ${e.message}');
    }
  }

  Future<Animal> updateAnimal(Animal animal) async {
    try {
      final response = await _dioClient.dio.put(
        '${Constants.animalsEndpoint}${animal.id}/',
        data: animal.toMap(),
      );
      return Animal.fromMap(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update animal: ${e.message}');
    }
  }

  Future<void> deleteAnimal(int id) async {
    try {
      await _dioClient.dio.delete('${Constants.animalsEndpoint}$id/');
    } on DioException catch (e) {
      throw Exception('Failed to delete animal: ${e.message}');
    }
  }

  Future<Animal> slaughterAnimal(int id) async {
    try {
      final response = await _dioClient.dio.patch(
        '${Constants.animalsEndpoint}$id/slaughter/',
      );
      return Animal.fromMap(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to slaughter animal: ${e.message}');
    }
  }
}
