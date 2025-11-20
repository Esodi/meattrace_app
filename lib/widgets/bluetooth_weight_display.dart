import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';

/// A beautiful, Bluetooth-only weight display widget
/// Shows weight in a premium, presentable format with large numbers
class BluetoothWeightDisplay extends StatelessWidget {
  final String label;
  final double? weight;
  final bool isConnected;
  final VoidCallback onTap;
  final String unit;
  final Color themeColor; // Theme color for the user role

  const BluetoothWeightDisplay({
    Key? key,
    required this.label,
    this.weight,
    required this.isConnected,
    required this.onTap,
    this.unit = 'kg',
    this.themeColor = Colors.blue, // Default to blue
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generate lighter shades for gradient
    final lightColor = Color.lerp(themeColor, Colors.white, 0.85)!;
    final mediumColor = Color.lerp(themeColor, Colors.white, 0.75)!;
    final darkColor = Color.lerp(themeColor, Colors.black, 0.1)!;
    final borderColor = Color.lerp(themeColor, Colors.white, 0.5)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  ? themeColor.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label and Bluetooth Icon
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isConnected ? 'Connected' : 'Tap to Connect',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Weight Display
            Center(
              child: weight != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          weight!.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 56,
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
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to read weight',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
            
            if (weight != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        size: 16,
                      ),
                      const SizedBox(width: 6),
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}
