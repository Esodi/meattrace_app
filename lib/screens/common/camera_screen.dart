import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// Camera screen for product photo capture
/// Provides image capture, gallery import, and basic editing tools
class CameraScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final int maxImages;
  final bool showEditingTools;
  final Function(List<File>) onImagesSelected;

  const CameraScreen({
    super.key,
    this.title = 'Take Photo',
    this.subtitle,
    this.maxImages = 1,
    this.showEditingTools = true,
    required this.onImagesSelected,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _showGrid = false;
  CameraMode _cameraMode = CameraMode.photo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: AppTypography.headlineMedium().copyWith(
                color: Colors.white,
              ),
            ),
            if (widget.subtitle != null)
              Text(
                widget.subtitle!,
                style: AppTypography.bodyMedium().copyWith(
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          if (_selectedImages.isNotEmpty)
            TextButton(
              onPressed: _confirmSelection,
              child: Text(
                'Done (${_selectedImages.length})',
                style: AppTypography.button().copyWith(color: AppColors.info),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _selectedImages.isEmpty
          ? _buildCameraView()
          : _buildImagePreview(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Camera placeholder (in production, use camera plugin)
        Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: AppTheme.space24),
                Text(
                  'Camera Preview',
                  style: AppTypography.headlineMedium().copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'Use camera or gallery to add photos',
                  style: AppTypography.bodyMedium().copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Grid overlay
        if (_showGrid) CustomPaint(painter: GridPainter(), child: Container()),

        // Top controls
        Positioned(
          top: AppTheme.space16,
          left: AppTheme.space16,
          right: AppTheme.space16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flash control
              _buildControl(
                icon: Icons.flash_off,
                label: 'Flash',
                onTap: () {
                  // Toggle flash
                },
              ),

              // Grid toggle
              _buildControl(
                icon: _showGrid ? Icons.grid_on : Icons.grid_off,
                label: 'Grid',
                isActive: _showGrid,
                onTap: () {
                  setState(() {
                    _showGrid = !_showGrid;
                  });
                },
              ),

              // Camera mode
              _buildControl(
                icon: _cameraMode == CameraMode.photo
                    ? Icons.photo_camera
                    : Icons.camera_alt,
                label: _cameraMode == CameraMode.photo ? 'Photo' : 'Product',
                onTap: _toggleCameraMode,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        // Main image preview
        Expanded(
          child: PageView.builder(
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Center(
                    child: Image.file(
                      _selectedImages[index],
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Image counter
                  Positioned(
                    top: AppTheme.space16,
                    right: AppTheme.space16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space12,
                        vertical: AppTheme.space8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        '${index + 1} / ${_selectedImages.length}',
                        style: AppTypography.labelMedium().copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Editing tools
        if (widget.showEditingTools) _buildEditingTools(),

        // Thumbnail strip
        if (_selectedImages.length > 1) _buildThumbnailStrip(),
      ],
    );
  }

  Widget _buildEditingTools() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildEditTool(
            icon: Icons.crop,
            label: 'Crop',
            onTap: () {
              // Implement crop
              _showSnackBar('Crop tool - Coming soon');
            },
          ),
          _buildEditTool(
            icon: Icons.rotate_90_degrees_cw,
            label: 'Rotate',
            onTap: () {
              // Implement rotate
              _showSnackBar('Rotate tool - Coming soon');
            },
          ),
          _buildEditTool(
            icon: Icons.filter,
            label: 'Filter',
            onTap: () {
              // Implement filters
              _showSnackBar('Filter tool - Coming soon');
            },
          ),
          _buildEditTool(
            icon: Icons.brightness_6,
            label: 'Adjust',
            onTap: () {
              // Implement brightness/contrast
              _showSnackBar('Adjust tool - Coming soon');
            },
          ),
          _buildEditTool(
            icon: Icons.delete,
            label: 'Delete',
            isDestructive: true,
            onTap: () {
              _deleteCurrentImage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            width: 64,
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white70, width: 2),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall - 2),
              child: Image.file(_selectedImages[index], fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Gallery
            _buildBottomButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              onTap: _pickFromGallery,
            ),

            // Capture button
            GestureDetector(
              onTap: _capturePhoto,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            // Switch camera (placeholder)
            _buildBottomButton(
              icon: Icons.flip_camera_ios,
              label: 'Flip',
              onTap: () {
                _showSnackBar('Camera flip - Coming soon');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControl({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.info.withValues(alpha: 0.3)
              : Colors.black54,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: isActive ? Border.all(color: AppColors.info, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.info : Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppTheme.space4),
            Text(
              label,
              style: AppTypography.labelMedium().copyWith(
                color: isActive ? AppColors.info : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditTool({
    required IconData icon,
    required String label,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: isDestructive
                  ? AppColors.error.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDestructive ? AppColors.error : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            label,
            style: AppTypography.labelSmall().copyWith(
              color: isDestructive ? AppColors.error : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: AppTheme.space4),
          Text(
            label,
            style: AppTypography.labelSmall().copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    if (_selectedImages.length >= widget.maxImages) {
      _showSnackBar('Maximum ${widget.maxImages} images allowed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error capturing photo: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_selectedImages.length >= widget.maxImages) {
      _showSnackBar('Maximum ${widget.maxImages} images allowed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.maxImages == 1) {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _selectedImages.add(File(image.path));
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        final List<XFile> images = await _picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        final int remainingSlots = widget.maxImages - _selectedImages.length;
        final List<XFile> imagesToAdd = images.take(remainingSlots).toList();

        setState(() {
          _selectedImages.addAll(imagesToAdd.map((e) => File(e.path)));
          _isLoading = false;
        });

        if (images.length > remainingSlots) {
          _showSnackBar(
            'Only $remainingSlots more images allowed. Selected first $remainingSlots.',
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error selecting images: $e');
    }
  }

  void _deleteCurrentImage() {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _selectedImages.removeAt(0);
    });

    _showSnackBar('Image deleted');
  }

  void _confirmSelection() {
    widget.onImagesSelected(_selectedImages);
    Navigator.of(context).pop();
  }

  void _toggleCameraMode() {
    setState(() {
      _cameraMode = _cameraMode == CameraMode.photo
          ? CameraMode.product
          : CameraMode.photo;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
      ),
    );
  }
}

/// Grid overlay painter for composition guide
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Vertical lines (rule of thirds)
    final double verticalSpacing = size.width / 3;
    canvas.drawLine(
      Offset(verticalSpacing, 0),
      Offset(verticalSpacing, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(verticalSpacing * 2, 0),
      Offset(verticalSpacing * 2, size.height),
      paint,
    );

    // Horizontal lines (rule of thirds)
    final double horizontalSpacing = size.height / 3;
    canvas.drawLine(
      Offset(0, horizontalSpacing),
      Offset(size.width, horizontalSpacing),
      paint,
    );
    canvas.drawLine(
      Offset(0, horizontalSpacing * 2),
      Offset(size.width, horizontalSpacing * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Camera mode enum
enum CameraMode { photo, product }
