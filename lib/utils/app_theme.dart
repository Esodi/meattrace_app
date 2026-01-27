import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// MeatTrace Pro Design System - Theme Configuration
/// Version 2.0 - Material Design 3 with role-based theming
class AppTheme {
  // ========== SPACING SYSTEM (8pt grid) ==========

  static const double space4 = 4.0; // 0.5 units
  static const double space6 = 6.0; // 0.75 units
  static const double space8 = 8.0; // 1 unit
  static const double space12 = 12.0; // 1.5 units
  static const double space16 = 16.0; // 2 units
  static const double space20 = 20.0; // 2.5 units
  static const double space24 = 24.0; // 3 units
  static const double space32 = 32.0; // 4 units
  static const double space40 = 40.0; // 5 units
  static const double space48 = 48.0; // 6 units
  static const double space56 = 56.0; // 7 units
  static const double space64 = 64.0; // 8 units

  // ========== BORDER RADIUS ==========

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusFull = 9999.0;

  // ========== ELEVATION (Material 3) ==========

  static const double elevationLevel0 = 0.0;
  static const double elevationLevel1 = 1.0;
  static const double elevationLevel2 = 3.0;
  static const double elevationLevel3 = 6.0;
  static const double elevationLevel4 = 8.0;
  static const double elevationLevel5 = 12.0;

  // ========== ICON SIZES ==========

  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // ========== BASE LIGHT THEME ==========

  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    primaryColor: AppColors.processorPrimary,
    primaryLight: AppColors.processorLight,
    primaryDark: AppColors.processorDark,
  );

  // ========== ROLE-BASED THEMES ==========

  static ThemeData abbatoirTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: AppColors.abbatoirPrimary,
    primaryLight: AppColors.abbatoirLight,
    primaryDark: AppColors.abbatoirDark,
  );

  static ThemeData processorTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: AppColors.processorPrimary,
    primaryLight: AppColors.processorLight,
    primaryDark: AppColors.processorDark,
  );

  static ThemeData shopTheme = _buildTheme(
    brightness: Brightness.light,
    primaryColor: AppColors.shopPrimary,
    primaryLight: AppColors.shopLight,
    primaryDark: AppColors.shopDark,
  );

  // ========== DARK THEME ==========

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    primaryColor: AppColors.processorPrimary,
    primaryLight: AppColors.processorLight,
    primaryDark: AppColors.processorDark,
  );

  // ========== THEME BUILDER ==========

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color primaryLight,
    required Color primaryDark,
  }) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: isDark ? primaryDark : primaryLight,
      onPrimaryContainer: isDark ? Colors.white : primaryDark,
      secondary: AppColors.secondaryBlue,
      onSecondary: Colors.white,
      secondaryContainer: isDark
          ? AppColors.secondaryBlueDark
          : AppColors.secondaryBlueLight,
      onSecondaryContainer: isDark ? Colors.white : AppColors.secondaryBlueDark,
      tertiary: AppColors.accentOrange,
      onTertiary: Colors.white,
      tertiaryContainer: isDark
          ? AppColors.accentOrangeDark
          : AppColors.accentOrangeLight,
      onTertiaryContainer: isDark ? Colors.white : AppColors.accentOrangeDark,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: isDark ? AppColors.errorDark : AppColors.errorLight,
      onErrorContainer: isDark ? Colors.white : AppColors.errorDark,
      surface: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      onSurface: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      surfaceContainerHighest: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.backgroundGray,
      onSurfaceVariant: isDark
          ? AppColors.darkTextSecondary
          : AppColors.textSecondary,
      outline: isDark ? AppColors.darkDivider : AppColors.divider,
      outlineVariant: isDark ? AppColors.darkDivider : AppColors.dividerLight,
      shadow: AppColors.shadow,
      scrim: isDark
          ? Colors.black.withValues(alpha: 0.5)
          : Colors.black.withValues(alpha: 0.3),
      inverseSurface: isDark ? AppColors.surfaceWhite : AppColors.darkSurface,
      onInverseSurface: isDark
          ? AppColors.textPrimary
          : AppColors.darkTextPrimary,
      inversePrimary: isDark ? primaryLight : primaryDark,
      surfaceTint: primaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,

      // ===== TYPOGRAPHY =====
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        displayMedium: AppTypography.displayMedium(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        displaySmall: AppTypography.displaySmall(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        headlineLarge: AppTypography.headlineLarge(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        headlineMedium: AppTypography.headlineMedium(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        headlineSmall: AppTypography.headlineSmall(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        titleLarge: AppTypography.titleLarge(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        titleMedium: AppTypography.titleMedium(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        titleSmall: AppTypography.titleSmall(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        bodyLarge: AppTypography.bodyLarge(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        bodyMedium: AppTypography.bodyMedium(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        bodySmall: AppTypography.bodySmall(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        labelLarge: AppTypography.labelLarge(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        labelMedium: AppTypography.labelMedium(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        labelSmall: AppTypography.labelSmall(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),

      // ===== APP BAR =====
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: elevationLevel1,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadow,
        titleTextStyle: AppTypography.appBarTitle(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white, size: iconMedium),
        actionsIconTheme: const IconThemeData(
          color: Colors.white,
          size: iconMedium,
        ),
        toolbarHeight: space56,
      ),

      // ===== CARDS =====
      cardTheme: CardThemeData(
        elevation: elevationLevel2,
        shadowColor: AppColors.shadow,
        surfaceTintColor: Colors.transparent,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(
            color: isDark ? AppColors.darkDivider : Colors.transparent,
            width: isDark ? 1 : 0,
          ),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space8,
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ===== BUTTONS =====
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark
              ? AppColors.darkTextTertiary
              : AppColors.textDisabled,
          disabledForegroundColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.textSecondary,
          elevation: elevationLevel2,
          shadowColor: AppColors.shadow,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: AppTypography.button(),
          minimumSize: const Size(double.infinity, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          disabledForegroundColor: isDark
              ? AppColors.darkTextTertiary
              : AppColors.textDisabled,
          side: BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: AppTypography.button(),
          minimumSize: const Size(double.infinity, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          disabledForegroundColor: isDark
              ? AppColors.darkTextTertiary
              : AppColors.textDisabled,
          padding: const EdgeInsets.symmetric(
            horizontal: space16,
            vertical: space8,
          ),
          textStyle: AppTypography.button(),
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark
              ? AppColors.darkTextTertiary
              : AppColors.textDisabled,
          disabledForegroundColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: AppTypography.button(),
          minimumSize: const Size(double.infinity, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),

      // ===== FLOATING ACTION BUTTON =====
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: elevationLevel3,
        highlightElevation: elevationLevel4,
        shape: const CircleBorder(),
        sizeConstraints: const BoxConstraints.tightFor(
          width: space56,
          height: space56,
        ),
      ),

      // ===== INPUT FIELDS =====
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.backgroundGray,
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(0),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
          borderRadius: BorderRadius.circular(0),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: const BorderSide(color: AppColors.error, width: 1),
          borderRadius: BorderRadius.circular(0),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: const BorderSide(color: AppColors.error, width: 2),
          borderRadius: BorderRadius.circular(0),
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? AppColors.darkTextTertiary : AppColors.textDisabled,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: space8,
        ),
        labelStyle: AppTypography.bodyLarge(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        floatingLabelStyle: AppTypography.labelMedium(color: primaryColor),
        hintStyle: AppTypography.bodyLarge(
          color: isDark
              ? AppColors.darkTextTertiary.withValues(alpha: 0.7)
              : AppColors.textTertiary.withValues(alpha: 0.7),
        ),
        errorStyle: AppTypography.error(color: AppColors.error),
        helperStyle: AppTypography.helper(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        prefixIconColor: isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary,
        suffixIconColor: isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary,
      ),

      // ===== BOTTOM NAVIGATION =====
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary,
        selectedLabelStyle: AppTypography.bottomNavLabel(),
        unselectedLabelStyle: AppTypography.bottomNavLabel(),
        elevation: elevationLevel4,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // ===== NAVIGATION BAR (Material 3) =====
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.bottomNavLabel(color: primaryColor);
          }
          return AppTypography.bottomNavLabel(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: iconMedium);
          }
          return IconThemeData(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            size: iconMedium,
          );
        }),
        elevation: elevationLevel3,
        height: space56 + space8,
      ),

      // ===== DIALOGS =====
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: elevationLevel5,
        shadowColor: AppColors.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: AppTypography.headlineSmall(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        contentTextStyle: AppTypography.bodyMedium(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),

      // ===== SNACKBAR =====
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.textPrimary,
        contentTextStyle: AppTypography.bodyMedium(color: Colors.white),
        actionTextColor: primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: elevationLevel3,
      ),

      // ===== CHIPS =====
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.backgroundGray,
        deleteIconColor: isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary,
        disabledColor: isDark
            ? AppColors.darkTextTertiary
            : AppColors.textDisabled,
        selectedColor: primaryColor.withValues(alpha: 0.12),
        secondarySelectedColor: AppColors.secondaryBlue.withValues(alpha: 0.12),
        shadowColor: AppColors.shadow,
        labelStyle: AppTypography.chipLabel(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        secondaryLabelStyle: AppTypography.chipLabel(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: space12,
          vertical: space8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),

      // ===== DIVIDER =====
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkDivider : AppColors.divider,
        thickness: 1,
        space: space16,
      ),

      // ===== LIST TILES =====
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space8,
        ),
        iconColor: isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary,
        textColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        tileColor: Colors.transparent,
        selectedTileColor: primaryColor.withValues(alpha: 0.08),
        selectedColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        titleTextStyle: AppTypography.bodyLarge(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        subtitleTextStyle: AppTypography.bodyMedium(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        leadingAndTrailingTextStyle: AppTypography.bodyMedium(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),

      // ===== TOOLTIPS =====
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.textPrimary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: AppTypography.tooltip(color: Colors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: space8,
          vertical: space4,
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),

      // ===== PROGRESS INDICATORS =====
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: isDark ? AppColors.darkDivider : AppColors.divider,
        circularTrackColor: isDark ? AppColors.darkDivider : AppColors.divider,
      ),

      // ===== SWITCHES & CHECKBOXES =====
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.5);
          }
          return isDark ? AppColors.darkDivider : AppColors.divider;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
          width: 2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
        }),
      ),

      // ===== TABS =====
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary,
        labelStyle: AppTypography.tabLabel(),
        unselectedLabelStyle: AppTypography.tabLabel(),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),

      // ===== ICON THEME =====
      iconTheme: IconThemeData(
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        size: iconMedium,
      ),

      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: iconMedium,
      ),
    );
  }

  // ========== THEME GETTER BY ROLE ==========

  static ThemeData getThemeForRole(String? role) {
    if (role == null) return processorTheme;

    switch (role.toLowerCase()) {
      case 'abbatoir':
      case 'abattoir':
        return abbatoirTheme;
      case 'processing_unit':
      case 'processor':
        return processorTheme;
      case 'shop':
      case 'retail':
        return shopTheme;
      default:
        return processorTheme;
    }
  }
}
