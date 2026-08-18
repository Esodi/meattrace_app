import 'package:flutter/material.dart';
import '../../utils/app_typography.dart';

/// A beautiful Bluetooth scale and manual weight display widget
/// Shows weight in a presentable format with large numbers,
/// Bluetooth scale connection status, and manual weight entry options.
class BluetoothWeightDisplay extends StatelessWidget {
  final String label;
  final double? weight;
  final bool isConnected;
  final VoidCallback onTap;
  final ValueChanged<double?>? onWeightChanged;
  final String unit;
  final Color themeColor; // Theme color for the user role

  const BluetoothWeightDisplay({
    super.key,
    required this.label,
    this.weight,
    required this.isConnected,
    required this.onTap,
    this.onWeightChanged,
    this.unit = 'kg',
    this.themeColor = Colors.blue, // Default to blue
  });

  Future<void> _showManualInputDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: weight != null ? weight!.toStringAsFixed(2) : '',
    );

    final result = await showDialog<double?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit_note, color: themeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Manual Weight Input',
                  style: AppTypography.titleLarge(),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter weight manually for $label:',
                style: AppTypography.bodyMedium(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Weight ($unit)',
                  hintText: 'e.g. 150.50',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themeColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.scale, color: themeColor),
                  suffixText: unit,
                  suffixStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (weight != null)
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear'),
                onPressed: () => Navigator.of(context).pop(-1.0),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  Navigator.of(context).pop(null);
                } else {
                  final val = double.tryParse(text);
                  Navigator.of(context).pop(val);
                }
              },
              child: const Text('Save Weight'),
            ),
          ],
        );
      },
    );

    if (result == -1.0) {
      onWeightChanged?.call(null);
    } else if (result != null) {
      onWeightChanged?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate lighter shades for gradient
    final lightColor = Color.lerp(themeColor, Colors.white, 0.85)!;
    final mediumColor = Color.lerp(themeColor, Colors.white, 0.75)!;
    final darkColor = Color.lerp(themeColor, Colors.black, 0.1)!;
    final borderColor = Color.lerp(themeColor, Colors.white, 0.5)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isConnected
              ? [lightColor, mediumColor]
              : [Colors.grey.shade50, Colors.grey.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? borderColor : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isConnected
                ? themeColor.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label, Bluetooth Icon and Manual Option
          Row(
            children: [
              Icon(
                Icons.monitor_weight_outlined,
                color: isConnected ? darkColor : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelLarge(
                    color: isConnected ? darkColor : Colors.grey.shade700,
                  ),
                ),
              ),
              // Bluetooth Status Chip (Tap to connect / read)
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isConnected ? themeColor : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bluetooth,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isConnected ? 'Connected' : 'Scale',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onWeightChanged != null) ...[
                const SizedBox(width: 6),
                // Manual Entry Chip
                InkWell(
                  onTap: () => _showManualInputDialog(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: themeColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.keyboard_alt_outlined,
                          color: themeColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Manual',
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Weight Display - Tap area triggers Bluetooth read by default
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: weight != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          weight!.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: darkColor,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: themeColor,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.scale,
                          size: 44,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          onWeightChanged != null
                              ? 'Tap scale or enter weight manually'
                              : 'Tap to read weight from scale',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Status & Manual Input Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (weight != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Weight Recorded',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onWeightChanged != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showManualInputDialog(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: themeColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: themeColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Edit Manually',
                            style: TextStyle(
                              color: themeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ] else if (onWeightChanged != null) ...[
                OutlinedButton.icon(
                  icon: Icon(Icons.edit_note, size: 16, color: themeColor),
                  label: Text(
                    'Input Weight Manually',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: themeColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: themeColor.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _showManualInputDialog(context),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

