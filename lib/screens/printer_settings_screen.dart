import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_printing_service.dart';
import '../widgets/enhanced_back_button.dart';
import '../widgets/loading_indicator.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final BluetoothPrintingService _printingService = BluetoothPrintingService();
  List<BluetoothDevice> _availablePrinters = [];
  BluetoothDevice? _selectedPrinter;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isTesting = false;
  String? _defaultPrinterAddress;

  @override
  void initState() {
    super.initState();
    _loadDefaultPrinter();
  }

  Future<void> _loadDefaultPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultPrinterAddress = prefs.getString('default_printer_address');
    setState(() {});
  }

  Future<void> _saveDefaultPrinter(String? address) async {
    if (address == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_printer_address', address);
    _defaultPrinterAddress = address;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default printer saved')),
    );
  }

  Future<void> _scanPrinters() async {
    setState(() => _isScanning = true);

    try {
      final hasPermissions = await _printingService.requestPermissions();
      if (!hasPermissions) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth permissions are required')),
        );
        return;
      }

      final printers = await _printingService.scanPrinters();
      setState(() {
        _availablePrinters = printers;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan printers: $e')),
      );
    }
  }

  Future<void> _connectToPrinter(BluetoothDevice printer) async {
    print('🔗 [PrinterSettingsScreen] Starting connection to: ${printer.platformName} (${printer.remoteId})');
    setState(() => _isConnecting = true);

    try {
      final connected = await _printingService.connectToPrinter(printer, maxRetries: 3);
      print('📊 [PrinterSettingsScreen] Connection result: $connected, isConnected: ${_printingService.isConnected}');
      setState(() {
        _isConnecting = false;
        _selectedPrinter = connected ? printer : null;
      });

      if (connected) {
        print('✅ [PrinterSettingsScreen] Successfully connected to ${printer.name}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${printer.name}')),
        );
      } else {
        print('❌ [PrinterSettingsScreen] Connection returned false');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect after multiple attempts')),
        );
      }
    } catch (e) {
      print('💥 [PrinterSettingsScreen] Connection exception: $e');
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }

  Future<void> _disconnectPrinter() async {
    try {
      await _printingService.disconnect();
      setState(() => _selectedPrinter = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected from printer')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to disconnect: $e')),
      );
    }
  }

  Future<void> _testPrint() async {
    print('🖨️ [PrinterSettingsScreen] Test print requested');
    print('📊 [PrinterSettingsScreen] isConnected: ${_printingService.isConnected}, selectedPrinter: ${_printingService.selectedPrinter}');
    if (!_printingService.isConnected) {
      print('❌ [PrinterSettingsScreen] No printer connected - showing error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No printer connected')),
      );
      return;
    }

    setState(() => _isTesting = true);

    try {
      print('🔄 [PrinterSettingsScreen] Starting test print...');
      await _printingService.printTestPage();
      print('✅ [PrinterSettingsScreen] Test print completed successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test print sent successfully')),
      );
    } catch (e) {
      print('💥 [PrinterSettingsScreen] Test print failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test print failed: $e')),
      );
    } finally {
      setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createEnhancedAppBarWithBackButton(
        title: 'Printer Settings',
        fallbackRoute: '/processor-home',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _printingService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                          color: _printingService.isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _printingService.isConnected
                              ? 'Connected to ${_selectedPrinter?.platformName ?? "Printer"}'
                              : 'Not connected',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scan Printers
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Printers',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isScanning ? null : _scanPrinters,
                        icon: _isScanning ? const LoadingIndicator() : const Icon(Icons.search),
                        label: Text(_isScanning ? 'Scanning...' : 'Scan for Printers'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._availablePrinters.map((printer) => ListTile(
                      title: Text(printer?.platformName ?? 'Unknown Printer'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_defaultPrinterAddress == printer?.remoteId.toString())
                            const Icon(Icons.star, color: Colors.amber),
                          IconButton(
                            icon: const Icon(Icons.bluetooth),
                            onPressed: _isConnecting ? null : () => _connectToPrinter(printer),
                          ),
                          IconButton(
                            icon: const Icon(Icons.star_border),
                            onPressed: () => _saveDefaultPrinter(printer?.remoteId.toString()),
                            tooltip: 'Set as default',
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Print
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Print',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isTesting || !_printingService.isConnected) ? null : _testPrint,
                        icon: _isTesting ? const LoadingIndicator() : const Icon(Icons.print),
                        label: const Text('Print Test Page'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Disconnect
            if (_printingService.isConnected)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _disconnectPrinter,
                      icon: const Icon(Icons.bluetooth_disabled),
                      label: const Text('Disconnect Printer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}







