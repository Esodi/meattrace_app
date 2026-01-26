import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../utils/constants.dart';

class NetworkHelper {
  /// Generate test URLs based on environment and network conditions
  static List<String> get testUrls {
    final baseUrls = [
      'http://127.0.0.1:8000', // Localhost (highest priority for development)
      'http://10.0.2.2:8000', // Android emulator
      'http://192.168.1.1:8000', // Common router IP
    ];

    // Add local network IPs if available
    _addLocalNetworkIPs(baseUrls);

    // Convert to health check URLs
    return baseUrls.map((url) => '$url/api/v2/health/').toList();
  }

  /// Add local network IP addresses to the test list
  static void _addLocalNetworkIPs(List<String> baseUrls) {
    try {
      // Common development IPs that might be used
      const commonDevIPs = [
        '192.168.254.17', // WiFi IP (from original code)
        '192.168.44.223', // From constants.dart
        '192.168.1.100', // Common development IP
      ];

      for (var ip in commonDevIPs) {
        if (!baseUrls.contains('http://$ip:8000')) {
          baseUrls.add('http://$ip:8000');
        }
      }
    } catch (e) {
      developer.log('Error adding local network IPs: $e');
    }
  }

  /// Test connectivity to multiple backend URLs and return the first working one
  static Future<String?> findWorkingBaseUrl() async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );

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
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

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

  /// Test connection using the configured base URL from Constants
  static Future<bool> testConfiguredConnection() async {
    final baseUrl = Constants.baseUrl.replaceAll('/api/v2', '');
    final healthUrl = '$baseUrl/api/v2/health/';
    return testConnection(healthUrl);
  }

  /// Get the primary backend URL (either from Constants or first working test URL)
  static Future<String?> getPrimaryBackendUrl() async {
    // First try the configured URL
    if (await testConfiguredConnection()) {
      return Constants.baseUrl;
    }

    // Fallback to finding a working URL from test URLs
    return await findWorkingBaseUrl();
  }

  /// Print network diagnostics to console
  static Future<void> printNetworkDiagnostics() async {
    developer.log('=== NETWORK DIAGNOSTICS ===');
    final diagnostics = await getNetworkDiagnostics();

    developer.log('Device IP: ${diagnostics['deviceIp'] ?? 'Unknown'}');
    developer.log('Configured Base URL: ${Constants.baseUrl}');
    developer.log('Backend Connectivity Tests:');

    for (var url in testUrls) {
      final status = diagnostics[url] == true ? '✅ REACHABLE' : '❌ UNREACHABLE';
      developer.log('  $url - $status');
    }

    developer.log('=== END DIAGNOSTICS ===');
  }
}
