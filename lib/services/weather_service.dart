import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class WeatherData {
  final double temperature;
  final String condition;
  final String location;
  final double soilMoisture; // in percentage

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.location,
    required this.soilMoisture,
  });
}

class WeatherService {
  static const String _openWeatherApiKey = 'YOUR_OPENWEATHER_API_KEY'; // Replace with actual key
  static const String _openWeatherBaseUrl = 'https://api.openweathermap.org/data/3.0/onecall';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<WeatherData> getWeatherData() async {
    try {
      // Get current location
      final position = await _getCurrentPosition();

      // Fetch weather data from OpenWeatherMap One Call API
      final response = await _dio.get(
        _openWeatherBaseUrl,
        queryParameters: {
          'lat': position.latitude,
          'lon': position.longitude,
          'exclude': 'minutely,daily,alerts',
          'units': 'metric',
          'appid': _openWeatherApiKey,
        },
      );

      final data = response.data;
      final current = data['current'];

      // Extract temperature and condition
      final temperature = current['temp'].toDouble();
      final weather = current['weather'][0];
      final condition = weather['main'];

      // Extract soil moisture from hourly data (first hour)
      final hourly = data['hourly'][0];
      final soilMoisture = hourly['soil_moisture'] != null
          ? (hourly['soil_moisture'] * 100).toDouble() // Convert to percentage
          : 75.0; // Default if not available

      // Get location name (simplified)
      final location = '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';

      return WeatherData(
        temperature: temperature,
        condition: condition,
        location: location,
        soilMoisture: soilMoisture,
      );
    } catch (e) {
      // Return mock data on error
      return _getMockWeatherData();
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  WeatherData _getMockWeatherData() {
    return WeatherData(
      temperature: 28.0,
      condition: 'Sunny',
      location: 'Farm Location',
      soilMoisture: 75.0,
    );
  }
}