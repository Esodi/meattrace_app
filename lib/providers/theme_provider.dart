import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool _isHighContrastEnabled = false;
  ThemeData _currentTheme = AppTheme.lightTheme;

  bool get isDarkMode => _isDarkMode;
  bool get isHighContrastEnabled => _isHighContrastEnabled;
  ThemeData get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isHighContrastEnabled = prefs.getBool('isHighContrastEnabled') ?? false;
    _updateTheme();
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('isHighContrastEnabled', _isHighContrastEnabled);
  }

  void setLightMode() {
    if (_isDarkMode) {
      _isDarkMode = false;
      _updateTheme();
      _saveThemeToPrefs();
      notifyListeners();
    }
  }

  void setDarkMode() {
    if (!_isDarkMode) {
      _isDarkMode = true;
      _updateTheme();
      _saveThemeToPrefs();
      notifyListeners();
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _updateTheme();
    _saveThemeToPrefs();
    notifyListeners();
  }

  void toggleHighContrast() {
    _isHighContrastEnabled = !_isHighContrastEnabled;
    _updateTheme();
    _saveThemeToPrefs();
    notifyListeners();
  }

  void setHighContrast(bool enabled) {
    if (_isHighContrastEnabled != enabled) {
      _isHighContrastEnabled = enabled;
      _updateTheme();
      _saveThemeToPrefs();
      notifyListeners();
    }
  }

  void _updateTheme() {
    ThemeData baseTheme = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

    if (_isHighContrastEnabled) {
      _currentTheme = _createHighContrastTheme(baseTheme);
    } else {
      _currentTheme = baseTheme;
    }
  }

  ThemeData _createHighContrastTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(
      // Enhanced contrast for text
      textTheme: baseTheme.textTheme.copyWith(
        bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
        bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
        headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
      ),

      // Enhanced contrast for cards
      cardTheme: baseTheme.cardTheme.copyWith(
        color: _isDarkMode ? Colors.black : Colors.white,
        shadowColor: _isDarkMode ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
      ),

      // Enhanced button contrast
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isDarkMode ? Colors.yellow : Colors.blue.shade900,
          foregroundColor: _isDarkMode ? Colors.black : Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: baseTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),

      // Enhanced input decoration
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 3),
        ),
        labelStyle: baseTheme.inputDecorationTheme.labelStyle?.copyWith(
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}







