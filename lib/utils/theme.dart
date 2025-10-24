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

  // Nature-inspired Colors for Processor Dashboard
  static const Color forestGreen = Color(0xFF2D5A3D); // Deep forest green for primary elements
  static const Color oceanBlue = Color(0xFF1E3A5F); // Ocean blue for secondary elements
  static const Color earthBrown = Color(0xFF8B4513); // Earth brown for tertiary elements
  static const Color skyBlue = Color(0xFF87CEEB); // Sky blue for accents
  static const Color leafGreen = Color(0xFF32CD32); // Leaf green for success states

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
      shadowColor: Colors.black.withValues(alpha: 0.1),
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
      shadowColor: Colors.black.withValues(alpha: 0.1),
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
        color: textSecondary.withValues(alpha: 0.7),
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
  static ThemeData getThemeForRole(String? role, {Brightness brightness = Brightness.light}) {
    final isDark = brightness == Brightness.dark;
    switch (role?.toLowerCase()) {
      case 'farmer':
        return isDark ? _farmerDarkTheme : _farmerTheme;
      case 'processing_unit':
      case 'processor':
        return isDark ? _processorDarkTheme : _processorTheme;
      case 'shop':
      case 'retail':
        return isDark ? _shopDarkTheme : _shopTheme;
      default:
        return isDark ? darkTheme : lightTheme;
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

  // Farmer Dark Theme - Primary Red focus with dark adaptations
  static ThemeData _farmerDarkTheme = darkTheme.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: primaryRed,
      secondary: secondaryBlue,
      tertiary: accentOrange,
      surface: Color(0xFF2D2D2D),
      background: Color(0xFF1A1A1A),
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
      surfaceTint: Color(0xFF3D3D3D),
    ),
    appBarTheme: darkTheme.appBarTheme.copyWith(
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
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: primaryRed,
      unselectedItemColor: Color(0xFFB0B0B0),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
  );

  // Processor Dark Theme - Primary Green focus with dark adaptations
  static ThemeData _processorDarkTheme = darkTheme;

  // Shop Dark Theme - Secondary Burgundy focus with dark adaptations
  static ThemeData _shopDarkTheme = darkTheme.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: secondaryBurgundy,
      secondary: secondaryBlue,
      tertiary: accentMaroon,
      surface: Color(0xFF2D2D2D),
      background: Color(0xFF1A1A1A),
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
      surfaceTint: Color(0xFF3D3D3D),
    ),
    appBarTheme: darkTheme.appBarTheme.copyWith(
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
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: secondaryBurgundy,
      unselectedItemColor: Color(0xFFB0B0B0),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryGreen,
      secondary: secondaryBlue,
      tertiary: accentOrange,
      surface: Color(0xFF2D2D2D), // Slightly lighter dark surface for better contrast
      background: Color(0xFF1A1A1A), // Adjusted dark background
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white, // Better contrast for text on dark surface
      onBackground: Colors.white, // Better contrast for text on dark background
      onError: Colors.white,
      surfaceTint: Color(0xFF3D3D3D), // Added for card hover effects
    ),

    // Typography - Roboto as primary font per design system
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).copyWith(
      // Headline Large: 32px / 2.0 line-height / Bold (500)
      displayLarge: GoogleFonts.roboto(
        fontSize: 32,
        height: 2.0,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFE0E0E0),
      ),
      // Headline Medium: 28px / 1.8 line-height / Bold (500)
      displayMedium: GoogleFonts.roboto(
        fontSize: 28,
        height: 1.8,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFE0E0E0),
      ),
      // Headline Small: 24px / 1.6 line-height / Bold (500)
      displaySmall: GoogleFonts.roboto(
        fontSize: 24,
        height: 1.6,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFE0E0E0),
      ),
      // Title Large: 22px / 1.5 line-height / Medium (500)
      headlineLarge: GoogleFonts.roboto(
        fontSize: 22,
        height: 1.5,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFE0E0E0),
      ),
      // Title Medium: 18px / 1.4 line-height / Medium (500)
      headlineMedium: GoogleFonts.roboto(
        fontSize: 18,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFE0E0E0),
      ),
      // Title Small: 16px / 1.4 line-height / Medium (500) - adjusted for consistency
      headlineSmall: GoogleFonts.roboto(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFE0E0E0),
      ),
      // Body Large: 16px / 1.5 line-height / Regular (400)
      titleLarge: GoogleFonts.roboto(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFE0E0E0),
      ),
      // Body Medium: 14px / 1.4 line-height / Regular (400)
      titleMedium: GoogleFonts.roboto(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFE0E0E0),
      ),
      // Body Small: 12px / 1.3 line-height / Regular (400)
      titleSmall: GoogleFonts.roboto(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFB0B0B0),
      ),
      // Label Large: 14px / 1.4 line-height / Medium (500)
      bodyLarge: GoogleFonts.roboto(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFE0E0E0),
      ),
      // Label Medium: 12px / 1.3 line-height / Medium (500)
      bodyMedium: GoogleFonts.roboto(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFB0B0B0),
      ),
      // Label Small: 12px / 1.3 line-height / Medium (500) - adjusted
      bodySmall: GoogleFonts.roboto(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFB0B0B0),
      ),
      // Additional labels for buttons and inputs
      labelLarge: GoogleFonts.roboto(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFE0E0E0),
      ),
      labelMedium: GoogleFonts.roboto(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFB0B0B0),
      ),
      labelSmall: GoogleFonts.roboto(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFB0B0B0),
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      toolbarHeight: 56,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: const Color(0xFF2D2D2D), // Lighter surface for better visibility
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF3D3D3D), width: 1), // Subtle border for definition
      ),
      margin: const EdgeInsets.all(8),
    ),

    // Button Themes
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
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        minimumSize: const Size(double.infinity, 48),
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
        minimumSize: const Size(44, 44),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF5F5F5F), width: 1),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF5F5F5F), width: 1),
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
        color: const Color(0xFFB0B0B0),
      ),
      floatingLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        color: primaryGreen,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.roboto(
        fontSize: 16,
        color: const Color(0xFF7F7F7F),
      ),
      errorStyle: GoogleFonts.roboto(
        fontSize: 12,
        color: errorRed,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: forestGreen,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: CircleBorder(),
      sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: primaryGreen,
      unselectedItemColor: Color(0xFFB0B0B0),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // SnackBar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF333333),
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
}







