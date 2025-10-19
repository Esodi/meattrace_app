import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_button.dart';

/// Bluetooth printer settings screen
/// Manages printer connection, device discovery, and print settings
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  bool _isScanning = false;
  bool _isBluetoothEnabled = true;
  BluetoothDevice? _connectedDevice;
  final List<BluetoothDevice> _availableDevices = [];

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
  }

  Future<void> _checkBluetoothStatus() async {
    // TODO: Implement bluetooth status check
    // Use flutter_blue_plus or similar package
    setState(() {
      _isBluetoothEnabled = true;
    });
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _availableDevices.clear();
    });

    // TODO: Implement bluetooth scanning
    // Simulate device discovery
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _availableDevices.addAll([
        BluetoothDevice(
          name: 'Zebra ZD421',
          address: '00:07:4D:4F:4E:59',
          isConnected: false,
        ),
        BluetoothDevice(
          name: 'Epson TM-T88VI',
          address: '00:01:90:A2:B3:C4',
          isConnected: false,
        ),
        BluetoothDevice(
          name: 'Brother QL-820NWB',
          address: '00:80:92:12:34:56',
          isConnected: false,
        ),
      ]);
      _isScanning = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    // TODO: Implement bluetooth connection
    setState(() {
      _connectedDevice = device.copyWith(isConnected: true);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.name}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _disconnectDevice() async {
    // TODO: Implement bluetooth disconnection
    final deviceName = _connectedDevice?.name ?? 'device';
    
    setState(() {
      _connectedDevice = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disconnected from $deviceName'),
          backgroundColor: AppColors.warning,
        ),
      );
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
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: _isBluetoothEnabled
                  ? AppColors.info.withValues(alpha: 0.1)
                  : AppColors.textSecondary.withValues(alpha: 0.1),
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
              // TODO: Enable/disable bluetooth
            },
            activeColor: AppColors.info,
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
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
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
                      _connectedDevice!.name,
                      style: AppTypography.bodyLarge().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      _connectedDevice!.address,
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
        ],
      ),
    );
  }

  Widget _buildAvailableDevicesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
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
    final isConnected = _connectedDevice?.address == device.address;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: const Icon(
          Icons.print,
          color: AppColors.info,
          size: 24,
        ),
      ),
      title: Text(
        device.name,
        style: AppTypography.bodyLarge().copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        device.address,
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
                color: AppColors.success.withValues(alpha: 0.1),
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
        printerName: _connectedDevice?.name ?? 'Printer',
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
                    color: AppColors.info.withValues(alpha: 0.1),
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

/// Bluetooth device model
class BluetoothDevice {
  final String name;
  final String address;
  final bool isConnected;

  BluetoothDevice({
    required this.name,
    required this.address,
    required this.isConnected,
  });

  BluetoothDevice copyWith({
    String? name,
    String? address,
    bool? isConnected,
  }) {
    return BluetoothDevice(
      name: name ?? this.name,
      address: address ?? this.address,
      isConnected: isConnected ?? this.isConnected,
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
