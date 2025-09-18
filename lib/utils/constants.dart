import '../services/network_helper.dart';

class Constants {
  // API Configuration - Multiple options for different environments
  static const String localhostUrl = 'http://127.0.0.1:8000/api/v1';        // For emulator
  static const String emulatorUrl = 'http://10.0.2.2:8000/api/v1';         // Android emulator host
  static const String wifiUrl = 'http://10.36.40.17:8000/api/v1';          // Your WiFi IP
  static const String prodBaseUrl = 'https://your-production-api.com/api/v1';

  // Dynamic base URL - will be set at runtime
  static String? _dynamicBaseUrl;

  // Get base URL based on environment
  static String get baseUrl {
    // Pinned to WiFi IP for this build
    return wifiUrl;
  }

  // Set the base URL dynamically (called during app initialization)
  static void setBaseUrl(String url) {
    _dynamicBaseUrl = url;
  }

  // Initialize base URL by testing connectivity
  static Future<void> initializeBaseUrl() async {
    final workingUrl = await NetworkHelper.findWorkingBaseUrl();
    if (workingUrl != null) {
      setBaseUrl(workingUrl);
    }
  }

  // API Endpoints
  static const String loginEndpoint = '/token/';
  static const String registerEndpoint = '/register/';
  static const String refreshTokenEndpoint = '/token/refresh/';
  static const String animalsEndpoint = '/animals/';
  static const String productsEndpoint = '/products/';
  static const String receiptsEndpoint = '/receipts/';
  static const String uploadEndpoint = '/upload/';
}
