import 'package:flutter/material.dart';
import '../../utils/app_typography.dart';

/// A beautiful Bluetooth scale weight display widget.
/// While connected, [weight] is the live, continuously-updating reading
/// straight off the scale — no tap required. The "Record" button captures
/// whatever that live value is at the moment it's pressed into
/// [recordedWeight] via [onWeightChanged]. A hidden long-press on the
/// display still opens a manual-entry override for when a scale genuinely
/// isn't available.
class BluetoothWeightDisplay extends StatelessWidget {
  final String label;
  final double? weight;
  final double? recordedWeight;
  final bool isConnected;
  final VoidCallback onTap;
  final ValueChanged<double?>? onWeightChanged;
  final String unit;
  final Color themeColor; // Theme color for the user role

  const BluetoothWeightDisplay({
    super.key,
    required this.label,
    this.weight,
    this.recordedWeight,
    required this.isConnected,
    required this.onTap,
    this.onWeightChanged,
    this.unit = 'kg',
    this.themeColor = Colors.blue, // Default to blue
  });

  Future<void> _showManualInputDialog(BuildContext context) async {
    final initial = recordedWeight ?? weight;
    final controller = TextEditingController(
      text: initial != null ? initial.toStringAsFixed(2) : '',
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
            if (recordedWeight != null)
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
    final canRecord = isConnected && weight != null && onWeightChanged != null;

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
          // Label, Bluetooth Icon and connection chip
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
              if (isConnected) ...[
                _LiveBadge(color: themeColor),
                const SizedBox(width: 6),
              ],
              // Bluetooth Status Chip (tap to connect when not connected)
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
                        isConnected ? 'Connected' : 'Connect Scale',
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
            ],
          ),
          const SizedBox(height: 16),

          // Live weight reading. Updates automatically while connected — no
          // tap needed. Long-press opens a manual-entry override,
          // intentionally not advertised in the UI: scale reading is the
          // normal path, this is only a fallback for when a scale isn't
          // available.
          GestureDetector(
            onLongPress: onWeightChanged != null
                ? () => _showManualInputDialog(context)
                : null,
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
                          isConnected
                              ? 'Waiting for a reading from the scale…'
                              : 'Connect a scale to read weight',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Record button — captures the live reading above at the moment
          // it's pressed.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canRecord
                  ? () => onWeightChanged?.call(weight)
                  : null,
              icon: const Icon(Icons.fiber_manual_record, size: 18),
              label: const Text('Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          if (recordedWeight != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                        'Recorded: ${recordedWeight!.toStringAsFixed(2)} $unit',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Small pulsing "LIVE" indicator shown while the scale is connected and
/// streaming readings, so it's visually obvious the number is live rather
/// than a static value.
class _LiveBadge extends StatefulWidget {
  final Color color;
  const _LiveBadge({required this.color});

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _controller.drive(CurveTween(curve: Curves.easeInOut)),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: widget.color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
