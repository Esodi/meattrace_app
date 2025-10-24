import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
// url_launcher is not used here; removed to satisfy analyzer
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

class PrinterManager {
  BluetoothDevice? _currentDevice;
  BluetoothCharacteristic? _writeCharacteristic;

  Future<List<ScanResult>> scan() async {
    try {
      final results = <ScanResult>[];

      // Listen to scan results
      final subscription = FlutterBluePlus.scanResults.listen((scanResults) {
        results.clear();
        results.addAll(scanResults);
      });

      // Start scanning with timeout
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

      // Wait for scanning to complete
      await FlutterBluePlus.isScanning.where((scanning) => scanning == false).first;

      subscription.cancel();
      return results;
    } catch (e) {
      throw Exception('Failed to scan for devices: $e');
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    await device.connect(license: License.free);
    _currentDevice = device;

    // Discover services
    final services = await device.discoverServices();

    // Find the print service and characteristic
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
          _writeCharacteristic = characteristic;
          break;
        }
      }
      if (_writeCharacteristic != null) break;
    }

    if (_writeCharacteristic == null) {
      throw Exception('No writable characteristic found for printing');
    }
  }

  Future<void> disconnect() async {
    if (_currentDevice != null) {
      await _currentDevice!.disconnect();
      _currentDevice = null;
      _writeCharacteristic = null;
    }
  }

  Future<void> writeBytes(Uint8List bytes) async {
    if (_currentDevice != null && _writeCharacteristic != null) {
      try {
        const int chunkSize = 200; // Use smaller chunks to avoid MTU limits
        final totalBytes = bytes.length;
  debugPrint('📤 [PrinterManager] Writing $totalBytes bytes to printer in chunks of $chunkSize...');

        for (int i = 0; i < totalBytes; i += chunkSize) {
          final end = (i + chunkSize < totalBytes) ? i + chunkSize : totalBytes;
          final chunk = bytes.sublist(i, end);
          debugPrint('📤 [PrinterManager] Writing chunk ${i ~/ chunkSize + 1} (${chunk.length} bytes)...');

          await _writeCharacteristic!.write(chunk, withoutResponse: true);

          // Small delay between chunks to prevent overwhelming the printer
          if (end < totalBytes) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }

  debugPrint('✅ [PrinterManager] All bytes written successfully');
      } catch (e) {
  debugPrint('❌ [PrinterManager] Failed to write bytes: $e');
        // Reset connection state on write failure
        _currentDevice = null;
        _writeCharacteristic = null;
        throw Exception('Failed to write bytes to printer: $e');
      }
    } else {
      throw Exception('No printer connected');
    }
  }
}

class BluetoothPrintingService {
  static final BluetoothPrintingService _instance = BluetoothPrintingService._internal();
  factory BluetoothPrintingService() => _instance;
  BluetoothPrintingService._internal() {
    _initializePlugin();
  }

  PrinterManager? _printerManager;
  BluetoothDevice? _selectedPrinter;
  bool _isConnected = false;

  static const String _kSelectedPrinterKey = 'bt_selected_printer_remote_id';
  static const String _kSelectedPrinterNameKey = 'bt_selected_printer_name';

  void _initializePlugin() {
  debugPrint('🔧 [BluetoothPrintingService] Initializing flutter_blue_plus...');

    // Set log level for debugging
    FlutterBluePlus.setLogLevel(LogLevel.info, color: true);

  debugPrint('✅ [BluetoothPrintingService] Initialized with flutter_blue_plus - full control over Bluetooth connections');
  }

  PrinterManager get printerManager {
    _printerManager ??= PrinterManager();
    return _printerManager!;
  }

  bool get isConnected => _isConnected && _selectedPrinter != null;
  BluetoothDevice? get selectedPrinter => _selectedPrinter;

  /// Persist the selected printer remote id + name to shared preferences
  Future<void> saveSelectedPrinter(BluetoothDevice device) async {
    try {
      _selectedPrinter = device;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedPrinterKey, device.remoteId.toString());
    // prefer platformName (non-nullable in this SDK), fall back to remoteId string
    final name = device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString();
    await prefs.setString(_kSelectedPrinterNameKey, name);
    } catch (e) {
  debugPrint('❌ [BluetoothPrintingService] Failed to save selected printer: $e');
    }
  }

  Future<void> clearSavedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSelectedPrinterKey);
      await prefs.remove(_kSelectedPrinterNameKey);
      _selectedPrinter = null;
    } catch (e) {
  debugPrint('❌ [BluetoothPrintingService] Failed to clear saved printer: $e');
    }
  }

  Future<String?> getSavedPrinterId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kSelectedPrinterKey);
    } catch (e) {
      return null;
    }
  }

  /// Try to connect to the saved printer by scanning and matching remoteId.
  Future<bool> connectToSavedPrinter({int maxRetries = 3}) async {
    try {
      final savedId = await getSavedPrinterId();
      if (savedId == null) return false;

      final devices = await scanPrinters();
      try {
  // Match by remoteId or platformName (flutter_blue_plus). platformName is non-nullable.
  final match = devices.firstWhere((d) => d.remoteId.toString() == savedId || d.platformName.toString() == savedId);
        return await connectToPrinter(match, maxRetries: maxRetries);
      } catch (e) {
        debugPrint('⚠️ [BluetoothPrintingService] Saved printer not found during scan: $e');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [BluetoothPrintingService] Error connecting to saved printer: $e');
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
  debugPrint('🔐 [BluetoothPrintingService] Requesting Bluetooth permissions...');

      // Request permissions one by one for better error handling
      final bluetoothScan = await Permission.bluetoothScan.request();
  debugPrint('📡 Bluetooth scan permission: ${bluetoothScan.toString()}');

      final bluetoothConnect = await Permission.bluetoothConnect.request();
  debugPrint('🔗 Bluetooth connect permission: ${bluetoothConnect.toString()}');

      final location = await Permission.location.request();
  debugPrint('📍 Location permission: ${location.toString()}');

      // Check if location services are enabled (required for BLE scanning)
      final locationEnabled = await Permission.location.serviceStatus.isEnabled;
  debugPrint('📍 Location services enabled: $locationEnabled');

      final allGranted = bluetoothScan.isGranted && bluetoothConnect.isGranted && location.isGranted;
  debugPrint('✅ [BluetoothPrintingService] All permissions granted: $allGranted');

      return allGranted;
    } catch (e) {
  debugPrint('❌ [BluetoothPrintingService] Error requesting permissions: $e');
      return false;
    }
  }

  Future<void> openLocationSettings() async {
  debugPrint('🔧 [BluetoothPrintingService] Opening location settings...');
    try {
      await Geolocator.openLocationSettings();
  debugPrint('✅ [BluetoothPrintingService] Location settings opened');
    } catch (e) {
  debugPrint('❌ [BluetoothPrintingService] Failed to open location settings: $e');
      // Fallback to app settings
      try {
        await openAppSettings();
  debugPrint('✅ [BluetoothPrintingService] App settings opened as fallback');
      } catch (e2) {
  debugPrint('❌ [BluetoothPrintingService] Failed to open app settings: $e2');
      }
    }
  }

  Future<List<BluetoothDevice>> scanPrinters() async {
    try {
  debugPrint('🔍 [BluetoothPrintingService] Starting BLE printer scan (note: ESC/POS printers typically use Classic Bluetooth, not BLE)...');

      // Check if location services are enabled (required for BLE scanning)
      final locationEnabled = await Permission.location.serviceStatus.isEnabled;
      if (!locationEnabled) {
  debugPrint('⚠️ [BluetoothPrintingService] Location services are disabled. Opening location settings...');
        await openLocationSettings();
        throw Exception('Location services are required for Bluetooth scanning. Please enable location services and try again.');
      }

      // Check if Bluetooth is available and enabled
      if (!await FlutterBluePlus.isSupported) {
        throw Exception('Bluetooth is not supported on this device');
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
  debugPrint('📡 [BluetoothPrintingService] Bluetooth adapter state: $adapterState');
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('Bluetooth is not enabled. Please enable Bluetooth and try again.');
      }

      final scanResults = await printerManager.scan();
      // Convert ScanResult to BluetoothDevice, filtering for printers if possible
      final devices = scanResults.map((result) => result.device).toList();

  debugPrint('✅ [BluetoothPrintingService] Found ${devices.length} BLE devices');
      if (devices.isEmpty) {
  debugPrint('⚠️ [BluetoothPrintingService] No BLE devices found. If using Classic Bluetooth printer, this library only supports BLE. Consider switching to flutter_bluetooth_serial for Classic Bluetooth.');
      }
      return devices;
    } catch (e) {
  debugPrint('❌ [BluetoothPrintingService] Failed to scan printers: $e');
      throw Exception('Failed to scan printers: $e');
    }
  }

  Future<bool> connectToPrinter(BluetoothDevice printer, {int maxRetries = 3}) async {
  debugPrint('🔗 [BluetoothPrintingService] Starting connection to printer: ${printer.platformName} (${printer.remoteId})');
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
  debugPrint('🔄 [BluetoothPrintingService] Connection attempt $attempt/$maxRetries');
        await printerManager.connect(printer);
        _selectedPrinter = printer;
        _isConnected = true;
  debugPrint('✅ [BluetoothPrintingService] Connected successfully to ${printer.platformName}');

        // Add a small delay after connection to let the connection stabilize
        await Future.delayed(const Duration(milliseconds: 500));
  debugPrint('📡 [BluetoothPrintingService] Connection stabilized, isConnected: $isConnected');
        return true;
      } catch (e) {
  debugPrint('❌ [BluetoothPrintingService] Connection attempt $attempt failed: $e');
        if (attempt == maxRetries) {
          debugPrint('💥 [BluetoothPrintingService] All connection attempts failed');
          throw Exception('Failed to connect to printer after $maxRetries attempts: $e');
        }
        // Wait before retrying
  debugPrint('⏳ [BluetoothPrintingService] Waiting ${attempt}s before retry...');
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    return false;
  }

  Future<void> disconnect() async {
  debugPrint('🔌 [BluetoothPrintingService] Disconnecting from printer...');
    try {
      await printerManager.disconnect();
      _selectedPrinter = null;
      _isConnected = false;
  debugPrint('✅ [BluetoothPrintingService] Disconnected successfully');
    } catch (e) {
  debugPrint('❌ [BluetoothPrintingService] Disconnect failed: $e');
      // Still clear the selected printer and connection status even if disconnect fails
      _selectedPrinter = null;
      _isConnected = false;
      throw Exception('Failed to disconnect: $e');
    }
  }

  Future<Uint8List?> _generateQRImage(String data, double size) async {
    try {
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: false,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
  // Paint QR to canvas and export as PNG
  qrPainter.paint(canvas, Size(size, size));
  final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      throw Exception('Failed to generate QR image: $e');
    }
  }

  Future<void> printQRCode(String qrData, String productName, String batchNumber) async {
      debugPrint('🖨️ [BluetoothPrintingService] Starting QR code print for: $productName (Batch: $batchNumber)');
    debugPrint('📊 [BluetoothPrintingService] QR data being encoded: $qrData');

    BluetoothDevice? printerToUse = _selectedPrinter;
    if (printerToUse == null) {
  debugPrint('❌ [BluetoothPrintingService] No printer selected');
      throw Exception('No printer selected');
    }

    // Ensure connection is valid
    if (!isConnected) {
  debugPrint('🔄 [BluetoothPrintingService] Not connected, attempting to reconnect...');
      try {
        await connectToPrinter(printerToUse, maxRetries: 2);
      } catch (e) {
  debugPrint('❌ [BluetoothPrintingService] Reconnection failed: $e');
        throw Exception('Failed to connect to printer: $e');
      }
    }

    try {
  debugPrint('🎨 [BluetoothPrintingService] Generating QR image...');
      // Generate QR image
      final qrImage = await _generateQRImage(qrData, 200.0);
      if (qrImage == null) {
        throw Exception('Failed to generate QR code image');
      }
  debugPrint('✅ [BluetoothPrintingService] QR image generated successfully');

      // Create ESC/POS commands
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      List<int> bytes = [];

      // Header
      bytes += generator.text('Nyama Tamu QR Code',
          styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.feed(1);

      // Product info
      bytes += generator.text('Product: $productName',
          styles: PosStyles(align: PosAlign.center));
      bytes += generator.text('Batch: $batchNumber',
          styles: PosStyles(align: PosAlign.center));
      bytes += generator.feed(1);

      // QR Code
      bytes += generator.qrcode(qrData);
      bytes += generator.feed(2);

      // Footer
      bytes += generator.text('Scan to verify traceability',
          styles: PosStyles(align: PosAlign.center));
      bytes += generator.feed(3);
      bytes += generator.cut();

  debugPrint('📤 [BluetoothPrintingService] Sending ${bytes.length} bytes to printer...');
      // Send to printer
      try {
        await printerManager.writeBytes(Uint8List.fromList(bytes));
  debugPrint('✅ [BluetoothPrintingService] Data sent to printer successfully');

        // Add delay after printing to ensure data is sent
  debugPrint('⏳ [BluetoothPrintingService] Waiting for print completion...');
  await Future.delayed(const Duration(milliseconds: 1000));
  debugPrint('✅ [BluetoothPrintingService] QR code print completed');
      } catch (e) {
        // If writing fails, reset connection state
  _isConnected = false;
  _selectedPrinter = null;
  debugPrint('💥 [BluetoothPrintingService] Print failed, resetting connection: $e');
        throw Exception('Failed to print QR code: $e');
      }

    } catch (e) {
  debugPrint('💥 [BluetoothPrintingService] Failed to print QR code: $e');
      throw Exception('Failed to print QR code: $e');
    }
  }

  Future<void> printTestPage() async {
    BluetoothDevice? printerToUse = _selectedPrinter;
    if (printerToUse == null) {
      throw Exception('No printer selected');
    }

    // Ensure connection is valid
    if (!isConnected) {
  debugPrint('🔄 [BluetoothPrintingService] Not connected, attempting to reconnect for test print...');
      try {
        await connectToPrinter(printerToUse, maxRetries: 2);
      } catch (e) {
    debugPrint('❌ [BluetoothPrintingService] Reconnection failed for test print: $e');
        throw Exception('Failed to connect to printer: $e');
      }
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      List<int> bytes = [];
      bytes += generator.text('Test Print',
          styles: PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.feed(1);
      bytes += generator.text('Bluetooth printer connected successfully',
          styles: PosStyles(align: PosAlign.center));
      bytes += generator.feed(1);
      bytes += generator.qrcode('test:12345');
      bytes += generator.feed(3);
      bytes += generator.cut();

      try {
        await printerManager.writeBytes(Uint8List.fromList(bytes));

        // Add delay after printing to ensure data is sent
        await Future.delayed(const Duration(milliseconds: 1000));
      } catch (e) {
        // If writing fails, reset connection state
        _isConnected = false;
        _selectedPrinter = null;
  _isConnected = false;
  _selectedPrinter = null;
  debugPrint('💥 [BluetoothPrintingService] Test print failed, resetting connection: $e');
        throw Exception('Failed to print test page: $e');
      }
    } catch (e) {
      throw Exception('Failed to print test page: $e');
    }
  }
}







