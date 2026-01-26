import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../models/sale.dart';
import '../../services/bluetooth_printing_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/core/custom_button.dart';
import 'package:intl/intl.dart';

class ReceiptPrinter {
  static final BluetoothPrintingService _printingService =
      BluetoothPrintingService();

  /// Print sale receipt with all details
  static Future<void> printSaleReceipt(BuildContext context, Sale sale) async {
    // Show printing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _PrintingDialog(),
    );

    try {
      // Check if printer is connected
      if (!_printingService.isConnected) {
        // Try to connect to saved printer
        final connected = await _printingService.connectToSavedPrinter();

        if (!connected) {
          // No saved printer, show printer selection
          Navigator.of(context).pop(); // Close printing dialog

          final shouldPrint = await _showPrinterSelectionDialog(context);
          if (shouldPrint != true) return;

          // Show printing dialog again
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const _PrintingDialog(),
            );
          }
        }
      }

      // Generate receipt bytes
      final bytes = await _generateReceiptBytes(sale);

      // Print receipt
      await _printingService.printerManager.writeBytes(bytes);

      // Close printing dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt printed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Close printing dialog
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print receipt: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Generate ESC/POS receipt bytes
  static Future<Uint8List> _generateReceiptBytes(Sale sale) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    List<int> bytes = [];

    // Header
    bytes += generator.text(
      '================================',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'NYAMA TAMU',
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      '================================',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);

    // Sale info
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    // Convert UTC time to local time for display
    final localTime = sale.createdAt.toLocal();
    bytes += generator.text(
      'Date: ${dateFormat.format(localTime)}',
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      'Sale #: ${sale.id ?? 'N/A'}',
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      '--------------------------------',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);

    // Items header
    bytes += generator.text(
      'ITEMS:',
      styles: PosStyles(align: PosAlign.left, bold: true),
    );
    bytes += generator.feed(1);

    // Items list
    for (final item in sale.items) {
      // Product name and batch
      bytes += generator.text(
        item.productName ?? 'Product',
        styles: PosStyles(align: PosAlign.left, bold: true),
      );
      if (item.batchNumber != null) {
        bytes += generator.text(
          '  Batch: ${item.batchNumber}',
          styles: PosStyles(align: PosAlign.left),
        );
      }

      // Quantity, price, and subtotal
      bytes += generator.text(
        '  ${item.quantity.toStringAsFixed(2)} kg x TZS ${item.unitPrice.toStringAsFixed(2)} = TZS ${item.subtotal.toStringAsFixed(2)}',
        styles: PosStyles(align: PosAlign.left),
      );
      bytes += generator.feed(1);
    }

    bytes += generator.text(
      '--------------------------------',
      styles: PosStyles(align: PosAlign.center),
    );

    // Total
    bytes += generator.text(
      'TOTAL: TZS ${sale.totalAmount.toStringAsFixed(2)}',
      styles: PosStyles(
        align: PosAlign.right,
        bold: true,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      'Payment: ${sale.paymentMethod}',
      styles: PosStyles(align: PosAlign.right),
    );
    bytes += generator.text(
      '--------------------------------',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);

    // Customer info (if provided)
    if (sale.customerName != null || sale.customerPhone != null) {
      bytes += generator.text(
        'CUSTOMER:',
        styles: PosStyles(align: PosAlign.left, bold: true),
      );
      if (sale.customerName != null) {
        bytes += generator.text(
          'Name: ${sale.customerName}',
          styles: PosStyles(align: PosAlign.left),
        );
      }
      if (sale.customerPhone != null) {
        bytes += generator.text(
          'Phone: ${sale.customerPhone}',
          styles: PosStyles(align: PosAlign.left),
        );
      }
      bytes += generator.text(
        '--------------------------------',
        styles: PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);
    }

    // QR Codes for each product (for traceability)
    if (sale.items.isNotEmpty) {
      bytes += generator.text(
        '================================',
        styles: PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'PRODUCT TRACEABILITY',
        styles: PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        '================================',
        styles: PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      for (final item in sale.items) {
        // Product name
        bytes += generator.text(
          item.productName ?? 'Product',
          styles: PosStyles(align: PosAlign.center, bold: true),
        );
        if (item.batchNumber != null) {
          bytes += generator.text(
            'Batch: ${item.batchNumber}',
            styles: PosStyles(align: PosAlign.center),
          );
        }
        bytes += generator.feed(1);

        // Generate QR code URL for this product
        final productQrUrl =
            '${Constants.baseUrl}/product-info/view/${item.product}/';

        bytes += generator.qrcode(
          productQrUrl,
          size: QRSize.Size4,
          cor: QRCorrection.H,
        );
        bytes += generator.text(
          'Scan to trace product origin',
          styles: PosStyles(align: PosAlign.center),
        );
        bytes += generator.feed(1);

        // Separator between products if there are multiple
        if (sale.items.length > 1 && item != sale.items.last) {
          bytes += generator.text(
            '- - - - - - - - - - - - - - - -',
            styles: PosStyles(align: PosAlign.center),
          );
          bytes += generator.feed(1);
        }
      }
    }

    // Footer
    bytes += generator.text(
      '================================',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Thank you for your business!',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      '================================',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  /// Show printer selection dialog with scanning
  static Future<bool?> _showPrinterSelectionDialog(BuildContext context) async {
    // Request permissions first
    final hasPermissions = await _printingService.requestPermissions();
    if (!hasPermissions) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth permissions are required to print'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }

    // Show scanning dialog
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PrinterSelectionDialog(),
    );
  }
}

/// Printing progress dialog
class _PrintingDialog extends StatelessWidget {
  const _PrintingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.shopPrimary),
          const SizedBox(height: 16),
          Text(
            'Printing receipt...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// Printer selection dialog with scanning
class _PrinterSelectionDialog extends StatefulWidget {
  const _PrinterSelectionDialog();

  @override
  State<_PrinterSelectionDialog> createState() =>
      _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<_PrinterSelectionDialog> {
  final BluetoothPrintingService _printingService = BluetoothPrintingService();
  List<BluetoothDevice> _printers = [];
  bool _isScanning = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scanForPrinters();
  }

  Future<void> _scanForPrinters() async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      final printers = await _printingService.scanPrinters();
      if (mounted) {
        setState(() {
          _printers = printers;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _connectToPrinter(BluetoothDevice printer) async {
    try {
      // Show connecting dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.shopPrimary),
                SizedBox(height: 16),
                Text('Connecting to printer...'),
              ],
            ),
          ),
        );
      }

      await _printingService.connectToPrinter(printer);
      await _printingService.saveSelectedPrinter(printer);

      if (mounted) {
        Navigator.of(context).pop(); // Close connecting dialog
        Navigator.of(context).pop(true); // Close printer selection dialog
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close connecting dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Printer'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isScanning
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.shopPrimary),
                  SizedBox(height: 16),
                  Text('Scanning for printers...'),
                ],
              )
            : _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: 'Retry',
                    icon: Icons.refresh,
                    onPressed: _scanForPrinters,
                  ),
                ],
              )
            : _printers.isEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bluetooth_disabled,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No printers found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Make sure your printer is turned on and in pairing mode',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: 'Scan Again',
                    icon: Icons.refresh,
                    onPressed: _scanForPrinters,
                  ),
                ],
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _printers.length,
                itemBuilder: (context, index) {
                  final printer = _printers[index];
                  final name = printer.platformName.isNotEmpty
                      ? printer.platformName
                      : printer.remoteId.toString();

                  return ListTile(
                    leading: const Icon(
                      Icons.print,
                      color: AppColors.shopPrimary,
                    ),
                    title: Text(name),
                    subtitle: Text(printer.remoteId.toString()),
                    onTap: () => _connectToPrinter(printer),
                  );
                },
              ),
      ),
      actions: [
        CustomButton(
          variant: ButtonVariant.secondary,
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        if (!_isScanning && _printers.isNotEmpty)
          CustomButton(
            label: 'Refresh',
            icon: Icons.refresh,
            onPressed: _scanForPrinters,
          ),
      ],
    );
  }
}
