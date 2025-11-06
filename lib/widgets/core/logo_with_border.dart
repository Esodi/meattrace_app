import 'package:flutter/material.dart';

/// Reusable circular logo widget with a visible border.
///
/// Usage:
/// LogoWithBorder(size: 80, borderWidth: 3, borderColor: Colors.white)
class LogoWithBorder extends StatelessWidget {
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final String assetPath;

  const LogoWithBorder({
    Key? key,
    this.size = 80,
    this.borderWidth = 3,
    this.borderColor,
    this.assetPath = 'assets/icons/MEATTRACE_ICON.png',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
      ),
      // Padding used so the image sits inside the border area
      child: Container(
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: effectiveBorderColor, width: borderWidth),
        ),
        child: ClipOval(
          child: Image.asset(
            assetPath,
            width: size - (borderWidth * 2),
            height: size - (borderWidth * 2),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
