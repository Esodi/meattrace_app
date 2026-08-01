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

  /// Reset stability debounce so the next reading is treated as the first sample.
  /// Call this before starting a new weight capture session.
  void resetStability() {
    _lastParsedWeight = null;
    _lastWeightTime = null;
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

  // Last stable weight value for debounce check
  double? _lastParsedWeight;
  DateTime? _lastWeightTime;

  /// Parse raw bytes into weight value
  /// This logic depends heavily on the specific scale's protocol
  void _parseWeightData(List<int> data) {
    if (data.isEmpty) {
      debugPrint('⚠️ [ScaleService] Received empty data');
      return;
    }

    debugPrint('📊 [ScaleService] Parsing weight data: $data');

    try {
      double? weight;

      // Strategy 1: ASCII text parsing — ONLY when all bytes are printable ASCII.
      // Guards against binary GATT data being misread as digit characters, which
      // produced spurious values like 257.30 from byte sequences that contained
      // ASCII digit codes by coincidence.
      bool isPrintableAscii = data.every(
        (b) => (b >= 0x20 && b <= 0x7E) || b == 0x0D || b == 0x0A,
      );
      if (isPrintableAscii) {
        String dataStr = String.fromCharCodes(data);
        debugPrint('📝 [ScaleService] Data as ASCII string: "$dataStr"');

        // Require at least one digit; decimal point required to avoid matching
        // raw integer byte values that sneak through (e.g. protocol headers).
        RegExp numRegex = RegExp(r'([+-]?\d+\.\d+)');
        Match? match = numRegex.firstMatch(dataStr);
        if (match != null) {
          weight = double.tryParse(match.group(1)!);
          if (weight != null) {
            debugPrint('✅ [ScaleService] Parsed weight (ASCII): $weight kg');
          }
        }
      }

      // Strategy 2: Standard GATT Weight Measurement (binary, 0x181D / 0x2A9D)
      if (weight == null && data.length >= 3) {
        int flags = data[0];
        bool isImperial = (flags & 0x01) != 0;
        int rawWeight = data[1] + (data[2] << 8); // little-endian
        double gattWeight = rawWeight / 100.0;
        if (isImperial) gattWeight *= 0.453592; // lbs → kg
        weight = gattWeight;
        debugPrint('✅ [ScaleService] Parsed weight (GATT binary): $weight kg');
      }

      // NOTE: A previous "Strategy 3" blindly reinterpreted any leftover
      // 2-byte fragment (e.g. a lone "\r\n" packet terminator split into its
      // own BLE notification) as a raw little-endian weight. That is how a
      // constant terminator byte pair [0x0D, 0x0A] was being decoded as
      // 257.3 kg on every zero-weight reading. There is no way to safely
      // guess a weight from an unrecognized fragment, so unparsed data is
      // now discarded instead of fabricating a number.
      if (weight == null) {
        debugPrint(
          '❌ [ScaleService] Could not parse weight data (ignoring fragment): $data',
        );
        return;
      }

      // Sanity check: reject physically impossible values. Zero is a valid,
      // meaningful reading (empty/tared platform) and must NOT be discarded
      // here — only genuinely impossible values (negative, absurdly large)
      // are rejected.
      if (weight < 0 || weight > 2000) {
        debugPrint(
          '⚠️ [ScaleService] Weight $weight kg out of valid range — discarded',
        );
        return;
      }

      // Stability debounce: only emit if the reading is consistent with the
      // previous one (within 0.5 kg) received within the last 2 seconds, or
      // if more than 2 seconds have passed since the last reading (new weight).
      final now = DateTime.now();
      final isStable = _lastParsedWeight != null &&
          _lastWeightTime != null &&
          now.difference(_lastWeightTime!).inMilliseconds < 2000 &&
          (weight - _lastParsedWeight!).abs() <= 0.5;

      _lastParsedWeight = weight;
      _lastWeightTime = now;

      if (isStable) {
        debugPrint('📤 [ScaleService] Stable weight confirmed: $weight kg');
        _weightController.add(weight);
      } else {
        debugPrint(
          '⏳ [ScaleService] First reading $weight kg — waiting for stable confirmation',
        );
      }
    } catch (e) {
      debugPrint('❌ [ScaleService] Error parsing weight data: $e');
    }
  }
}
