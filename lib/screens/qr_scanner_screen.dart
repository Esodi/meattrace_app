import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'product_display_screen.dart';
import '../services/scan_history_service.dart';
import '../widgets/enhanced_back_button.dart';
import '../widgets/order_details_overlay.dart';

class QrScannerScreen extends StatefulWidget {
  final String? source;

  const QrScannerScreen({super.key, this.source});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isFlashOn = false;
  bool _isScanning = true;
  bool _showSuccessAnimation = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to scan QR codes'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }

  void _scanFromGallery() {
    // Mock implementation - in real app, use image_picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gallery scan not implemented yet')),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scanning Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Position QR code within the frame'),
            Text('• Ensure good lighting'),
            Text('• Hold device steady'),
            Text('• Use flash if needed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  String _getFallbackRoute() {
    if (widget.source == 'shop') {
      return '/shop-home';
    } else if (widget.source == 'processor') {
      return '/processor-home';
    } else {
      return '/shop-home'; // default fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        leading: EnhancedBackButton(fallbackRoute: _getFallbackRoute()),
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: _toggleFlash,
            tooltip: _isFlashOn ? 'Turn off flash' : 'Turn on flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // QR Scanner
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.white,
              borderRadius: 16,
              borderLength: 40,
              borderWidth: 8,
              cutOutSize: MediaQuery.of(context).size.width * 0.75,
              overlayColor: Colors.black.withOpacity(0.6),
            ),
          ),

          // Scanning animation overlay
          if (_isScanning)
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
                child: CustomPaint(
                  painter: ScanningAnimationPainter(),
                ),
              ),
            ),

          // Top instruction panel
          Positioned(
            top: MediaQuery.of(context).size.height * 0.08,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan QR Code',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF212121),
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Scan product or order QR codes',
                    style: TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Bottom control panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isScanning ? Icons.pause : Icons.play_arrow,
                        label: _isScanning ? 'Pause' : 'Resume',
                        onPressed: _pauseResumeCamera,
                        color: const Color(0xFFFF9800),
                      ),
                      _buildControlButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onPressed: _scanFromGallery,
                        color: const Color(0xFF2196F3),
                      ),
                      _buildControlButton(
                        icon: Icons.help_outline,
                        label: 'Help',
                        onPressed: _showHelpDialog,
                        color: const Color(0xFF9C27B0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isScanning
                          ? const Color(0xFF4CAF50).withOpacity(0.1)
                          : const Color(0xFFF44336).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isScanning ? Icons.check_circle : Icons.pause_circle,
                          color: _isScanning ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isScanning ? 'Scanning...' : 'Paused',
                          style: TextStyle(
                            color: _isScanning ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Success animation overlay
          if (_showSuccessAnimation)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 100,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: color,
          foregroundColor: Colors.white,
          mini: true,
          child: Icon(icon, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_isScanning && scanData.code != null) {
        _isScanning = false;
        _processScannedData(scanData.code!);
      }
    });
  }

  void _processScannedData(String data) {
    // Check if it's an order QR code
    if (data.startsWith('ORDER_')) {
      final orderId = data.substring(6); // Remove 'ORDER_' prefix

      if (int.tryParse(orderId) != null) {
        _showOrderDetailsOverlay(int.parse(orderId));
      } else {
        _showErrorDialog('Invalid order QR code format.');
      }
      return;
    }

    // Extract product_id from QR data
    String? productId = _extractProductId(data);

    if (productId != null) {
      // Save to scan history
      final scanHistoryService = ScanHistoryService();
      scanHistoryService.addScan(productId);

      // Navigate to product display
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDisplayScreen(productId: productId),
        ),
      ).then((_) {
        // Resume scanning when returning
        _isScanning = true;
      });
    } else {
      _showErrorDialog('Invalid QR Code. Please try again.');
    }
  }

  String? _extractProductId(String data) {
    // Try parsing as JSON first
    try {
      final jsonData = jsonDecode(data);
      if (jsonData is Map && jsonData.containsKey('product_id')) {
        return jsonData['product_id'].toString();
      }
    } catch (e) {
      // Not JSON, continue to other checks
    }

    // Check if it's a URL containing product ID
    if (data.contains('/api/v2/products/')) {
      final uri = Uri.tryParse(data);
      if (uri != null) {
        // Extract product ID from URL path
        final pathSegments = uri.pathSegments;
        final productsIndex = pathSegments.indexOf('products');
        if (productsIndex != -1 && productsIndex + 1 < pathSegments.length) {
          final productId = pathSegments[productsIndex + 1];
          if (int.tryParse(productId) != null) {
            return productId;
          }
        }
      }
    }

    // Assume plain string is product_id
    if (data.isNotEmpty && int.tryParse(data) != null) {
      return data;
    }

    return null;
  }

  void _toggleFlash() async {
    if (controller != null) {
      await controller!.toggleFlash();
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    }
  }

  void _pauseResumeCamera() async {
    if (controller != null) {
      if (_isScanning) {
        await controller!.pauseCamera();
      } else {
        await controller!.resumeCamera();
      }
      setState(() {
        _isScanning = !_isScanning;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _isScanning = true;
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }


  void _showOrderDetailsOverlay(int orderId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => OrderDetailsOverlay(orderId: orderId),
    ).then((_) {
      // Resume scanning when overlay is closed
      _isScanning = true;
    });
  }

  @override
  void dispose() {
    // controller?.dispose(); // No longer necessary with qr_code_scanner_plus
    super.dispose();
  }
}

class ScanningAnimationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.35;

    // Draw scanning lines
    for (int i = 0; i < 4; i++) {
      final y = centerY - radius + (i * radius * 2 / 3);
      if (y >= centerY - radius && y <= centerY + radius) {
        canvas.drawLine(
          Offset(centerX - radius, y),
          Offset(centerX + radius, y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
