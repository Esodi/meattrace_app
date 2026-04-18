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
  static Future<void> printSaleReceipt(
    BuildContext context,
    Sale sale, {
    String? shopName,
  }) async {
    // Capture root navigator to safely close dialogs without popping the page
    final navigator = Navigator.of(context, rootNavigator: true);

    // Show printing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const _PrintingDialog(),
    );

    try {
      // Check if printer is connected
      if (!_printingService.isConnected) {
        // Try to connect to saved printer
        final connected = await _printingService.connectToSavedPrinter();

        if (!connected) {
          // No saved printer, show printer selection
          navigator.pop(); // Close printing dialog using captured navigator

          if (context.mounted) {
            final shouldPrint = await _showPrinterSelectionDialog(context);
            if (shouldPrint != true) return;

            // Show printing dialog again
            showDialog(
              context: context,
              barrierDismissible: false,
              useRootNavigator: true,
              builder: (_) => const _PrintingDialog(),
            );
          } else {
            return;
          }
        }
      }

      // Generate receipt bytes
      final bytes = await _generateReceiptBytes(sale, shopName: shopName);

      // Print receipt
      await _printingService.printerManager.writeBytes(bytes);

      // Close printing dialog safely
      navigator.pop();

      // Show success message if context is still valid
      if (context.mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt printed successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      // Ensure dialog is closed even on error
      try {
        navigator.pop();
      } catch (_) {
        // Ignore if already popped
      }

      // Show error message if context is still valid
      if (context.mounted) {
        if (context.mounted) {
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
  }

  /// Generate ESC/POS receipt bytes
  static Future<Uint8List> _generateReceiptBytes(
    Sale sale, {
    String? shopName,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final currencyFormat = NumberFormat('#,###');

    List<int> bytes = [];

    // Header
    bytes += generator.text(
      '================================',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      shopName?.toUpperCase() ?? 'NYAMA TAMU',
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

    // Receipt Number / UUID
    if (sale.receiptUuid != null) {
      bytes += generator.text(
        'Receipt #: ${sale.receiptUuid!.substring(0, 8).toUpperCase()}',
        styles: PosStyles(align: PosAlign.left),
      );
    } else {
      bytes += generator.text(
        'Sale #: ${sale.id ?? 'N/A'}',
        styles: PosStyles(align: PosAlign.left),
      );
    }

    // Cashier
    bytes += generator.text(
      'Cashier ID: ${sale.soldBy}',
      styles: PosStyles(align: PosAlign.left),
    );

    bytes += generator.text(
      '--------------------------------',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);

    // Items list (Table Layout)
    // 32 chars on 58mm: 14 for name, 6 for qty/wt, 10 for price
    bytes += generator.row([
      PosColumn(
        text: 'Item',
        width: 6,
        styles: PosStyles(bold: true, align: PosAlign.left),
      ),
      PosColumn(
        text: 'Qty/Wt',
        width: 3,
        styles: PosStyles(bold: true, align: PosAlign.right),
      ),
      PosColumn(
        text: 'Total',
        width: 3,
        styles: PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);
    bytes += generator.text(
      '--------------------------------',
      styles: PosStyles(align: PosAlign.center),
    );

    for (final item in sale.items) {
      String name = item.productName ?? 'Product';
      // Truncate name if too long to fit 58mm cleanly in column
      if (name.length > 14) name = name.substring(0, 14);

      String qtyStr = item.weight > 0
          ? '${item.weight.toStringAsFixed(1)}${item.weightUnit}'
          : item.quantity.toStringAsFixed(0);
      String totalStr = currencyFormat.format(item.subtotal);

      bytes += generator.row([
        PosColumn(
          text: name,
          width: 6,
          styles: PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: qtyStr,
          width: 3,
          styles: PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: totalStr,
          width: 3,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);

      if (item.batchNumber != null) {
        bytes += generator.text(
          '  [Batch: ${item.batchNumber}]',
          styles: PosStyles(align: PosAlign.left, height: PosTextSize.size1),
        );
      }
    }

    bytes += generator.text(
      '--------------------------------',
      styles: PosStyles(align: PosAlign.center),
    );

    // Total
    bytes += generator.row([
      PosColumn(
        text: 'TOTAL:',
        width: 6,
        styles: PosStyles(align: PosAlign.left, bold: true),
      ),
      PosColumn(
        text: 'TZS ${currencyFormat.format(sale.totalAmount)}',
        width: 6,
        styles: PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    bytes += generator.text(
      'Payment: ${sale.paymentMethod.toUpperCase()}',
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

    // Per-item traceability QRs — same format the processor prints for each
    // product, so scanning either produces the same traceability page.
    if (sale.items.isNotEmpty) {
      bytes += generator.text(
        '================================',
        styles: PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        'TRACE EACH ITEM',
        styles: PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        'Scan each QR to verify origin',
        styles: PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      for (final item in sale.items) {
        final label = item.productName ?? 'Product #${item.product}';
        final truncated = label.length > 30 ? label.substring(0, 30) : label;
        bytes += generator.text(
          truncated,
          styles: PosStyles(align: PosAlign.center, bold: true),
        );
        if (item.batchNumber != null) {
          bytes += generator.text(
            'Batch: ${item.batchNumber}',
            styles: PosStyles(align: PosAlign.center),
          );
        }
        bytes += generator.qrcode(
          '${Constants.baseUrl}/product-info/view/${item.product}/',
          size: QRSize.Size4,
          cor: QRCorrection.L,
        );
        bytes += generator.feed(1);
      }
    }

    // Footer
    bytes += generator.text(
      '================================',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Thank you for shopping with us!',
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bluetooth permissions are required to print'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
      return false;
    }

    // Show scanning dialog on root navigator
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => _PrinterSelectionDialog(),
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
    // Capture the root navigator BEFORE showing any nested dialog so that
    // subsequent .pop() calls only dismiss dialog routes, not the page itself.
    final rootNav = Navigator.of(context, rootNavigator: true);

    try {
      // Show connecting dialog on the root navigator overlay
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (_) => const AlertDialog(
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
        rootNav.pop(); // Close connecting dialog
        rootNav.pop(true); // Close printer selection dialog → returns true
      }
    } catch (e) {
      if (mounted) {
        rootNav.pop(); // Close connecting dialog only
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to connect: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
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
