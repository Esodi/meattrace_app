import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Premium circular logo widget with layered shadows and a glass finish.
/// Features internal padding to ensure logo edges are fully visible.
class LogoWithBorder extends StatelessWidget {
  final double size;
  final String assetPath;
  final List<Color>? glowColors;
  final double padding;

  const LogoWithBorder({
    super.key,
    this.size = 100, // Increased default diameter
    this.assetPath = 'assets/icons/MEATTRACE_ICON.png',
    this.glowColors,
    this.padding = 12.0, // Default padding to show logo edges
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlow =
        glowColors ?? [AppColors.abbatoirPrimary, AppColors.processorPrimary];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          // Layer 1: Soft ambient glow using brand colors
          BoxShadow(
            color: effectiveGlow.first.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 12),
            spreadRadius: -5,
          ),
          // Layer 2: Sharp contact shadow for definition
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: ClipOval(
          child: Stack(
            children: [
              // Main Logo Image (contained within padding to show edges)
              Center(
                child: Image.asset(
                  assetPath,
                  width: size - (padding * 2),
                  height: size - (padding * 2),
                  fit: BoxFit.contain, // Changed to contain to prevent cropping
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.backgroundGray,
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.textSecondary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),

              // Glassy Reflective Overlay (Glare) for premium feel
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.35),
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                        Colors.black.withOpacity(0.04),
                      ],
                      stops: const [0.0, 0.4, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
