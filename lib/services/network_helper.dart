import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;

class NetworkHelper {
  static const List<String> testUrls = [
    'http://192.168.150.17:8000/api/v1/health/',  // WiFi IP
    'http://10.0.2.2:8000/api/v1/health/',     // Android emulator
    'http://127.0.0.1:8000/api/v1/health/',    // Localhost
    'http://192.168.1.1:8000/api/v1/health/',  // Common router IP
  ];

  /// Test connectivity to multiple backend URLs and return the first working one
  static Future<String?> findWorkingBaseUrl() async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));

    for (String url in testUrls) {
      try {
        developer.log('Testing connectivity to: $url');
        final response = await dio.get(url);
        
        if (response.statusCode == 200) {
          final baseUrl = url.replaceAll('/health/', '');
          developer.log('✅ Successfully connected to: $baseUrl');
          return baseUrl;
        }
      } catch (e) {
        developer.log('❌ Failed to connect to: $url - Error: $e');
        continue;
      }
    }
    
    developer.log('❌ No working backend URL found');
    return null;
  }

  /// Get the local IP address of the device
  static Future<String?> getLocalIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            developer.log('Device IP: ${addr.address}');
            return addr.address;
          }
        }
      }
    } catch (e) {
      developer.log('Error getting local IP: $e');
    }
    return null;
  }

  /// Test if a specific URL is reachable
  static Future<bool> testConnection(String url) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      
      final response = await dio.get(url);
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Connection test failed for $url: $e');
      return false;
    }
  }

  /// Get network diagnostics information
  static Future<Map<String, dynamic>> getNetworkDiagnostics() async {
    final diagnostics = <String, dynamic>{};
    
    // Get device IP
    diagnostics['deviceIp'] = await getLocalIpAddress();
    
    // Test each URL
    for (String url in testUrls) {
      final isReachable = await testConnection(url);
      diagnostics[url] = isReachable;
    }
    
    return diagnostics;
  }

  /// Print network diagnostics to console
  static Future<void> printNetworkDiagnostics() async {
    developer.log('=== NETWORK DIAGNOSTICS ===');
    final diagnostics = await getNetworkDiagnostics();
    
    developer.log('Device IP: ${diagnostics['deviceIp'] ?? 'Unknown'}');
    developer.log('Backend Connectivity Tests:');
    
    testUrls.forEach((url) {
      final status = diagnostics[url] == true ? '✅ REACHABLE' : '❌ UNREACHABLE';
      developer.log('  $url - $status');
    });
    
    developer.log('=== END DIAGNOSTICS ===');
  }
}