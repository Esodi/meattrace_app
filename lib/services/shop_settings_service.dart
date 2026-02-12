import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shop_settings.dart';
import '../utils/auth_utils.dart';
import '../utils/constants.dart';

class ShopSettingsService {
  static const String baseUrl = '${Constants.baseUrl}/shop-settings';

  // Get shop settings
  Future<ShopSettings?> getMySettings() async {
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.get(
      Uri.parse('$baseUrl/my_settings/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return ShopSettings.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load settings: ${response.body}');
    }
  }

  // Create shop settings
  Future<ShopSettings> createSettings(ShopSettings settings) async {
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.post(
      Uri.parse('$baseUrl/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(settings.toJson()),
    );

    if (response.statusCode == 201) {
      return ShopSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create settings: ${response.body}');
    }
  }

  // Update shop settings
  Future<ShopSettings> updateSettings(int id, ShopSettings settings) async {
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.put(
      Uri.parse('$baseUrl/$id/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(settings.toJson()),
    );

    if (response.statusCode == 200) {
      return ShopSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update settings: ${response.body}');
    }
  }

  // Partial update (PATCH)
  Future<ShopSettings> partialUpdate(int id, Map<String, dynamic> data) async {
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.patch(
      Uri.parse('$baseUrl/$id/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return ShopSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update settings: ${response.body}');
    }
  }
}
