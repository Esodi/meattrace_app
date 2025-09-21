import '../services/network_helper.dart';

class Constants {
  // API Configuration - Multiple options for different environments
  static const String localhostUrl = 'http://127.0.0.1:8000/api/v1';        // For emulator
  static const String emulatorUrl = 'http://10.0.2.2:8000/api/v1';         // Android emulator host
  static const String wifiUrl = 'http://192.168.161.17:8000/api/v1';       // Your WiFi IP - UPDATED
  static const String prodBaseUrl = 'https://your-production-api.com/api/v1';

  // Dynamic base URL - will be set at runtime
  static String? _dynamicBaseUrl;

  // Get base URL based on environment
  static String get baseUrl {
    // Use dynamic URL if available, otherwise fall back to localhost
    return _dynamicBaseUrl ?? localhostUrl;
  }

  // Set the base URL dynamically (called during app initialization)
  static void setBaseUrl(String url) {
    _dynamicBaseUrl = url;
  }

  // Initialize base URL by testing connectivity
  static Future<void> initializeBaseUrl() async {
    // First try the WiFi URL directly since we know the server is running there
    final wifiUrlWithoutApi = wifiUrl.replaceAll('/api/v1', '');
    try {
      final isWifiReachable = await NetworkHelper.testConnection('$wifiUrlWithoutApi/health/');
      if (isWifiReachable) {
        setBaseUrl(wifiUrl);
        return;
      }
    } catch (e) {
      // Continue to fallback
    }

    // Fallback to automatic detection
    final workingUrl = await NetworkHelper.findWorkingBaseUrl();
    if (workingUrl != null) {
      setBaseUrl(workingUrl);
    }
  }

  // API Endpoints
  static const String loginEndpoint = '/token/';
  static const String registerEndpoint = '/register/';
  static const String refreshTokenEndpoint = '/token/refresh/';
  static const String userProfileEndpoint = '/profile/';
  static const String animalsEndpoint = '/animals/';
  static const String productsEndpoint = '/products/';
  static const String receiptsEndpoint = '/receipts/';
  static const String processingUnitsEndpoint = '/processing-units/';
  static const String uploadEndpoint = '/upload/';
}
