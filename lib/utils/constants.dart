class Constants {
  // API Configuration - Fixed base URL for backend
  // static const String baseUrl = 'https://dev.shambabora.co.tz/api/v2';
  
  // For Physical Device via Bluetooth Network:
  static const String baseUrl = 'http://192.168.44.223:8000/api/v2';
  
  // Alternative IPs (uncomment the one you need):
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v2';            // Android Emulator
  // static const String baseUrl = 'http://localhost:8000/api/v2';           // USB with ADB reverse

  // API Endpoints
  static const String loginEndpoint = '/token/';
  static const String registerEndpoint = '/register/';
  static const String refreshTokenEndpoint = '/token/refresh/';
  static const String userProfileEndpoint = '/profile/';
  static const String animalsEndpoint = '/animals/';
  static const String carcassMeasurementsEndpoint = '/carcass-measurements/';
  static const String slaughterPartsEndpoint = '/slaughter-parts/';
  static const String productsEndpoint = '/products/';
  static const String receiptsEndpoint = '/receipts/';
  static const String inventoryEndpoint = '/inventory/';
  static const String processingUnitsEndpoint = '/processing-units/';
  static const String shopsEndpoint = '/shops/';
  static const String uploadEndpoint = '/upload/';
  static const String activitiesEndpoint = '/activities/';

  // User Management Endpoints
  static const String usersEndpoint = '/users/';
  static const String userInvitationEndpoint = '/users/invite/';
  static const String userAuditLogsEndpoint = '/users/audit-logs/';
  static const String joinRequestsEndpoint = '/join-requests/';
}







