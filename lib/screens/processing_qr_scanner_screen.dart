import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import '../services/api_service.dart';
import '../widgets/enhanced_back_button.dart';
import '../models/product.dart';
import '../models/animal.dart';

class ProcessingQrScannerScreen extends StatefulWidget {
  const ProcessingQrScannerScreen({super.key});

  @override
  State<ProcessingQrScannerScreen> createState() => _ProcessingQrScannerScreenState();
}

class _ProcessingQrScannerScreenState extends State<ProcessingQrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isFlashOn = false;
  bool _isScanning = true;
  bool _showSuccessAnimation = false;
  final ApiService _apiService = ApiService();

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

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing QR Scanner'),
        leading: const EnhancedBackButton(fallbackRoute: '/processor-home'),
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
                    'Processing Stage Scanner',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF212121),
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Scan animal, product, or batch QR codes',
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
          heroTag: null,
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

  void _processScannedData(String data) async {
    final navigator = Navigator.of(context);
    try {
      // Show loading indicator
      _showLoadingDialog();

      // Determine what type of QR code this is and fetch appropriate data
      final result = await _identifyAndFetchData(data);

      // Hide loading dialog
      navigator.pop();

      if (result != null) {
        // Show success animation briefly
        setState(() {
          _showSuccessAnimation = true;
        });
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        setState(() {
          _showSuccessAnimation = false;
        });

        // Navigate to processing details screen
        navigator.push(
          MaterialPageRoute(
            builder: (context) => ProcessingDetailsScreen(data: result),
          ),
        ).then((_) {
          // Resume scanning when returning
          _isScanning = true;
        });
      } else {
        _showErrorDialog('Unable to identify or fetch data for this QR code.');
      }
    } catch (e) {
      // Hide loading dialog if still showing
      if (mounted && navigator.canPop()) {
        navigator.pop();
      }
      if (mounted) {
        _showErrorDialog('Error processing QR code: ${e.toString()}');
      }
    }
  }

  Future<Map<String, dynamic>?> _identifyAndFetchData(String data) async {
    // Try to identify what type of QR code this is
    
    // Check if it's a product URL
    if (data.contains('/api/v2/products/')) {
      final productId = _extractProductId(data);
      if (productId != null) {
        try {
          final product = await _apiService.fetchProduct(productId);
          return {
            'type': 'product',
            'data': product,
            'id': productId,
          };
        } catch (e) {
          print('Error fetching product: $e');
        }
      }
    }
    
    // Check if it's an animal ID
    if (data.startsWith('ANIMAL_') || data.contains('animal')) {
      try {
        // Try to extract animal ID
        String? animalId;
        if (data.startsWith('ANIMAL_')) {
          animalId = data;
        } else {
          // Try parsing as JSON
          try {
            final jsonData = jsonDecode(data);
            animalId = jsonData['animal_id']?.toString();
          } catch (e) {
            // Not JSON, might be a URL or other format
            if (data.contains('/animals/')) {
              final uri = Uri.tryParse(data);
              if (uri != null) {
                final pathSegments = uri.pathSegments;
                final animalsIndex = pathSegments.indexOf('animals');
                if (animalsIndex != -1 && animalsIndex + 1 < pathSegments.length) {
                  animalId = pathSegments[animalsIndex + 1];
                }
              }
            }
          }
        }
        
        if (animalId != null) {
          final animal = await _apiService.fetchAnimal(animalId);
          return {
            'type': 'animal',
            'data': animal,
            'id': animalId,
          };
        }
      } catch (e) {
        print('Error fetching animal: $e');
      }
    }
    
    // Check if it's a batch number or processing stage identifier
    if (data.startsWith('BATCH_') || data.contains('batch')) {
      try {
        String? batchNumber;
        if (data.startsWith('BATCH_')) {
          batchNumber = data.substring(6); // Remove 'BATCH_' prefix
        } else {
          try {
            final jsonData = jsonDecode(data);
            batchNumber = jsonData['batch_number']?.toString();
          } catch (e) {
            // Assume the whole string is the batch number
            batchNumber = data;
          }
        }
        
        if (batchNumber != null) {
          final products = await _apiService.fetchProductsByBatch(batchNumber);
          return {
            'type': 'batch',
            'data': products,
            'id': batchNumber,
          };
        }
      } catch (e) {
        print('Error fetching batch: $e');
      }
    }
    
    // Try as a generic product ID
    if (int.tryParse(data) != null) {
      try {
        final product = await _apiService.fetchProduct(data);
        return {
          'type': 'product',
          'data': product,
          'id': data,
        };
      } catch (e) {
        print('Error fetching product by ID: $e');
      }
    }
    
    return null;
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

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing QR code...'),
          ],
        ),
      ),
    );
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Processing Scanner Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This scanner can read:'),
            SizedBox(height: 8),
            Text('• Product QR codes'),
            Text('• Animal ID codes'),
            Text('• Batch number codes'),
            Text('• Processing stage identifiers'),
            SizedBox(height: 16),
            Text('Tips:'),
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
  void dispose() {
    super.dispose();
  }
}

class ProcessingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProcessingDetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String;
    final id = data['id'] as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('${type.toUpperCase()} Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh data
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getTypeIcon(type),
                          size: 32,
                          color: _getTypeColor(type),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getTypeTitle(type),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'ID: $id',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content based on type
            if (type == 'product') _buildProductDetails(data['data'] as Product),
            if (type == 'animal') _buildAnimalDetails(data['data'] as Animal),
            if (type == 'batch') _buildBatchDetails(data['data'] as List<Product>),

            const SizedBox(height: 24),

            // Processing actions
            _buildProcessingActions(type, id),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Name', product.name),
                _buildDetailRow('Type', product.productType),
                _buildDetailRow('Quantity', '${product.quantity} units'),
                _buildDetailRow('Weight', '${product.weight} ${product.weightUnit}'),
                _buildDetailRow('Batch', product.batchNumber),
                _buildDetailRow('Price', '\$${product.price.toStringAsFixed(2)}'),
                if (product.description.isNotEmpty)
                  _buildDetailRow('Description', product.description),
                _buildDetailRow('Created', product.createdAt.toLocal().toString().split('.')[0]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Processing stages
        const Text(
          'Processing Timeline',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildProcessingTimeline(product.timeline),
      ],
    );
  }

  Widget _buildAnimalDetails(Animal animal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Animal Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID', animal.animalId),
                if (animal.animalName != null)
                  _buildDetailRow('Name', animal.animalName!),
                _buildDetailRow('Species', animal.species),
                _buildDetailRow('Age', '${animal.age} months'),
                _buildDetailRow('Weight', '${animal.weight} kg'),
                if (animal.breed != null)
                  _buildDetailRow('Breed', animal.breed!),
                if (animal.farmName != null)
                  _buildDetailRow('Farm', animal.farmName!),
                if (animal.farmerUsername != null)
                  _buildDetailRow('Farmer', animal.farmerUsername!),
                _buildDetailRow('Status', animal.slaughtered ? 'Slaughtered' : 'Live'),
                if (animal.slaughtered && animal.slaughteredAt != null)
                  _buildDetailRow('Slaughtered', animal.slaughteredAt!.toLocal().toString().split('.')[0]),
                if (animal.receivedAt != null)
                  _buildDetailRow('Received', animal.receivedAt!.toLocal().toString().split('.')[0]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchDetails(List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Batch Information (${products.length} products)',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...products.map((product) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.inventory_2),
            title: Text(product.name),
            subtitle: Text('${product.quantity} units • ${product.productType}'),
            trailing: Text('\$${product.price.toStringAsFixed(2)}'),
          ),
        )),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingTimeline(List<dynamic> timeline) {
    if (timeline.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No processing timeline available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: timeline.map<Widget>((event) {
            return ListTile(
              leading: const Icon(Icons.timeline, color: Colors.blue),
              title: Text(event['action'] ?? 'Unknown action'),
              subtitle: Text(event['location'] ?? 'Unknown location'),
              trailing: Text(
                event['timestamp'] != null 
                  ? DateTime.parse(event['timestamp']).toLocal().toString().split('.')[0]
                  : 'Unknown time',
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProcessingActions(String type, String id) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Processing Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (type == 'animal') ...[
                  _buildActionButton(
                    'Create Product',
                    Icons.add_business,
                    Colors.green,
                    () {
                      // Navigate to create product screen with animal pre-selected
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    'Record Measurements',
                    Icons.straighten,
                    Colors.blue,
                    () {
                      // Navigate to carcass measurement screen
                    },
                  ),
                ],
                if (type == 'product') ...[
                  _buildActionButton(
                    'Update Stage',
                    Icons.update,
                    Colors.orange,
                    () {
                      // Show stage update dialog
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    'Transfer Product',
                    Icons.send,
                    Colors.purple,
                    () {
                      // Navigate to transfer screen
                    },
                  ),
                ],
                if (type == 'batch') ...[
                  _buildActionButton(
                    'Batch Operations',
                    Icons.batch_prediction,
                    Colors.teal,
                    () {
                      // Show batch operations dialog
                    },
                  ),
                ],
                const SizedBox(height: 8),
                _buildActionButton(
                  'Add Timeline Event',
                  Icons.add_circle,
                  Colors.indigo,
                  () {
                    // Show add timeline event dialog
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'product':
        return Icons.inventory_2;
      case 'animal':
        return Icons.pets;
      case 'batch':
        return Icons.batch_prediction;
      default:
        return Icons.qr_code;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'product':
        return Colors.green;
      case 'animal':
        return Colors.blue;
      case 'batch':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTypeTitle(String type) {
    switch (type) {
      case 'product':
        return 'Product Information';
      case 'animal':
        return 'Animal Information';
      case 'batch':
        return 'Batch Information';
      default:
        return 'QR Code Information';
    }
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