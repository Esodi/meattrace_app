import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;

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
        print('📤 [PrinterManager] Writing ${bytes.length} bytes to printer...');
        await _writeCharacteristic!.write(bytes, withoutResponse: true);
        print('✅ [PrinterManager] Bytes written successfully');
      } catch (e) {
        print('❌ [PrinterManager] Failed to write bytes: $e');
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

  void _initializePlugin() {
    print('🔧 [BluetoothPrintingService] Initializing flutter_blue_plus...');

    // Set log level for debugging
    FlutterBluePlus.setLogLevel(LogLevel.info, color: true);

    print('✅ [BluetoothPrintingService] Initialized with flutter_blue_plus - full control over Bluetooth connections');
  }

  PrinterManager get printerManager {
    _printerManager ??= PrinterManager();
    return _printerManager!;
  }

  bool get isConnected => _isConnected && _selectedPrinter != null;
  BluetoothDevice? get selectedPrinter => _selectedPrinter;

  Future<bool> requestPermissions() async {
    try {
      print('🔐 [BluetoothPrintingService] Requesting Bluetooth permissions...');

      // Request permissions one by one for better error handling
      final bluetoothScan = await Permission.bluetoothScan.request();
      print('📡 Bluetooth scan permission: ${bluetoothScan.toString()}');

      final bluetoothConnect = await Permission.bluetoothConnect.request();
      print('🔗 Bluetooth connect permission: ${bluetoothConnect.toString()}');

      final location = await Permission.location.request();
      print('📍 Location permission: ${location.toString()}');

      final allGranted = bluetoothScan.isGranted && bluetoothConnect.isGranted && location.isGranted;
      print('✅ [BluetoothPrintingService] All permissions granted: $allGranted');

      return allGranted;
    } catch (e) {
      print('❌ [BluetoothPrintingService] Error requesting permissions: $e');
      return false;
    }
  }

  Future<List<BluetoothDevice>> scanPrinters() async {
    try {
      print('🔍 [BluetoothPrintingService] Starting printer scan...');

      // Check if Bluetooth is available and enabled
      if (!await FlutterBluePlus.isSupported) {
        throw Exception('Bluetooth is not supported on this device');
      }

      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        throw Exception('Bluetooth is not enabled. Please enable Bluetooth and try again.');
      }

      final scanResults = await printerManager.scan();
      // Convert ScanResult to BluetoothDevice, filtering for printers if possible
      final devices = scanResults.map((result) => result.device).toList();

      print('✅ [BluetoothPrintingService] Found ${devices.length} Bluetooth devices');
      return devices;
    } catch (e) {
      print('❌ [BluetoothPrintingService] Failed to scan printers: $e');
      throw Exception('Failed to scan printers: $e');
    }
  }

  Future<bool> connectToPrinter(BluetoothDevice printer, {int maxRetries = 3}) async {
    print('🔗 [BluetoothPrintingService] Starting connection to printer: ${printer.platformName} (${printer.remoteId})');
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔄 [BluetoothPrintingService] Connection attempt $attempt/$maxRetries');
        await printerManager.connect(printer);
        _selectedPrinter = printer;
        _isConnected = true;
        print('✅ [BluetoothPrintingService] Connected successfully to ${printer.platformName}');

        // Add a small delay after connection to let the connection stabilize
        await Future.delayed(const Duration(milliseconds: 500));
        print('📡 [BluetoothPrintingService] Connection stabilized, isConnected: $isConnected');
        return true;
      } catch (e) {
        print('❌ [BluetoothPrintingService] Connection attempt $attempt failed: $e');
        if (attempt == maxRetries) {
          print('💥 [BluetoothPrintingService] All connection attempts failed');
          throw Exception('Failed to connect to printer after $maxRetries attempts: $e');
        }
        // Wait before retrying
        print('⏳ [BluetoothPrintingService] Waiting ${attempt}s before retry...');
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    return false;
  }

  Future<void> disconnect() async {
    print('🔌 [BluetoothPrintingService] Disconnecting from printer...');
    try {
      await printerManager.disconnect();
      _selectedPrinter = null;
      _isConnected = false;
      print('✅ [BluetoothPrintingService] Disconnected successfully');
    } catch (e) {
      print('❌ [BluetoothPrintingService] Disconnect failed: $e');
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
      final paint = Paint();

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
    print('🖨️ [BluetoothPrintingService] Starting QR code print for: $productName (Batch: $batchNumber)');

    BluetoothDevice? printerToUse = _selectedPrinter;
    if (printerToUse == null) {
      print('❌ [BluetoothPrintingService] No printer selected');
      throw Exception('No printer selected');
    }

    // Ensure connection is valid
    if (!isConnected) {
      print('🔄 [BluetoothPrintingService] Not connected, attempting to reconnect...');
      try {
        await connectToPrinter(printerToUse, maxRetries: 2);
      } catch (e) {
        print('❌ [BluetoothPrintingService] Reconnection failed: $e');
        throw Exception('Failed to connect to printer: $e');
      }
    }

    try {
      print('🎨 [BluetoothPrintingService] Generating QR image...');
      // Generate QR image
      final qrImage = await _generateQRImage(qrData, 200.0);
      if (qrImage == null) {
        throw Exception('Failed to generate QR code image');
      }
      print('✅ [BluetoothPrintingService] QR image generated successfully');

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

      print('📤 [BluetoothPrintingService] Sending ${bytes.length} bytes to printer...');
      // Send to printer
      try {
        await printerManager.writeBytes(Uint8List.fromList(bytes));
        print('✅ [BluetoothPrintingService] Data sent to printer successfully');

        // Add delay after printing to ensure data is sent
        print('⏳ [BluetoothPrintingService] Waiting for print completion...');
        await Future.delayed(const Duration(milliseconds: 1000));
        print('✅ [BluetoothPrintingService] QR code print completed');
      } catch (e) {
        // If writing fails, reset connection state
        _isConnected = false;
        _selectedPrinter = null;
        print('💥 [BluetoothPrintingService] Print failed, resetting connection: $e');
        throw Exception('Failed to print QR code: $e');
      }

    } catch (e) {
      print('💥 [BluetoothPrintingService] Failed to print QR code: $e');
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
      print('🔄 [BluetoothPrintingService] Not connected, attempting to reconnect for test print...');
      try {
        await connectToPrinter(printerToUse, maxRetries: 2);
      } catch (e) {
        print('❌ [BluetoothPrintingService] Reconnection failed for test print: $e');
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
        print('💥 [BluetoothPrintingService] Test print failed, resetting connection: $e');
        throw Exception('Failed to print test page: $e');
      }
    } catch (e) {
      throw Exception('Failed to print test page: $e');
    }
  }
}







