import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/bluetooth_scale_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';

class ScaleConnectionDialog extends StatefulWidget {
  const ScaleConnectionDialog({super.key});

  @override
  State<ScaleConnectionDialog> createState() => _ScaleConnectionDialogState();
}

class _ScaleConnectionDialogState extends State<ScaleConnectionDialog> {
  final BluetoothScaleService _scaleService = BluetoothScaleService();
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanResults = [];
    });

    try {
      debugPrint('🔍 [ScaleDialog] Requesting Bluetooth permissions...');

      // Android 12+ requires these to be granted at runtime — declaring
      // them in the manifest alone is not enough. Without this, startScan()
      // silently returns zero devices (looks like "nothing found").
      final bluetoothScan = await Permission.bluetoothScan.request();
      final bluetoothConnect = await Permission.bluetoothConnect.request();
      final location = await Permission.location.request();
      debugPrint(
        '🔐 [ScaleDialog] scan=$bluetoothScan connect=$bluetoothConnect location=$location',
      );

      if (!bluetoothScan.isGranted || !bluetoothConnect.isGranted) {
        throw Exception(
          'Bluetooth permission denied. Enable it in app settings to connect a scale.',
        );
      }
      // Location is only declared up to API 30 in the manifest (BLUETOOTH_SCAN
      // is flagged neverForLocation on 31+), so on Android 12+ devices this
      // permission doesn't exist to grant and must not block scanning. It's
      // still required pre-12, so we request it best-effort and only warn —
      // if it's actually needed and missing, startScan() itself will fail
      // with a reportable error via the existing catch block below.
      if (!location.isGranted) {
        debugPrint(
          '⚠️ [ScaleDialog] Location permission not granted (expected on Android 12+)',
        );
      } else {
        final locationEnabled =
            await Permission.location.serviceStatus.isEnabled;
        if (!locationEnabled) {
          debugPrint('⚠️ [ScaleDialog] Location services are turned off');
        }
      }

      debugPrint('🔍 [ScaleDialog] Checking Bluetooth support...');

      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth is not supported on this device');
      }

      debugPrint('🔍 [ScaleDialog] Checking Bluetooth adapter state...');
      final adapterState = await FlutterBluePlus.adapterState.first;
      debugPrint('🔍 [ScaleDialog] Adapter state: $adapterState');

      if (adapterState != BluetoothAdapterState.on) {
        throw Exception(
          'Bluetooth is turned off. Please enable Bluetooth and try again.',
        );
      }

      debugPrint('🔍 [ScaleDialog] Starting scan...');
      await _scaleService.startScan(timeout: const Duration(seconds: 15));

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        debugPrint(
          '🔍 [ScaleDialog] Scan results: ${results.length} devices found',
        );
        if (mounted) {
          // Use addPostFrameCallback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                // Show ALL devices, not just those with names
                _scanResults = results;
              });

              // Debug: print device names
              for (var result in results) {
                debugPrint(
                  '  - Device: ${result.device.platformName.isEmpty ? "Unknown" : result.device.platformName} (${result.device.remoteId})',
                );
              }
            }
          });
        }
      });

      // Auto-stop scanning after timeout
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && _isScanning) {
          debugPrint('🔍 [ScaleDialog] Scan timeout reached, stopping...');
          _stopScan();
        }
      });
    } catch (e) {
      debugPrint('❌ [ScaleDialog] Scan error: $e');
      if (mounted) {
        setState(() => _isScanning = false);
        if (context.mounted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Scan failed: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _stopScan() async {
    _scanSubscription?.cancel();
    await _scaleService.stopScan();
    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await _stopScan();

    try {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      await _scaleService.connect(device);

      // Close loading
      if (mounted) Navigator.pop(context);

      // Close dialog with success
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.bluetooth, color: AppColors.abbatoirPrimary),
          const SizedBox(width: 12),
          const Text('Connect Scale'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            if (_isScanning)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            const SizedBox(height: 8),
            Text(
              '${_scanResults.length} devices found',
              style: AppTypography.bodySmall(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _scanResults.length,
                itemBuilder: (context, index) {
                  final result = _scanResults[index];
                  final deviceName = result.device.platformName.isEmpty
                      ? 'Unknown'
                      : result.device.platformName;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bluetooth, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                deviceName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                result.device.remoteId.toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _connectToDevice(result.device),
                          child: const Text('Connect'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_isScanning)
          TextButton(onPressed: _stopScan, child: const Text('Stop Scan'))
        else
          TextButton(onPressed: _startScan, child: const Text('Rescan')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
