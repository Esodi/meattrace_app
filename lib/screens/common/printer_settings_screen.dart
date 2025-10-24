// Temporarily ignore deprecated RadioListTile APIs (migrate to RadioGroup later)
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:meattrace_app/utils/app_colors.dart';
import 'package:meattrace_app/utils/app_typography.dart';
import 'package:meattrace_app/utils/app_theme.dart';
import 'package:meattrace_app/widgets/core/custom_button.dart';
import 'package:meattrace_app/services/bluetooth_printing_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Bluetooth printer settings screen
/// Manages printer connection, device discovery, and print settings
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  bool _isScanning = false;
  bool _isBluetoothEnabled = false;
  BluetoothDevice? _connectedDevice;
  final List<BluetoothDevice> _availableDevices = [];
  final BluetoothPrintingService _printingService = BluetoothPrintingService();

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      // Listen to adapter state once and update
      final state = await FlutterBluePlus.adapterState.first;
      setState(() {
        _isBluetoothEnabled = state == BluetoothAdapterState.on;
      });

      // Also listen for changes
      FlutterBluePlus.adapterState.listen((s) {
        if (mounted) setState(() => _isBluetoothEnabled = s == BluetoothAdapterState.on);
      });
    } catch (e) {
      // Fallback: assume disabled
      setState(() => _isBluetoothEnabled = false);
    }
  }

  Future<void> _openBluetoothSettings() async {
    // Attempt to open the OS settings so the user can enable Bluetooth.
    // There's no cross-platform programmatic 'enable' for Bluetooth; instruct
    // the user to toggle it in system settings. We open app settings as a
    // helpful shortcut.
    try {
      final opened = await openAppSettings();
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable Bluetooth from your system settings')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open settings: $e')));
    }
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _availableDevices.clear();
    });

    try {
      // Ensure permissions for BLE scan
      final granted = await _printingService.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bluetooth permissions are required to scan for printers')),
          );
        }
        setState(() => _isScanning = false);
        return;
      }

      final devices = await _printingService.scanPrinters();
      if (mounted) {
        setState(() {
          _availableDevices.addAll(devices);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to scan for printers: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      final connected = await _printingService.connectToPrinter(device, maxRetries: 3);
      if (connected) {
        setState(() => _connectedDevice = device);
        if (mounted) {
            final displayName = device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to $displayName'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    }
  }

  Future<void> _disconnectDevice() async {
    try {
      await _printingService.disconnect();
    final deviceName = (_connectedDevice != null && _connectedDevice!.platformName.isNotEmpty)
      ? _connectedDevice!.platformName
      : (_connectedDevice?.remoteId.toString() ?? 'device');
      setState(() => _connectedDevice = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disconnected from $deviceName'), backgroundColor: AppColors.warning),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disconnect: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Printer Settings'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.space16),
        children: [
          // Bluetooth status
          _buildBluetoothStatusCard(),
          const SizedBox(height: AppTheme.space16),

          // Connected device
          if (_connectedDevice != null) ...[
            _buildConnectedDeviceCard(),
            const SizedBox(height: AppTheme.space16),
          ],

          // Available devices
          _buildAvailableDevicesSection(),
          const SizedBox(height: AppTheme.space16),

          // Print test button
          if (_connectedDevice != null) _buildPrintTestButton(),
        ],
      ),
    );
  }

  Widget _buildBluetoothStatusCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.textSecondary.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: _isBluetoothEnabled
                  ? AppColors.info.withAlpha(26)
                  : AppColors.textSecondary.withAlpha(26),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              Icons.bluetooth,
              color: _isBluetoothEnabled ? AppColors.info : AppColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bluetooth',
                  style: AppTypography.headlineSmall(),
                ),
                Text(
                  _isBluetoothEnabled ? 'Enabled' : 'Disabled',
                  style: AppTypography.bodyMedium().copyWith(
                    color: _isBluetoothEnabled
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isBluetoothEnabled,
            onChanged: (value) {
              setState(() {
                _isBluetoothEnabled = value;
              });
              // Offer a shortcut to system settings where Bluetooth can be enabled
              if (!value) {
                // User turned the switch off in the UI - ask them to use system settings
                _openBluetoothSettings();
              } else {
                _openBluetoothSettings();
              }
            },
            // activeColor is deprecated; use activeThumbColor
            activeThumbColor: AppColors.info,
          ),
          const SizedBox(width: AppTheme.space8),
          if (!_isBluetoothEnabled)
            ElevatedButton(
              onPressed: _openBluetoothSettings,
              child: const Text('Open Bluetooth Settings'),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectedDeviceCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.success.withAlpha(77), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Text(
                'Connected Printer',
                style: AppTypography.headlineSmall().copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          
          Row(
            children: [
              Icon(
                Icons.print,
                color: AppColors.textSecondary,
                size: 48,
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(
                        // platformName is non-nullable; check emptiness instead of null
                        _connectedDevice!.platformName.isNotEmpty
                            ? _connectedDevice!.platformName
                            : _connectedDevice!.remoteId.toString(),
                      style: AppTypography.bodyLarge().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      _connectedDevice!.remoteId.toString(),
                      style: AppTypography.bodyMedium().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              label: 'Disconnect',
              variant: ButtonVariant.secondary,
              onPressed: _disconnectDevice,
              icon: Icons.bluetooth_disabled,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Set as Default',
                  variant: ButtonVariant.primary,
                  onPressed: () async {
                    if (_connectedDevice != null) {
                      await _printingService.saveSelectedPrinter(_connectedDevice!);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved as default printer')));
                    }
                  },
                  icon: Icons.star,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: CustomButton(
                  label: 'Clear Default',
                  variant: ButtonVariant.secondary,
                  onPressed: () async {
                    await _printingService.clearSavedPrinter();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cleared default printer')));
                  },
                  icon: Icons.clear,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableDevicesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.textSecondary.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Available Devices',
                    style: AppTypography.headlineSmall(),
                  ),
                ),
                if (_isScanning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isBluetoothEnabled ? _startScanning : null,
                    color: AppColors.info,
                    tooltip: 'Scan for devices',
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          if (!_isBluetoothEnabled)
            Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.bluetooth_disabled,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Text(
                      'Bluetooth is disabled',
                      style: AppTypography.bodyLarge().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Enable Bluetooth to discover printers',
                      style: AppTypography.bodyMedium().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_availableDevices.isEmpty && !_isScanning)
            Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Text(
                      'No devices found',
                      style: AppTypography.bodyLarge().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Tap refresh to scan for nearby printers',
                      style: AppTypography.bodyMedium().copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableDevices.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: AppTheme.space16,
              ),
              itemBuilder: (context, index) {
                final device = _availableDevices[index];
                return _buildDeviceListItem(device);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceListItem(BluetoothDevice device) {
    final isConnected = _connectedDevice?.remoteId.toString() == device.remoteId.toString();

    String deviceTitle() {
      // Prefer platformName (flutter_blue_plus), then name, then id
    // Prefer platformName (non-nullable) and fall back to remoteId string
    if (device.platformName.isNotEmpty) return device.platformName;
    return device.remoteId.toString();
    }

    String deviceSubtitle() => device.remoteId.toString();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: AppColors.info.withAlpha(26),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: const Icon(
          Icons.print,
          color: AppColors.info,
          size: 24,
        ),
      ),
      title: Text(
        deviceTitle(),
        style: AppTypography.bodyLarge().copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        deviceSubtitle(),
        style: AppTypography.bodyMedium().copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: isConnected
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space12,
                vertical: AppTheme.space6,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(26),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                'Connected',
                style: AppTypography.labelMedium().copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : TextButton(
              onPressed: () => _connectToDevice(device),
              child: const Text('Connect'),
            ),
    );
  }

  Widget _buildPrintTestButton() {
    return CustomButton(
      label: 'Print Test Label',
      variant: ButtonVariant.primary,
      onPressed: () => _showPrintDialog(context),
      icon: Icons.print,
      size: ButtonSize.large,
    );
  }

  void _showPrintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PrintDialog(
          printerName: _connectedDevice != null && _connectedDevice!.platformName.isNotEmpty
              ? _connectedDevice!.platformName
              : (_connectedDevice?.remoteId.toString() ?? 'Printer'),
        onPrint: (template, copies) {
          Navigator.pop(context);
          _printLabel(template, copies);
        },
      ),
    );
  }

  Future<void> _printLabel(PrintTemplate template, int copies) async {
    // TODO: Implement actual printing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Printing $copies ${template.name} label(s)...'),
        backgroundColor: AppColors.info,
      ),
    );

    // Simulate printing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Print completed successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

/// Print dialog widget
class PrintDialog extends StatefulWidget {
  final String printerName;
  final Function(PrintTemplate template, int copies) onPrint;

  const PrintDialog({
    super.key,
    required this.printerName,
    required this.onPrint,
  });

  @override
  State<PrintDialog> createState() => _PrintDialogState();
}

class _PrintDialogState extends State<PrintDialog> {
  PrintTemplate _selectedTemplate = PrintTemplate.animalTag;
  int _copies = 1;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withAlpha(26),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.print,
                    color: AppColors.info,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Print Label',
                        style: AppTypography.headlineMedium(),
                      ),
                      Text(
                        widget.printerName,
                        style: AppTypography.bodyMedium().copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space24),

            // Template selection
            Text(
              'Label Template',
              style: AppTypography.bodyLarge().copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            ...PrintTemplate.values.map((template) {
              // The RadioListTile 'groupValue' and 'onChanged' APIs are deprecated in
              // newer Flutter versions in favor of RadioGroup. We keep the current
              // widget for now and suppress the analyzer info to avoid noise.
              // TODO: migrate to RadioGroup when ready.
              return RadioListTile<PrintTemplate>(
                value: template,
                groupValue: _selectedTemplate,
                onChanged: (value) {
                  setState(() {
                    _selectedTemplate = value!;
                  });
                },
                title: Text(template.name),
                subtitle: Text(
                  template.description,
                  style: AppTypography.bodyMedium().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                activeColor: AppColors.info,
              );
            }),

            const SizedBox(height: AppTheme.space16),

            // Copies selector
            Text(
              'Number of Copies',
              style: AppTypography.bodyLarge().copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _copies > 1
                      ? () => setState(() => _copies--)
                      : null,
                  color: AppColors.info,
                ),
                Expanded(
                  child: Text(
                    '$_copies',
                    style: AppTypography.headlineMedium(),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _copies < 10
                      ? () => setState(() => _copies++)
                      : null,
                  color: AppColors.info,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.space24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Cancel',
                    variant: ButtonVariant.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: CustomButton(
                    label: 'Print',
                    variant: ButtonVariant.primary,
                    onPressed: () {
                      widget.onPrint(_selectedTemplate, _copies);
                    },
                    icon: Icons.print,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



/// Print template enum
enum PrintTemplate {
  animalTag('Animal Tag', '2" x 1" tag with QR code and ID'),
  productLabel('Product Label', '4" x 2" label with product details'),
  transferReceipt('Transfer Receipt', 'A4 receipt with transfer details'),
  qrCodeOnly('QR Code Only', '2" x 2" QR code label');

  final String name;
  final String description;

  const PrintTemplate(this.name, this.description);
}
