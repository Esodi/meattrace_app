import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../core/custom_button.dart';

/// Dialog for rejecting a product with reason and partial quantity support
class ProductRejectionDialog extends StatefulWidget {
  final Product product;

  const ProductRejectionDialog({super.key, required this.product});

  @override
  State<ProductRejectionDialog> createState() => _ProductRejectionDialogState();
}

class _ProductRejectionDialogState extends State<ProductRejectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _quantityController = TextEditingController();

  bool _rejectAll = true;
  double _rejectionQuantity = 0.0;
  double _rejectionWeight = 0.0;
  bool _isWeightBased = false;
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rejectionQuantity = widget.product.quantity.toDouble();
    _rejectionWeight = widget.product.weight ?? 0.0;
    _quantityController.text = _rejectionQuantity.toStringAsFixed(1);
    _weightController.text = _rejectionWeight.toStringAsFixed(1);
    _isWeightBased =
        widget.product.weight != null && widget.product.weight! > 0;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _quantityController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'quantity': _rejectionQuantity,
        'weight': _rejectionWeight,
        'reason': _reasonController.text.trim(),
        'reject_all': _rejectAll,
        'is_weight_based': _isWeightBased,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                        child: Icon(
                          Icons.cancel_outlined,
                          color: AppColors.error,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reject Product',
                              style: AppTypography.headlineSmall(),
                            ),
                            const SizedBox(height: AppTheme.space4),
                            Text(
                              widget.product.name,
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

                  // Product Info
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Batch', widget.product.batchNumber),
                        const SizedBox(height: AppTheme.space8),
                        _buildInfoRow(
                          'Total Quantity',
                          '${widget.product.quantity} units',
                        ),
                        const SizedBox(height: AppTheme.space8),
                        _buildInfoRow(
                          'Weight',
                          '${widget.product.weight ?? 0} ${widget.product.weightUnit}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),

                  // Rejection Type
                  Text(
                    'Rejection Type',
                    style: AppTypography.labelLarge().copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),

                  RadioListTile<bool>(
                    value: true,
                    groupValue: _rejectAll,
                    onChanged: (value) {
                      setState(() {
                        _rejectAll = value!;
                        if (_rejectAll) {
                          _rejectionQuantity = widget.product.quantity
                              .toDouble();
                          _quantityController.text = _rejectionQuantity
                              .toStringAsFixed(1);
                        }
                      });
                    },
                    title: Text(
                      'Reject All (${widget.product.quantity} units)',
                      style: AppTypography.bodyMedium(),
                    ),
                    activeColor: AppColors.error,
                    contentPadding: EdgeInsets.zero,
                  ),

                  RadioListTile<bool>(
                    value: false,
                    groupValue: _rejectAll,
                    onChanged: (value) {
                      setState(() {
                        _rejectAll = value!;
                      });
                    },
                    title: Text(
                      'Partial Rejection',
                      style: AppTypography.bodyMedium(),
                    ),
                    activeColor: AppColors.error,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Partial Quantity Input
                  if (!_rejectAll) ...[
                    const SizedBox(height: AppTheme.space12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: 'Quantity to Reject',
                              suffixText: 'units',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSmall,
                                ),
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            validator: (value) {
                              if (_isWeightBased) return null;
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final quantity = double.tryParse(value);
                              if (quantity == null || quantity <= 0) {
                                return 'Invalid';
                              }
                              if (quantity > widget.product.quantity) {
                                return 'Max ${widget.product.quantity}';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final quantity = double.tryParse(value);
                              if (quantity != null) {
                                setState(() {
                                  _rejectionQuantity = quantity;
                                });
                              }
                            },
                          ),
                        ),
                        if (widget.product.weight != null &&
                            widget.product.weight! > 0) ...[
                          const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              decoration: InputDecoration(
                                labelText: 'Weight to Reject',
                                suffixText: widget.product.weightUnit,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall,
                                  ),
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              validator: (value) {
                                if (!_isWeightBased) return null;
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final weight = double.tryParse(value);
                                if (weight == null || weight <= 0) {
                                  return 'Invalid';
                                }
                                if (weight > widget.product.weight!) {
                                  return 'Max ${widget.product.weight}';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                final weight = double.tryParse(value);
                                if (weight != null) {
                                  setState(() {
                                    _rejectionWeight = weight;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 16,
                          ),
                          const SizedBox(width: AppTheme.space8),
                          Expanded(
                            child: Text(
                              'Remaining ${(widget.product.quantity - _rejectionQuantity).toStringAsFixed(1)} units will be accepted',
                              style: AppTypography.caption().copyWith(
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppTheme.space24),

                  // Rejection Reason
                  Text(
                    'Rejection Reason *',
                    style: AppTypography.labelLarge().copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),

                  TextFormField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText:
                          'e.g., Damaged packaging, Quality issues, Expired...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please provide a rejection reason';
                      }
                      if (value.trim().length < 5) {
                        return 'Reason must be at least 5 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppTheme.space24),

                  // Warning Message
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: Text(
                            'This action cannot be undone. The rejected product will be logged and notified to the processor.',
                            style: AppTypography.caption().copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.space24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.space16,
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          label: 'Reject Product',
                          onPressed: _submit,
                          customColor: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall().copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium().copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
