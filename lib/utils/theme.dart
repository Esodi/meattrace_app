import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // MeatTrace Design System Color Palette
  // Primary Colors
  static const Color primaryGreen = Color(0xFF2E7D32); // Trust, nature, freshness, processing unit branding
  static const Color primaryRed = Color(0xFFD32F2F); // Meat, vitality, alerts, farmer branding

  // Secondary Colors
  static const Color secondaryBurgundy = Color(0xFF5D4037); // Sophistication, quality meat, shop branding
  static const Color secondaryBlue = Color(0xFF1976D2); // Technology, trust, reliability

  // Accent Colors
  static const Color accentOrange = Color(0xFFFF9800); // Energy, processing, warmth
  static const Color accentMaroon = Color(0xFF8D4A4A); // Premium quality, depth

  // Neutral Colors
  static const Color backgroundGray = Color(0xFFF5F5F5); // Clean, modern background
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Card backgrounds, content areas
  static const Color textPrimary = Color(0xFF212121); // High contrast text
  static const Color textSecondary = Color(0xFF757575); // Secondary information
  static const Color dividerGray = Color(0xFFE0E0E0); // Subtle separations

  // Semantic Colors
  static const Color successGreen = Color(0xFF4CAF50); // Confirmations, completed actions
  static const Color warningOrange = Color(0xFFFF9800); // Cautions, pending states
  static const Color warningAmber = Color(0xFFFF9800); // Alias for backward compatibility
  static const Color errorRed = Color(0xFFF44336); // Errors, critical issues
  static const Color infoBlue = Color(0xFF2196F3); // Information, help text

  // Legacy colors for backward compatibility
  static const Color backgroundCream = Color(0xFFFFFBF7);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primaryGreen, // Changed to primary green as main brand color
      secondary: secondaryBlue,
      tertiary: accentOrange,
      surface: surfaceWhite,
      background: backgroundGray,
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onBackground: textPrimary,
      onError: Colors.white,
    ),

    // Typography - Roboto as primary font per design system
    textTheme: GoogleFonts.robotoTextTheme().copyWith(
      // Headline Large: 32px / 2.0 line-height / Bold (500)
      displayLarge: GoogleFonts.roboto(
        fontSize: 32,
        height: 2.0,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      // Headline Medium: 28px / 1.8 line-height / Bold (500)
      displayMedium: GoogleFonts.roboto(
        fontSize: 28,
        height: 1.8,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      // Headline Small: 24px / 1.6 line-height / Bold (500)
      displaySmall: GoogleFonts.roboto(
        fontSize: 24,
        height: 1.6,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      // Title Large: 22px / 1.5 line-height / Medium (500)
      headlineLarge: GoogleFonts.roboto(
        fontSize: 22,
        height: 1.5,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      // Title Medium: 18px / 1.4 line-height / Medium (500)
      headlineMedium: GoogleFonts.roboto(
        fontSize: 18,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      // Title Small: 16px / 1.4 line-height / Medium (500) - adjusted for consistency
      headlineSmall: GoogleFonts.roboto(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      // Body Large: 16px / 1.5 line-height / Regular (400)
      titleLarge: GoogleFonts.roboto(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      // Body Medium: 14px / 1.4 line-height / Regular (400)
      titleMedium: GoogleFonts.roboto(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      // Body Small: 12px / 1.3 line-height / Regular (400)
      titleSmall: GoogleFonts.roboto(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      // Label Large: 14px / 1.4 line-height / Medium (500)
      bodyLarge: GoogleFonts.roboto(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      // Label Medium: 12px / 1.3 line-height / Medium (500)
      bodyMedium: GoogleFonts.roboto(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      // Label Small: 12px / 1.3 line-height / Medium (500) - adjusted
      bodySmall: GoogleFonts.roboto(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      // Additional labels for buttons and inputs
      labelLarge: GoogleFonts.roboto(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.roboto(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.roboto(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 2, // Level 2 elevation
      shadowColor: Colors.black.withOpacity(0.1),
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      toolbarHeight: 56, // Standard toolbar height
    ),

    // Card Theme - Elevation 2-4dp, 12px border radius, 16-20px padding
    cardTheme: CardThemeData(
      color: surfaceWhite,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(8), // 1 unit spacing
    ),

    // Button Themes - Rounded corners (12px), full-width on mobile
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 14, // Label Large
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        minimumSize: const Size(double.infinity, 48), // Full width, 44px minimum touch target
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryGreen,
        side: const BorderSide(color: primaryGreen, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        minimumSize: const Size(double.infinity, 48),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        minimumSize: const Size(44, 44), // Minimum touch target
      ),
    ),

    // Input Decoration Theme - Underline style, floating labels
    inputDecorationTheme: InputDecorationTheme(
      filled: false, // Underline style, not filled
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: dividerGray, width: 1),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: dividerGray, width: 1),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: errorRed, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      labelStyle: GoogleFonts.roboto(
        fontSize: 16,
        color: textSecondary,
      ),
      floatingLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        color: primaryGreen,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.roboto(
        fontSize: 16,
        color: textSecondary.withOpacity(0.7),
      ),
      errorStyle: GoogleFonts.roboto(
        fontSize: 12,
        color: errorRed,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Floating Action Button Theme - Circular, 56px diameter
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 6, // Level 3 elevation
      shape: CircleBorder(),
      sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceWhite,
      selectedItemColor: primaryGreen,
      unselectedItemColor: textSecondary,
      elevation: 8, // Level 4 elevation
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceWhite,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // SnackBar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimary,
      contentTextStyle: GoogleFonts.roboto(
        color: Colors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // Role-based themes
  static ThemeData getThemeForRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'farmer':
        return _farmerTheme;
      case 'processing_unit':
      case 'processor':
        return _processorTheme;
      case 'shop':
      case 'retail':
        return _shopTheme;
      default:
        return lightTheme; // Default to processor theme
    }
  }

  // Farmer Theme - Primary Red focus
  static ThemeData _farmerTheme = lightTheme.copyWith(
    colorScheme: const ColorScheme.light(
      primary: primaryRed,
      secondary: secondaryBlue,
      tertiary: accentOrange,
      surface: surfaceWhite,
      background: backgroundGray,
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onBackground: textPrimary,
      onError: Colors.white,
    ),
    appBarTheme: lightTheme.appBarTheme.copyWith(
      backgroundColor: primaryRed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        minimumSize: const Size(double.infinity, 48),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryRed,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: CircleBorder(),
      sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceWhite,
      selectedItemColor: primaryRed,
      unselectedItemColor: textSecondary,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
  );

  // Processor Theme - Primary Green focus
  static ThemeData _processorTheme = lightTheme;

  // Shop Theme - Secondary Burgundy focus
  static ThemeData _shopTheme = lightTheme.copyWith(
    colorScheme: const ColorScheme.light(
      primary: secondaryBurgundy,
      secondary: secondaryBlue,
      tertiary: accentMaroon,
      surface: surfaceWhite,
      background: backgroundGray,
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onBackground: textPrimary,
      onError: Colors.white,
    ),
    appBarTheme: lightTheme.appBarTheme.copyWith(
      backgroundColor: secondaryBurgundy,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryBurgundy,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        minimumSize: const Size(double.infinity, 48),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondaryBurgundy,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: CircleBorder(),
      sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceWhite,
      selectedItemColor: secondaryBurgundy,
      unselectedItemColor: textSecondary,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
  );

  // Dark Theme (Optional - can be implemented later)
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: primaryGreen,
      secondary: secondaryBlue,
      tertiary: accentOrange,
    ),
  );
}