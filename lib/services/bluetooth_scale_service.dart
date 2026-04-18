import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Service to handle Bluetooth Scale connections and data reading
class BluetoothScaleService {
  static final BluetoothScaleService _instance =
      BluetoothScaleService._internal();

  factory BluetoothScaleService() {
    return _instance;
  }

  BluetoothScaleService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _weightCharacteristic;
  StreamSubscription? _connectionSubscription;

  // Stream controller for weight readings
  final _weightController = StreamController<double>.broadcast();
  Stream<double> get weightStream => _weightController.stream;

  // Connection state
  final _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;

  /// Start scanning for BLE devices
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // Check if Bluetooth is supported and on
    if (await FlutterBluePlus.isSupported == false) {
      debugPrint('Bluetooth not supported');
      return;
    }

    // Turn on Bluetooth if off (Android only)
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    // Start scanning
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Connect to a device
  Future<void> connect(BluetoothDevice device) async {
    await stopScan();

    try {
      // Note: flutter_blue_plus 2.0.0+ connect method signature
      await device.connect(license: License.free);
      _connectedDevice = device;

      // Listen to connection state changes
      _connectionSubscription = device.connectionState.listen((state) {
        _connectionStateController.add(state);
        if (state == BluetoothConnectionState.disconnected) {
          _cleanupConnection();
        }
      });

      // Discover services
      await _discoverServices(device);
    } catch (e) {
      debugPrint('Error connecting to scale: $e');
      _cleanupConnection();
      rethrow;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _cleanupConnection();
    }
  }

  void _cleanupConnection() {
    _connectedDevice = null;
    _weightCharacteristic = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
  }

  /// Manually trigger a weight read (for scales that support READ operation)
  Future<void> readWeight() async {
    if (_weightCharacteristic == null) {
      debugPrint('⚠️ [ScaleService] No characteristic available for reading');
      return;
    }

    try {
      if (_weightCharacteristic!.properties.read) {
        debugPrint('📖 [ScaleService] Performing manual READ...');
        List<int> value = await _weightCharacteristic!.read();
        debugPrint('📦 [ScaleService] Read data: $value');
        _parseWeightData(value);
      } else {
        debugPrint(
          '⚠️ [ScaleService] Characteristic does not support READ (NOTIFY-only scale)',
        );
        debugPrint(
          '💡 [ScaleService] Ensure weight is ON the scale and try changing it slightly',
        );

        // Check if notify is enabled
        bool isNotifying = _weightCharacteristic!.isNotifying;
        debugPrint(
          '🔔 [ScaleService] Notifications currently enabled: $isNotifying',
        );

        if (!isNotifying) {
          debugPrint('🔄 [ScaleService] Re-enabling notifications...');
          await _weightCharacteristic!.setNotifyValue(true);
        }
      }
    } catch (e) {
      debugPrint('❌ [ScaleService] Read failed: $e');
      rethrow;
    }
  }

  /// Discover services and find the weight characteristic
  Future<void> _discoverServices(BluetoothDevice device) async {
    debugPrint('🔍 [ScaleService] Discovering services...');
    List<BluetoothService> services = await device.discoverServices();
    debugPrint('🔍 [ScaleService] Found ${services.length} services');

    // First pass: Look for standard weight service
    for (var service in services) {
      debugPrint('  📦 Service UUID: ${service.uuid}');

      // Check for standard Weight Scale Service (0x181D)
      if (service.uuid.toString().toUpperCase().contains('181D')) {
        debugPrint('  ✅ Found Weight Scale Service!');
        for (var characteristic in service.characteristics) {
          debugPrint('    📝 Characteristic UUID: ${characteristic.uuid}');
          // Weight Measurement Characteristic (0x2A9D)
          if (characteristic.uuid.toString().toUpperCase().contains('2A9D')) {
            debugPrint('    ✅ Found Weight Measurement Characteristic!');
            await _setupNotification(characteristic);
            return;
          }
        }
      }
    }

    debugPrint(
      '\n⚠️ [ScaleService] Standard weight service not found. Scanning all characteristics...\n',
    );

    // Second pass: Log ALL characteristics and find suitable ones
    List<BluetoothCharacteristic> candidates = [];

    for (var service in services) {
      debugPrint('  📦 Service: ${service.uuid}');
      for (var characteristic in service.characteristics) {
        String uuid = characteristic.uuid.toString().toUpperCase();
        debugPrint('    📝 Char: $uuid');
        debugPrint(
          '       Properties: read=${characteristic.properties.read}, '
          'write=${characteristic.properties.write}, '
          'notify=${characteristic.properties.notify}, '
          'indicate=${characteristic.properties.indicate}',
        );

        // Skip known non-weight characteristics
        if (uuid.contains('2A05') || // Service Changed
            uuid.contains('2A00') || // Device Name
            uuid.contains('2A01') || // Appearance
            uuid.contains('2A04')) {
          // Peripheral Preferred Connection Parameters
          debugPrint('       ⏭️  Skipping (system characteristic)');
          continue;
        }

        // Look for notify/indicate characteristics (potential weight data)
        if (characteristic.properties.notify ||
            characteristic.properties.indicate) {
          debugPrint('       ⭐ CANDIDATE for weight data!');
          candidates.add(characteristic);
        }
      }
    }

    debugPrint(
      '\n🎯 [ScaleService] Found ${candidates.length} candidate characteristic(s)\n',
    );

    // Try the first suitable candidate
    if (candidates.isNotEmpty) {
      debugPrint(
        '🎯 [ScaleService] Using first candidate: ${candidates.first.uuid}',
      );
      await _setupNotification(candidates.first);
      return;
    }

    debugPrint('❌ [ScaleService] No suitable characteristic found!');
  }

  Future<void> _setupNotification(
    BluetoothCharacteristic characteristic,
  ) async {
    debugPrint(
      '🔔 [ScaleService] Setting up notification for ${characteristic.uuid}',
    );
    _weightCharacteristic = characteristic;

    try {
      await characteristic.setNotifyValue(true);
      debugPrint('✅ [ScaleService] Notifications enabled');

      characteristic.lastValueStream.listen((value) {
        debugPrint(
          '📦 [ScaleService] Received data: $value (length: ${value.length})',
        );
        _parseWeightData(value);
      });
    } catch (e) {
      debugPrint('❌ [ScaleService] Failed to enable notifications: $e');
    }
  }

  /// Parse raw bytes into weight value
  /// This logic depends heavily on the specific scale's protocol
  void _parseWeightData(List<int> data) {
    if (data.isEmpty) {
      debugPrint('⚠️ [ScaleService] Received empty data');
      return;
    }

    debugPrint('📊 [ScaleService] Parsing weight data: $data');

    try {
      // Strategy 1: ASCII text parsing (for scales like SZL that send "ST,GS,+00001.0kg")
      try {
        String dataStr = String.fromCharCodes(data);
        debugPrint('📝 [ScaleService] Data as string: "$dataStr"');

        // Try to extract number from string (handles formats like "+00001.0kg", "1.23 kg", etc.)
        RegExp numRegex = RegExp(r'([+-]?\d+\.?\d*)');
        Match? match = numRegex.firstMatch(dataStr);
        if (match != null) {
          double weight = double.parse(match.group(1)!);
          debugPrint('✅ [ScaleService] Parsed weight (ASCII): $weight kg');
          _weightController.add(weight);
          return;
        }
      } catch (e) {
        debugPrint('⚠️ [ScaleService] ASCII parsing failed: $e');
      }

      // Strategy 2: Standard GATT Weight Measurement (binary)
      if (data.length >= 3) {
        int flags = data[0];
        bool isImperial = (flags & 0x01) != 0;

        // Simple little-endian parsing
        int rawWeight = data[1] + (data[2] << 8);
        double weight = rawWeight / 100.0;

        if (isImperial) {
          weight = weight * 0.453592; // Convert lbs to kg
        }

        debugPrint('✅ [ScaleService] Parsed weight (GATT binary): $weight kg');
        _weightController.add(weight);
        return;
      }

      // Strategy 3: Raw interpretation (last resort)
      if (data.length >= 2) {
        int rawValue = data[0] + (data[1] << 8);
        double weight = rawValue / 10.0; // Assume 1 decimal place
        debugPrint('⚠️ [ScaleService] Parsed weight (raw guess): $weight kg');
        _weightController.add(weight);
        return;
      }

      debugPrint('❌ [ScaleService] Could not parse weight data');
    } catch (e) {
      debugPrint('❌ [ScaleService] Error parsing weight data: $e');
    }
  }
}
