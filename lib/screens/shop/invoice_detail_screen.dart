import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../widgets/core/custom_button.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InvoiceProvider>(
        context,
        listen: false,
      ).loadInvoice(widget.invoiceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Invoice Details', style: AppTypography.headlineMedium()),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'record_payment',
                child: Text('Record Payment'),
              ),
              const PopupMenuItem(
                value: 'convert_sale',
                child: Text('Convert to Sale'),
              ),
              const PopupMenuItem(
                value: 'download_pdf',
                child: Text('Download PDF'),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: Text('Cancel Invoice'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentInvoice == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final invoice = provider.currentInvoice;
          if (invoice == null) {
            return const Center(child: Text('Invoice not found'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadInvoice(widget.invoiceId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCard(invoice),
                const SizedBox(height: 16),
                _buildItemsCard(invoice),
                const SizedBox(height: 16),
                _buildPaymentsCard(invoice),
                const SizedBox(height: 16),
                _buildSummaryCard(invoice),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(Invoice invoice) {
    final statusColor = _getStatusColor(invoice.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    invoice.statusDisplay,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (invoice.customerContact != null) ...[
              _buildInfoRow('Customer Contact', invoice.customerContact!),
              const SizedBox(height: 8),
            ],
            _buildInfoRow(
              'Issue Date',
              DateFormat('MMM dd, yyyy').format(invoice.issueDate),
            ),
            if (invoice.dueDate != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'Due Date',
                DateFormat('MMM dd, yyyy').format(invoice.dueDate!),
              ),
            ],
            if (invoice.paymentTerms != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Payment Terms', invoice.paymentTerms!),
            ],
            if (invoice.notes != null) ...[
              const Divider(height: 24),
              Text(
                'Notes:',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(invoice.notes!, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildItemsCard(Invoice invoice) {
    final currencyFormatter = NumberFormat.currency(
      symbol: 'TZS ',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...invoice.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName ?? 'Product ${item.product}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${item.quantity.toStringAsFixed(1)} kg × ${currencyFormatter.format(item.unitPrice)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormatter.format(item.subtotal),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsCard(Invoice invoice) {
    final currencyFormatter = NumberFormat.currency(
      symbol: 'TZS ',
      decimalDigits: 0,
    );

    if (invoice.payments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...invoice.payments.map((payment) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.payment),
                title: Text(currencyFormatter.format(payment.amount)),
                subtitle: Text(
                  '${payment.paymentMethod.toUpperCase()} • ${DateFormat('MMM dd, yyyy').format(payment.paymentDate)}',
                ),
                trailing: payment.recordedByName != null
                    ? Text(
                        'By ${payment.recordedByName}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      )
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Invoice invoice) {
    final currencyFormatter = NumberFormat.currency(
      symbol: 'TZS ',
      decimalDigits: 0,
    );

    return Card(
      color: AppColors.shopPrimary.withOpacity(0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow(
              'Subtotal',
              currencyFormatter.format(invoice.subtotal),
            ),
            if (invoice.taxAmount > 0) ...[
              const SizedBox(height: 8),
              _buildSummaryRow(
                'Tax',
                currencyFormatter.format(invoice.taxAmount),
              ),
            ],
            const Divider(height: 24),
            _buildSummaryRow(
              'Total',
              currencyFormatter.format(invoice.totalAmount),
              isTotal: true,
            ),
            if (invoice.amountPaid > 0) ...[
              const SizedBox(height: 8),
              _buildSummaryRow(
                'Paid',
                currencyFormatter.format(invoice.amountPaid),
                color: Colors.green,
              ),
            ],
            if (invoice.balanceDue > 0) ...[
              const SizedBox(height: 8),
              _buildSummaryRow(
                'Balance Due',
                currencyFormatter.format(invoice.balanceDue),
                color: Colors.red,
                isTotal: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'record_payment':
        _showRecordPaymentDialog();
        break;
      case 'convert_sale':
        _showConvertToSaleDialog();
        break;
      case 'download_pdf':
        _downloadPdf();
        break;
      case 'cancel':
        _showCancelDialog();
        break;
    }
  }

  Future<void> _downloadPdf() async {
    final provider = Provider.of<InvoiceProvider>(context, listen: false);
    final invoice = provider.currentInvoice;
    if (invoice == null) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF...'),
          duration: Duration(seconds: 2),
        ),
      );

      if (invoice.id == null) {
        throw Exception('Invoice ID is missing');
      }
      final pdfBytes = await provider.downloadInvoicePdf(invoice.id!);

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Invoice_${invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(pdfBytes);

      // Using share_plus to open/save the file
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Invoice ${invoice.invoiceNumber}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _showRecordPaymentDialog() {
    final invoice = Provider.of<InvoiceProvider>(
      context,
      listen: false,
    ).currentInvoice;
    if (invoice == null) return;

    final amountController = TextEditingController(
      text: invoice.balanceDue.toString(),
    );
    String paymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (paymentCtx) {
        return AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (Max: ${invoice.balanceDue})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: ['cash', 'mobile_money', 'bank_transfer', 'card'].map((
                  method,
                ) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) => paymentMethod = value!,
              ),
            ],
          ),
          actions: [
            CustomButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(paymentCtx).pop(),
              variant: ButtonVariant.text,
              customColor: AppColors.textSecondary,
            ),
            CustomButton(
              label: 'Record',
              onPressed: () async {
                try {
                  await Provider.of<InvoiceProvider>(
                    context, // Use outer context
                    listen: false,
                  ).recordPayment(
                    invoiceId: widget.invoiceId,
                    amount: double.parse(amountController.text),
                    paymentMethod: paymentMethod,
                  );
                  if (mounted) {
                    Navigator.of(paymentCtx).pop(); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment recorded successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              variant: ButtonVariant.primary,
              customColor: AppColors.shopPrimary,
              size: ButtonSize.small,
            ),
          ],
        );
      },
    );
  }

  void _showConvertToSaleDialog() {
    String paymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (saleCtx) {
        return AlertDialog(
          title: const Text('Convert to Sale'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This will create a sale from this invoice and mark it as completed.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: ['cash', 'mobile_money', 'bank_transfer', 'card'].map((
                  method,
                ) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) => paymentMethod = value!,
              ),
            ],
          ),
          actions: [
            CustomButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(saleCtx).pop(),
              variant: ButtonVariant.text,
              customColor: AppColors.textSecondary,
            ),
            CustomButton(
              label: 'Convert',
              onPressed: () async {
                try {
                  await Provider.of<InvoiceProvider>(
                    context, // Use outer context
                    listen: false,
                  ).convertToSale(
                    invoiceId: widget.invoiceId,
                    paymentMethod: paymentMethod,
                  );
                  if (mounted) {
                    Navigator.of(saleCtx).pop(); // Close dialog
                    if (mounted) {
                      context.pop(); // Close detail screen using GoRouter
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Converted to sale successfully'),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              variant: ButtonVariant.primary,
              customColor: AppColors.shopPrimary,
              size: ButtonSize.small,
            ),
          ],
        );
      },
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (cancelCtx) {
        return AlertDialog(
          title: const Text('Cancel Invoice'),
          content: const Text(
            'Are you sure you want to cancel this invoice? This action cannot be undone.',
          ),
          actions: [
            CustomButton(
              label: 'No',
              onPressed: () => Navigator.of(cancelCtx).pop(),
              variant: ButtonVariant.text,
              customColor: AppColors.textSecondary,
            ),
            CustomButton(
              label: 'Yes, Cancel',
              onPressed: () async {
                try {
                  await Provider.of<InvoiceProvider>(
                    context, // Use outer context
                    listen: false,
                  ).cancelInvoice(widget.invoiceId);
                  if (mounted) {
                    Navigator.of(cancelCtx).pop(); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice cancelled')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              variant: ButtonVariant.primary,
              customColor: AppColors.error,
              size: ButtonSize.small,
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
