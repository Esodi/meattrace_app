import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MeatTrace Pro Design System - Typography
/// Version 2.0 - Enhanced typography with Poppins for headings
class AppTypography {
  // ========== FONT FAMILIES ==========
  
  /// Primary font: Poppins - Modern, friendly, professional
  /// Used for: Headings, titles, important UI elements
  static String get primaryFont => 'Poppins';

  /// Secondary font: Roboto - Clean, readable, versatile
  /// Used for: Body text, labels, descriptions
  static String get secondaryFont => 'Roboto';

  /// Monospace font: Roboto Mono - Code and IDs
  /// Used for: Animal IDs, batch numbers, QR codes
  static String get monoFont => 'RobotoMono';

  /// Script font: Playfair Display - Elegant serif for special text
  /// Used for: App subtitles, elegant headings
  static String get scriptFont => 'PlayfairDisplay';
  
  // ========== DISPLAY STYLES (Poppins - Extra Large Headlines) ==========
  
  /// Display Large: 57px / Bold (700) / -0.25px letter spacing
  /// Usage: Hero sections, splash screens
  static TextStyle displayLarge({Color? color}) => GoogleFonts.poppins(
    fontSize: 57,
    height: 1.12,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    color: color,
  );
  
  /// Display Medium: 45px / Bold (700) / 0px letter spacing
  /// Usage: Large titles, feature highlights
  static TextStyle displayMedium({Color? color}) => GoogleFonts.poppins(
    fontSize: 45,
    height: 1.16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: color,
  );
  
  /// Display Small: 36px / Bold (600) / 0px letter spacing
  /// Usage: Section headers, dialog titles
  static TextStyle displaySmall({Color? color}) => GoogleFonts.poppins(
    fontSize: 36,
    height: 1.22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: color,
  );
  
  // ========== HEADLINE STYLES (Poppins - Large Headlines) ==========
  
  /// Headline Large: 32px / SemiBold (600) / 0px letter spacing
  /// Usage: Screen titles, major sections
  static TextStyle headlineLarge({Color? color}) => GoogleFonts.poppins(
    fontSize: 32,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: color,
  );
  
  /// Headline Medium: 28px / SemiBold (600) / 0px letter spacing
  /// Usage: Dashboard cards, feature titles
  static TextStyle headlineMedium({Color? color}) => GoogleFonts.poppins(
    fontSize: 28,
    height: 1.29,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: color,
  );
  
  /// Headline Small: 24px / SemiBold (600) / 0px letter spacing
  /// Usage: Subsection headers, card titles
  static TextStyle headlineSmall({Color? color}) => GoogleFonts.poppins(
    fontSize: 24,
    height: 1.33,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: color,
  );
  
  // ========== TITLE STYLES (Poppins - Medium Titles) ==========
  
  /// Title Large: 22px / Medium (500) / 0px letter spacing
  /// Usage: List item titles, prominent labels
  static TextStyle titleLarge({Color? color}) => GoogleFonts.poppins(
    fontSize: 22,
    height: 1.27,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: color,
  );
  
  /// Title Medium: 16px / Medium (500) / 0.15px letter spacing
  /// Usage: Standard titles, navigation labels
  static TextStyle titleMedium({Color? color}) => GoogleFonts.poppins(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    color: color,
  );
  
  /// Title Small: 14px / Medium (500) / 0.1px letter spacing
  /// Usage: Small titles, compact headers
  static TextStyle titleSmall({Color? color}) => GoogleFonts.poppins(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: color,
  );
  
  // ========== BODY STYLES (Roboto - Body Text) ==========
  
  /// Body Large: 16px / Regular (400) / 0.5px letter spacing
  /// Usage: Primary body text, descriptions
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.roboto(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: color,
  );
  
  /// Body Medium: 14px / Regular (400) / 0.25px letter spacing
  /// Usage: Secondary body text, list items
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.roboto(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: color,
  );
  
  /// Body Small: 12px / Regular (400) / 0.4px letter spacing
  /// Usage: Captions, helper text, timestamps
  static TextStyle bodySmall({Color? color}) => GoogleFonts.roboto(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: color,
  );
  
  // ========== LABEL STYLES (Roboto - UI Labels) ==========
  
  /// Label Large: 14px / Medium (500) / 0.1px letter spacing
  /// Usage: Button text, prominent labels
  static TextStyle labelLarge({Color? color}) => GoogleFonts.roboto(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: color,
  );
  
  /// Label Medium: 12px / Medium (500) / 0.5px letter spacing
  /// Usage: Input labels, small buttons
  static TextStyle labelMedium({Color? color}) => GoogleFonts.roboto(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: color,
  );
  
  /// Label Small: 11px / Medium (500) / 0.5px letter spacing
  /// Usage: Tiny labels, badges, chips
  static TextStyle labelSmall({Color? color}) => GoogleFonts.roboto(
    fontSize: 11,
    height: 1.45,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: color,
  );
  
  // ========== SPECIALIZED STYLES ==========
  
  /// Button Text: 14px / SemiBold (600) / 1.25px letter spacing (uppercase)
  /// Usage: Primary and secondary buttons
  static TextStyle button({Color? color}) => GoogleFonts.roboto(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.25,
    color: color,
  );
  
  /// Overline: 10px / Medium (500) / 1.5px letter spacing (uppercase)
  /// Usage: Section labels, category tags
  static TextStyle overline({Color? color}) => GoogleFonts.roboto(
    fontSize: 10,
    height: 1.6,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: color,
  );
  
  /// Caption: 12px / Regular (400) / 0.4px letter spacing
  /// Usage: Image captions, footnotes
  static TextStyle caption({Color? color}) => GoogleFonts.roboto(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: color,
  );
  
  /// Code/Mono: 14px / Regular (400) / Monospace
  /// Usage: Animal IDs, batch codes, technical data
  static TextStyle code({Color? color}) => GoogleFonts.robotoMono(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: color,
  );
  
  /// Code Large: 16px / Medium (500) / Monospace
  /// Usage: Prominent IDs, QR code labels
  static TextStyle codeLarge({Color? color}) => GoogleFonts.robotoMono(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: color,
  );
  
  /// Numeric Large: 28px / Bold (700) / Roboto (tabular numbers)
  /// Usage: Statistics, counters, metrics
  static TextStyle numericLarge({Color? color}) => GoogleFonts.roboto(
    fontSize: 28,
    height: 1.29,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    fontFeatures: [const FontFeature.tabularFigures()],
    color: color,
  );
  
  /// Numeric Medium: 20px / SemiBold (600) / Roboto (tabular numbers)
  /// Usage: Card statistics, dashboard numbers
  static TextStyle numericMedium({Color? color}) => GoogleFonts.roboto(
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    fontFeatures: [const FontFeature.tabularFigures()],
    color: color,
  );
  
  /// Numeric Small: 16px / Medium (500) / Roboto (tabular numbers)
  /// Usage: Inline numbers, list counts
  static TextStyle numericSmall({Color? color}) => GoogleFonts.roboto(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    fontFeatures: [const FontFeature.tabularFigures()],
    color: color,
  );
  
  // ========== CONTEXT-SPECIFIC STYLES ==========
  
  /// AppBar Title: 20px / SemiBold (600) / Poppins
  static TextStyle appBarTitle({Color? color}) => GoogleFonts.poppins(
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: color,
  );
  
  /// Bottom Nav Label: 12px / Medium (500) / Roboto
  static TextStyle bottomNavLabel({Color? color}) => GoogleFonts.roboto(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: color,
  );
  
  /// Tab Label: 14px / Medium (500) / Roboto / Uppercase
  static TextStyle tabLabel({Color? color}) => GoogleFonts.roboto(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
    color: color,
  );
  
  /// Chip Label: 13px / Medium (500) / Roboto
  static TextStyle chipLabel({Color? color}) => GoogleFonts.roboto(
    fontSize: 13,
    height: 1.38,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    color: color,
  );
  
  /// Badge Text: 10px / Bold (700) / Roboto
  static TextStyle badge({Color? color}) => GoogleFonts.roboto(
    fontSize: 10,
    height: 1.6,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: color,
  );
  
  /// Tooltip: 12px / Regular (400) / Roboto
  static TextStyle tooltip({Color? color}) => GoogleFonts.roboto(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: color,
  );

  /// Error Message: 12px / Regular (400) / Roboto
  static TextStyle error({Color? color}) => GoogleFonts.roboto(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: color,
  );

  /// Helper Text: 12px / Regular (400) / Roboto
  static TextStyle helper({Color? color}) => GoogleFonts.roboto(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: color,
  );

  // ========== SCRIPT FONT STYLES (Playfair Display) ==========

  /// Script Large: 24px / Regular (400) / Playfair Display
  /// Usage: Elegant subtitles, special headings
  static TextStyle scriptLarge({Color? color}) => GoogleFonts.playfairDisplay(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: color,
  );

  /// Script Medium: 20px / Regular (400) / Playfair Display
  /// Usage: App subtitles, elegant labels
  static TextStyle scriptMedium({Color? color}) => GoogleFonts.playfairDisplay(
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: color,
  );

  /// Script Small: 16px / Regular (400) / Playfair Display
  /// Usage: Small elegant text, captions
  static TextStyle scriptSmall({Color? color}) => GoogleFonts.playfairDisplay(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: color,
  );
  
  // ========== TEXT STYLE MODIFIERS ==========
  
  /// Make text bold
  static TextStyle bold(TextStyle style) => style.copyWith(
    fontWeight: FontWeight.w700,
  );
  
  /// Make text semi-bold
  static TextStyle semiBold(TextStyle style) => style.copyWith(
    fontWeight: FontWeight.w600,
  );
  
  /// Make text medium weight
  static TextStyle medium(TextStyle style) => style.copyWith(
    fontWeight: FontWeight.w500,
  );
  
  /// Make text italic
  static TextStyle italic(TextStyle style) => style.copyWith(
    fontStyle: FontStyle.italic,
  );
  
  /// Make text underlined
  static TextStyle underline(TextStyle style) => style.copyWith(
    decoration: TextDecoration.underline,
  );
  
  /// Make text line-through
  static TextStyle lineThrough(TextStyle style) => style.copyWith(
    decoration: TextDecoration.lineThrough,
  );
  
  /// Change text color
  static TextStyle withColor(TextStyle style, Color color) => style.copyWith(
    color: color,
  );
  
  /// Change text opacity
  static TextStyle withOpacity(TextStyle style, double opacity) => style.copyWith(
    color: style.color?.withOpacity(opacity),
  );
  
  /// Add letter spacing
  static TextStyle withLetterSpacing(TextStyle style, double spacing) => style.copyWith(
    letterSpacing: spacing,
  );
  
  /// Change line height
  static TextStyle withHeight(TextStyle style, double height) => style.copyWith(
    height: height,
  );
}
