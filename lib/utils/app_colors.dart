import 'package:flutter/material.dart';

/// MeatTrace Pro Design System - Color Palette
/// Version 2.0 - Enhanced color system with gradients and semantic colors
class AppColors {
  // ========== ROLE-BASED PRIMARY COLORS ==========
  
  /// Farmer/Abattoir Primary - Energetic Red
  static const Color farmerPrimary = Color(0xFFD32F2F); // Red 700
  static const Color farmerLight = Color(0xFFE57373); // Red 300
  static const Color farmerDark = Color(0xFFB71C1C); // Red 900
  
  /// Processing Unit Primary - Natural Green
  static const Color processorPrimary = Color(0xFF2E7D32); // Green 800
  static const Color processorLight = Color(0xFF66BB6A); // Green 400
  static const Color processorDark = Color(0xFF1B5E20); // Green 900
  
  /// Shop/Retail Primary - Sophisticated Burgundy
  static const Color shopPrimary = Color(0xFF5D4037); // Brown 700
  static const Color shopLight = Color(0xFF8D6E63); // Brown 300
  static const Color shopDark = Color(0xFF3E2723); // Brown 900
  
  // ========== SECONDARY COLORS ==========
  
  static const Color secondaryBlue = Color(0xFF1976D2); // Blue 700
  static const Color secondaryBlueLight = Color(0xFF64B5F6); // Blue 300
  static const Color secondaryBlueDark = Color(0xFF0D47A1); // Blue 900
  
  static const Color accentOrange = Color(0xFFFF9800); // Orange 500
  static const Color accentOrangeLight = Color(0xFFFFB74D); // Orange 300
  static const Color accentOrangeDark = Color(0xFFE65100); // Orange 900
  
  static const Color accentMaroon = Color(0xFF8D4A4A); // Custom Maroon
  
  // ========== SEMANTIC COLORS ==========
  
  static const Color success = Color(0xFF4CAF50); // Green 500
  static const Color successLight = Color(0xFF81C784); // Green 300
  static const Color successDark = Color(0xFF2E7D32); // Green 800
  
  static const Color warning = Color(0xFFFF9800); // Orange 500
  static const Color warningLight = Color(0xFFFFB74D); // Orange 300
  static const Color warningDark = Color(0xFFF57C00); // Orange 700
  
  static const Color error = Color(0xFFF44336); // Red 500
  static const Color errorLight = Color(0xFFE57373); // Red 300
  static const Color errorDark = Color(0xFFD32F2F); // Red 700
  
  static const Color info = Color(0xFF2196F3); // Blue 500
  static const Color infoLight = Color(0xFF64B5F6); // Blue 300
  static const Color infoDark = Color(0xFF1976D2); // Blue 700
  
  // ========== NEUTRAL COLORS ==========
  
  static const Color textPrimary = Color(0xFF212121); // Grey 900
  static const Color textSecondary = Color(0xFF757575); // Grey 600
  static const Color textTertiary = Color(0xFF9E9E9E); // Grey 500
  static const Color textDisabled = Color(0xFFBDBDBD); // Grey 400
  
  static const Color backgroundLight = Color(0xFFFAFAFA); // Grey 50
  static const Color backgroundGray = Color(0xFFF5F5F5); // Grey 100
  static const Color surfaceWhite = Color(0xFFFFFFFF); // White
  
  static const Color dividerLight = Color(0xFFEEEEEE); // Grey 200
  static const Color divider = Color(0xFFE0E0E0); // Grey 300
  static const Color dividerDark = Color(0xFFBDBDBD); // Grey 400
  
  /// Border color for cards and containers
  static const Color borderLight = Color(0xFFE0E0E0); // Grey 300 - same as divider
  
  // ========== DARK MODE COLORS ==========
  
  static const Color darkBackground = Color(0xFF121212); // Material Dark Background
  static const Color darkSurface = Color(0xFF1E1E1E); // Material Dark Surface
  static const Color darkSurfaceVariant = Color(0xFF2D2D2D); // Elevated Surface
  
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // White
  static const Color darkTextSecondary = Color(0xFFB0B0B0); // Grey
  static const Color darkTextTertiary = Color(0xFF808080); // Dark Grey
  
  static const Color darkDivider = Color(0xFF3D3D3D); // Dark Grey
  
  // ========== GRADIENT DEFINITIONS ==========
  
  /// Farmer Gradient - Warm Red
  static const LinearGradient farmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [farmerLight, farmerPrimary, farmerDark],
    stops: [0.0, 0.5, 1.0],
  );
  
  /// Processor Gradient - Fresh Green
  static const LinearGradient processorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [processorLight, processorPrimary, processorDark],
    stops: [0.0, 0.5, 1.0],
  );
  
  /// Shop Gradient - Rich Burgundy
  static const LinearGradient shopGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [shopLight, shopPrimary, shopDark],
    stops: [0.0, 0.5, 1.0],
  );
  
  /// Success Gradient
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successLight, success, successDark],
  );
  
  /// Warning Gradient
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningLight, warning, warningDark],
  );
  
  /// Error Gradient
  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [errorLight, error, errorDark],
  );
  
  /// Info Gradient
  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [infoLight, info, infoDark],
  );
  
  // ========== QUALITY TIER COLORS ==========
  
  static const Color qualityPremium = Color(0xFFFFD700); // Gold
  static const Color qualityGradeA = Color(0xFF4CAF50); // Green
  static const Color qualityGradeB = Color(0xFF2196F3); // Blue
  static const Color qualityStandard = Color(0xFF9E9E9E); // Grey
  
  // ========== HEALTH STATUS COLORS ==========
  
  static const Color healthHealthy = Color(0xFF4CAF50); // Green
  static const Color healthQuarantine = Color(0xFFFF9800); // Orange
  static const Color healthSick = Color(0xFFF44336); // Red
  static const Color healthTreatment = Color(0xFF2196F3); // Blue
  
  // ========== LIVESTOCK SPECIES COLORS ==========
  
  static const Color speciesCattle = Color(0xFF8D6E63); // Brown
  static const Color speciesPig = Color(0xFFE91E63); // Pink
  static const Color speciesChicken = Color(0xFFFFEB3B); // Yellow
  static const Color speciesSheep = Color(0xFFEEEEEE); // Light Grey
  static const Color speciesGoat = Color(0xFF795548); // Deep Brown
  
  // ========== OVERLAY COLORS ==========
  
  static Color overlayLight = Colors.white.withValues(alpha: 0.1);
  static Color overlayMedium = Colors.white.withValues(alpha: 0.2);
  static Color overlayHeavy = Colors.white.withValues(alpha: 0.3);
  
  static Color overlayDark = Colors.black.withValues(alpha: 0.1);
  static Color overlayDarkMedium = Colors.black.withValues(alpha: 0.2);
  static Color overlayDarkHeavy = Colors.black.withValues(alpha: 0.5);
  
  // ========== SHADOW COLORS ==========
  
  static Color shadow = Colors.black.withValues(alpha: 0.1);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.15);
  static Color shadowHeavy = Colors.black.withValues(alpha: 0.25);
  
  // ========== HELPER METHODS ==========
  
  /// Get primary color based on user role
  static Color getPrimaryColorForRole(String? role) {
    if (role == null) return processorPrimary;
    
    switch (role.toLowerCase()) {
      case 'farmer':
      case 'abattoir':
        return farmerPrimary;
      case 'processing_unit':
      case 'processor':
        return processorPrimary;
      case 'shop':
      case 'retail':
        return shopPrimary;
      default:
        return processorPrimary;
    }
  }
  
  /// Get light variant of primary color based on user role
  static Color getLightColorForRole(String? role) {
    if (role == null) return processorLight;
    
    switch (role.toLowerCase()) {
      case 'farmer':
      case 'abattoir':
        return farmerLight;
      case 'processing_unit':
      case 'processor':
        return processorLight;
      case 'shop':
      case 'retail':
        return shopLight;
      default:
        return processorLight;
    }
  }
  
  /// Get dark variant of primary color based on user role
  static Color getDarkColorForRole(String? role) {
    if (role == null) return processorDark;
    
    switch (role.toLowerCase()) {
      case 'farmer':
      case 'abattoir':
        return farmerDark;
      case 'processing_unit':
      case 'processor':
        return processorDark;
      case 'shop':
      case 'retail':
        return shopDark;
      default:
        return processorDark;
    }
  }
  
  /// Get gradient based on user role
  static LinearGradient getGradientForRole(String? role) {
    if (role == null) return processorGradient;
    
    switch (role.toLowerCase()) {
      case 'farmer':
      case 'abattoir':
        return farmerGradient;
      case 'processing_unit':
      case 'processor':
        return processorGradient;
      case 'shop':
      case 'retail':
        return shopGradient;
      default:
        return processorGradient;
    }
  }
  
  /// Get color based on health status
  static Color getHealthStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return healthHealthy;
      case 'quarantine':
        return healthQuarantine;
      case 'sick':
        return healthSick;
      case 'treatment':
      case 'under_treatment':
        return healthTreatment;
      default:
        return healthHealthy;
    }
  }
  
  /// Get color based on quality tier
  static Color getQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'premium':
      case 'grade_a+':
        return qualityPremium;
      case 'grade_a':
      case 'a':
        return qualityGradeA;
      case 'grade_b':
      case 'b':
        return qualityGradeB;
      case 'standard':
      default:
        return qualityStandard;
    }
  }
  
  /// Get color based on livestock species
  static Color getSpeciesColor(String species) {
    switch (species.toLowerCase()) {
      case 'cattle':
      case 'cow':
      case 'bull':
        return speciesCattle;
      case 'pig':
      case 'swine':
        return speciesPig;
      case 'chicken':
      case 'poultry':
        return speciesChicken;
      case 'sheep':
        return speciesSheep;
      case 'goat':
        return speciesGoat;
      default:
        return textSecondary;
    }
  }
}
