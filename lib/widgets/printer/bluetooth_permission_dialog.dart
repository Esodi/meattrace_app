import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/bluetooth_printing_service.dart';

/// Ensures Bluetooth scan/connect permissions are granted before printing.
///
/// If permission was never asked (or was denied but not permanently), this
/// re-triggers the system permission dialog instead of just failing. If the
/// user has permanently denied it (Android "Don't ask again", or iOS after
/// its one-shot prompt), the system dialog can no longer appear, so this
/// offers a path to the app's Settings page instead.
///
/// Returns true once permissions are granted and the caller can proceed.
Future<bool> ensureBluetoothPermissions(BuildContext context) async {
  final service = BluetoothPrintingService();

  if (await service.requestPermissions()) return true;
  if (!context.mounted) return false;

  final permanentlyDenied = await service.hasPermanentlyDeniedPermissions();
  if (!context.mounted) return false;

  if (permanentlyDenied) {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bluetooth Permission Needed'),
        content: const Text(
          'Bluetooth permission was denied, so this app can no longer ask for '
          'it directly. Please enable Bluetooth permission in Settings, then '
          'try printing again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (openSettings == true) {
      await openAppSettings();
    }
    return false;
  }

  // Not permanently denied yet — explain why we need it, then re-request so
  // the system dialog appears again rather than leaving the user stuck.
  final tryAgain = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Bluetooth Permission Needed'),
      content: const Text(
        'MeatTrace Pro needs Bluetooth permission to find and print to your '
        'receipt printer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Grant Permission'),
        ),
      ],
    ),
  );
  if (tryAgain == true) {
    if (!context.mounted) return false;
    return await service.requestPermissions();
  }
  return false;
}
