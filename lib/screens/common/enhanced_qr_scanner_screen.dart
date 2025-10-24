import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart' as perm;
import '../../deferred/qr_scanner_deferred.dart' deferred as qrDeferred show QRView, QrScannerOverlayShape, openAppSettings;
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_text_field.dart';
import 'product_display_screen.dart';
import '../../services/scan_history_service.dart';
// Removed old_ui widget imports - widgets moved to old_ui folder
// import '../../widgets/enhanced_back_button.dart';
// import '../../widgets/order_details_overlay.dart';
// import '../../widgets/loading_indicator.dart';

/// MeatTrace Pro - Enhanced QR Scanner Screen
/// Modern QR scanner with animated frame, flashlight, gallery import, and manual entry

class EnhancedQrScannerScreen extends StatefulWidget {
  final String? source;

  const EnhancedQrScannerScreen({Key? key, this.source}) : super(key: key);

  @override
  State<EnhancedQrScannerScreen> createState() => _EnhancedQrScannerScreenState();
}

class _EnhancedQrScannerScreenState extends State<EnhancedQrScannerScreen> with TickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late Future<void> _libraryLoader;
  bool _isLibraryLoaded = false;
  String? _loadError;
  dynamic controller;
  bool _isFlashOn = false;
  bool _isScanning = true;
  bool _showSuccessAnimation = false;
  
  // Animation controllers
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _libraryLoader = _loadLibrary();
    _initAnimations();
  }

  void _initAnimations() {
    // Scan line animation
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    // Pulse animation for corners
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadLibrary() async {
    try {
      await qrDeferred.loadLibrary();
      setState(() {
        _isLibraryLoaded = true;
      });
      _requestCameraPermission();
    } catch (e) {
      setState(() {
        _loadError = e.toString();
      });
    }
  }

  Future<void> _requestCameraPermission() async {
    if (!_isLibraryLoaded) return;
    final status = await perm.Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Row(
          children: [
            Icon(
              Icons.camera_alt,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppTheme.space12),
            const Text('Camera Permission'),
          ],
        ),
        content: Text(
          'MeatTrace Pro needs camera access to scan QR codes. Please grant camera permission in settings.',
          style: AppTypography.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge(color: AppColors.textSecondary),
            ),
          ),
          PrimaryButton(
            label: 'Open Settings',
            onPressed: () {
              Navigator.of(context).pop();
              qrDeferred.openAppSettings();
            },
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _scanFromGallery() {
    // TODO: Implement gallery picker with image_picker package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: AppTheme.space12),
            const Expanded(
              child: Text('Gallery scan feature coming soon!'),
            ),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Row(
          children: [
            Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppTheme.space12),
            const Text('Manual Entry'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter product ID or QR code data manually',
              style: AppTypography.bodyMedium(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppTheme.space16),
            CustomTextField(
              controller: controller,
              label: 'Product ID',
              hint: 'Enter product ID or scan data',
              keyboardType: TextInputType.text,
              prefixIcon: const Icon(Icons.numbers),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge(color: AppColors.textSecondary),
            ),
          ),
          PrimaryButton(
            label: 'Submit',
            onPressed: () {
              final data = controller.text.trim();
              if (data.isNotEmpty) {
                Navigator.of(context).pop();
                _processScannedData(data);
              }
            },
            size: ButtonSize.small,
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
      return '/shop-home';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loadError != null) {
      return _buildErrorScreen();
    }

    if (!_isLibraryLoaded) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                ),
                onPressed: _toggleFlash,
                tooltip: _isFlashOn ? 'Turn off flash' : 'Turn on flash',
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR Scanner Camera View
          Positioned.fill(
            child: qrDeferred.QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: qrDeferred.QrScannerOverlayShape(
                borderColor: Colors.transparent,
                borderRadius: 0,
                borderLength: 0,
                borderWidth: 0,
                cutOutSize: MediaQuery.of(context).size.width * 0.75,
                overlayColor: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),

          // Animated Scanning Frame
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.width * 0.75,
                  child: CustomPaint(
                    painter: ScanFramePainter(
                      pulseValue: _pulseAnimation.value,
                      isScanning: _isScanning,
                    ),
                    child: AnimatedBuilder(
                      animation: _scanLineAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: ScanLinePainter(
                            progress: _scanLineAnimation.value,
                            isScanning: _isScanning,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Top Instruction Panel
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: AppTheme.space24,
            right: AppTheme.space24,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    CustomIcons.MEATTRACE_ICON,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Scan QR Code',
                    style: AppTypography.headlineSmall(
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    'Position the QR code within the frame',
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: AppTheme.space20,
                left: AppTheme.space20,
                right: AppTheme.space20,
                bottom: MediaQuery.of(context).padding.bottom + AppTheme.space20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLarge),
                  topRight: Radius.circular(AppTheme.radiusLarge),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space16,
                      vertical: AppTheme.space8,
                    ),
                    decoration: BoxDecoration(
                      color: _isScanning
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isScanning ? AppColors.success : AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Text(
                          _isScanning ? 'Scanning Active' : 'Scanning Paused',
                          style: AppTypography.labelMedium(
                            color: _isScanning ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.space20),
                  
                  // Control Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: _isScanning ? Icons.pause_circle : Icons.play_circle,
                        label: _isScanning ? 'Pause' : 'Resume',
                        onPressed: _pauseResumeCamera,
                        color: AppColors.warning,
                      ),
                      _buildActionButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onPressed: _scanFromGallery,
                        color: AppColors.info,
                      ),
                      _buildActionButton(
                        icon: Icons.edit,
                        label: 'Manual',
                        onPressed: _showManualEntryDialog,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Success Animation Overlay
          if (_showSuccessAnimation)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 100,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppTheme.space16),
                      Text(
                        'QR Code Scanned!',
                        style: AppTypography.headlineSmall(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: IconButton(
            icon: Icon(icon, size: 28),
            onPressed: onPressed,
            color: color,
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          label,
          style: AppTypography.labelSmall(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.space16),
            Text('Loading QR scanner...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: AppColors.error,
              ),
              const SizedBox(height: AppTheme.space16),
              Text(
                'Failed to load QR scanner',
                style: AppTypography.headlineSmall(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                _loadError!,
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space24),
              PrimaryButton(
                label: 'Retry',
                onPressed: () {
                  setState(() {
                    _loadError = null;
                    _libraryLoader = _loadLibrary();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onQRViewCreated(dynamic controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_isScanning && scanData.code != null) {
        setState(() {
          _isScanning = false;
          _showSuccessAnimation = true;
        });
        
        // Hide success animation after delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _showSuccessAnimation = false;
            });
            _processScannedData(scanData.code!);
          }
        });
      }
    });
  }

  void _processScannedData(String data) {
    // Check if it's an order QR code
    if (data.startsWith('ORDER_')) {
      final orderId = data.substring(6);
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

      // Navigate to product display screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDisplayScreen(
            productId: productId,
            source: widget.source,
          ),
        ),
      ).then((_) {
        // Resume scanning when returning
        if (mounted) {
          setState(() {
            _isScanning = true;
          });
        }
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
    if (data.contains('/api/v2/products/') || data.contains('/api/product-info/')) {
      final uri = Uri.tryParse(data);
      if (uri != null) {
        final pathSegments = uri.pathSegments;
        final productsIndex = pathSegments.indexOf('products');
        final productInfoIndex = pathSegments.indexOf('product-info');
        
        if (productsIndex != -1 && productsIndex + 1 < pathSegments.length) {
          final productId = pathSegments[productsIndex + 1];
          if (int.tryParse(productId) != null) {
            return productId;
          }
        } else if (productInfoIndex != -1 && productInfoIndex + 1 < pathSegments.length) {
          final productId = pathSegments[productInfoIndex + 1];
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppTheme.space12),
            const Text('Scan Error'),
          ],
        ),
        content: Text(
          message,
          style: AppTypography.bodyMedium(),
        ),
        actions: [
          PrimaryButton(
            label: 'Try Again',
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isScanning = true;
              });
            },
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _showOrderDetailsOverlay(int orderId) {
    // TODO: Implement order details dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text('Order #$orderId'),
        content: const Text('Order details will be displayed here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    ).then((_) {
      setState(() {
        _isScanning = true;
      });
    });
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

/// Custom painter for animated scan frame with pulsing corners
class ScanFramePainter extends CustomPainter {
  final double pulseValue;
  final bool isScanning;

  ScanFramePainter({required this.pulseValue, required this.isScanning});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isScanning
          ? AppColors.success.withOpacity(pulseValue)
          : AppColors.warning.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 40.0;
    const cornerRadius = 12.0;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, cornerRadius)
        ..quadraticBezierTo(0, 0, cornerRadius, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - cornerRadius, 0)
        ..quadraticBezierTo(size.width, 0, size.width, cornerRadius)
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - cornerRadius)
        ..quadraticBezierTo(0, size.height, cornerRadius, size.height)
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width - cornerRadius, size.height)
        ..quadraticBezierTo(size.width, size.height, size.width, size.height - cornerRadius)
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(ScanFramePainter oldDelegate) =>
      pulseValue != oldDelegate.pulseValue || isScanning != oldDelegate.isScanning;
}

/// Custom painter for animated scan line
class ScanLinePainter extends CustomPainter {
  final double progress;
  final bool isScanning;

  ScanLinePainter({required this.progress, required this.isScanning});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isScanning) return;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppColors.success.withValues(alpha: 0.0),
          AppColors.success.withValues(alpha: 0.8),
          AppColors.success.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 3))
      ..style = PaintingStyle.fill;

    final y = size.height * progress;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 1.5, size.width, 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(ScanLinePainter oldDelegate) =>
      progress != oldDelegate.progress || isScanning != oldDelegate.isScanning;
}
