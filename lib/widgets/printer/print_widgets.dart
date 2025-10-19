import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// Print preview widget for different label templates
class PrintPreview extends StatelessWidget {
  final PrintPreviewType type;
  final Map<String, String> data;

  const PrintPreview({
    super.key,
    required this.type,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium - 2),
        child: _buildPreviewContent(),
      ),
    );
  }

  Widget _buildPreviewContent() {
    switch (type) {
      case PrintPreviewType.animalTag:
        return _buildAnimalTagPreview();
      case PrintPreviewType.productLabel:
        return _buildProductLabelPreview();
      case PrintPreviewType.transferReceipt:
        return _buildTransferReceiptPreview();
      case PrintPreviewType.qrCodeOnly:
        return _buildQRCodePreview();
    }
  }

  Widget _buildAnimalTagPreview() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'MEATTRACE PRO',
                  style: AppTypography.headlineSmall().copyWith(
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2), width: 2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(Icons.qr_code, size: 50),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          
          // Animal details
          _buildPreviewField('Tag ID', data['tagId'] ?? 'CT-2024-001'),
          _buildPreviewField('Species', data['species'] ?? 'Cattle'),
          _buildPreviewField('Date', data['date'] ?? '18/10/2025'),
        ],
      ),
    );
  }

  Widget _buildProductLabelPreview() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEATTRACE PRO',
                      style: AppTypography.headlineSmall().copyWith(
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    _buildPreviewField('Product', data['productName'] ?? 'Beef Cut'),
                    _buildPreviewField('Batch', data['batchNumber'] ?? 'BCH-2024-001'),
                    _buildPreviewField('Weight', data['weight'] ?? '2.5 kg'),
                    _buildPreviewField('Cut Date', data['cutDate'] ?? '18/10/2025'),
                    _buildPreviewField('Expiry', data['expiry'] ?? '25/10/2025'),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2), width: 2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(Icons.qr_code, size: 70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransferReceiptPreview() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text(
                  'MEATTRACE PRO',
                  style: AppTypography.headlineLarge().copyWith(
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  'TRANSFER RECEIPT',
                  style: AppTypography.headlineSmall().copyWith(
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: AppTheme.space24),
          
          // Transfer details
          _buildPreviewField('Transfer ID', data['transferId'] ?? 'TRF-2024-001'),
          _buildPreviewField('From', data['from'] ?? 'Green Valley Farm'),
          _buildPreviewField('To', data['to'] ?? 'Premium Processors Ltd'),
          _buildPreviewField('Date', data['date'] ?? '18/10/2025 14:30'),
          const SizedBox(height: AppTheme.space12),
          
          _buildPreviewField('Items', data['itemCount'] ?? '5 animals'),
          _buildPreviewField('Total Weight', data['totalWeight'] ?? '2,750 kg'),
          
          const Divider(height: AppTheme.space24),
          
          // QR code
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2), width: 2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: const Icon(Icons.qr_code, size: 90),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodePreview() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2), width: 3),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(Icons.qr_code, size: 140),
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            data['code'] ?? 'MT-2024-001',
            style: AppTypography.headlineSmall(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTypography.bodyMedium().copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium().copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// Print preview type enum
enum PrintPreviewType {
  animalTag,
  productLabel,
  transferReceipt,
  qrCodeOnly,
}

/// Quick print button widget
class QuickPrintButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const QuickPrintButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: (color ?? AppColors.info).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color ?? AppColors.info,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                label,
                style: AppTypography.bodyMedium().copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Printer status indicator
class PrinterStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String? printerName;
  final VoidCallback? onTap;

  const PrinterStatusIndicator({
    super.key,
    required this.isConnected,
    this.printerName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space8,
        ),
        decoration: BoxDecoration(
          color: isConnected
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isConnected ? AppColors.success : AppColors.warning,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: isConnected ? AppColors.success : AppColors.warning,
              size: 16,
            ),
            const SizedBox(width: AppTheme.space8),
            Text(
              isConnected
                  ? printerName ?? 'Printer Connected'
                  : 'No Printer',
              style: AppTypography.labelMedium().copyWith(
                color: isConnected ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppTheme.space4),
              Icon(
                Icons.settings,
                color: isConnected ? AppColors.success : AppColors.warning,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
