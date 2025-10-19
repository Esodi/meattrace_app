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
  static const String _openMeteoBaseUrl = 'https://api.open-meteo.com/v1/forecast';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<WeatherData> getWeatherData() async {
    try {
      // Get current location
      final position = await _getCurrentPosition();

      // Fetch weather data from Open-Meteo API
      final response = await _dio.get(
        _openMeteoBaseUrl,
        queryParameters: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'current_weather': true,
          'hourly': 'soil_moisture_0_to_1cm',
          'timezone': 'auto',
        },
      );

      final data = response.data;
      final currentWeather = data['current_weather'];

      // Extract temperature and condition
      final temperature = currentWeather['temperature'].toDouble();
      final weatherCode = currentWeather['weathercode'];
      final condition = _getWeatherConditionFromCode(weatherCode);

      // Extract soil moisture from hourly data (first hour)
      final hourly = data['hourly'];
      final soilMoisture = hourly['soil_moisture_0_to_1cm'] != null && hourly['soil_moisture_0_to_1cm'].isNotEmpty
          ? (hourly['soil_moisture_0_to_1cm'][0] * 100).toDouble() // Convert to percentage
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

  String _getWeatherConditionFromCode(int code) {
    // Open-Meteo weather codes
    switch (code) {
      case 0: return 'Clear sky';
      case 1: return 'Mainly clear';
      case 2: return 'Partly cloudy';
      case 3: return 'Overcast';
      case 45: return 'Fog';
      case 48: return 'Depositing rime fog';
      case 51: return 'Light drizzle';
      case 53: return 'Moderate drizzle';
      case 55: return 'Dense drizzle';
      case 56: return 'Light freezing drizzle';
      case 57: return 'Dense freezing drizzle';
      case 61: return 'Slight rain';
      case 63: return 'Moderate rain';
      case 65: return 'Heavy rain';
      case 66: return 'Light freezing rain';
      case 67: return 'Heavy freezing rain';
      case 71: return 'Slight snow fall';
      case 73: return 'Moderate snow fall';
      case 75: return 'Heavy snow fall';
      case 77: return 'Snow grains';
      case 80: return 'Slight rain showers';
      case 81: return 'Moderate rain showers';
      case 82: return 'Violent rain showers';
      case 85: return 'Slight snow showers';
      case 86: return 'Heavy snow showers';
      case 95: return 'Thunderstorm';
      case 96: return 'Thunderstorm with slight hail';
      case 99: return 'Thunderstorm with heavy hail';
      default: return 'Unknown';
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
      location: 'Abbatoir Location',
      soilMoisture: 75.0,
    );
  }
}