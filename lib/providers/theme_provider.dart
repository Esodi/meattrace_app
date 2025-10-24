import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

enum ThemePreference { light, dark, system }

class ThemeProvider with ChangeNotifier {
  static const String _darkModeKey = 'isDarkMode';
  static const String _themePreferenceKey = 'themePreference';
  static const String _highContrastKey = 'isHighContrastEnabled';
  static const String _textScaleKey = 'textScale';
  static const String _reduceMotionKey = 'reduceMotion';

  ThemePreference _themePreference = ThemePreference.system;
  bool _systemIsDark = false;
  bool _isHighContrastEnabled = false;
  bool _reduceMotion = false;
  double _textScale = 1.0;
  ThemeData _currentTheme = AppTheme.lightTheme;

  ThemePreference get themePreference => _themePreference;
  bool get isDarkMode => _themePreference == ThemePreference.dark ||
                        (_themePreference == ThemePreference.system && _systemIsDark);
  bool get isHighContrastEnabled => _isHighContrastEnabled;
  bool get reduceMotion => _reduceMotion;
  double get textScale => _textScale;
  ThemeData get currentTheme => _currentTheme;
  ThemeMode get themeMode {
    if (_themePreference == ThemePreference.system) {
      return ThemeMode.system;
    }
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Migrate old preference if exists
    final oldDarkMode = prefs.getBool(_darkModeKey);
    if (oldDarkMode != null) {
      _themePreference = oldDarkMode ? ThemePreference.dark : ThemePreference.light;
      // Remove old key after migration
      await prefs.remove(_darkModeKey);
    } else {
      final preferenceString = prefs.getString(_themePreferenceKey);
      _themePreference = ThemePreference.values.firstWhere(
        (e) => e.name == preferenceString,
        orElse: () => ThemePreference.system,
      );
    }
    _isHighContrastEnabled = prefs.getBool(_highContrastKey) ?? false;
    _textScale = prefs.getDouble(_textScaleKey) ?? 1.0;
    _reduceMotion = prefs.getBool(_reduceMotionKey) ?? false;
    _updateTheme();
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, _themePreference.name);
    await prefs.setBool(_highContrastKey, _isHighContrastEnabled);
    await prefs.setDouble(_textScaleKey, _textScale);
    await prefs.setBool(_reduceMotionKey, _reduceMotion);
  }

  void setLightMode() {
    if (_themePreference != ThemePreference.light) {
      _themePreference = ThemePreference.light;
      _updateTheme();
      _saveThemeToPrefs();
      notifyListeners();
    }
  }

  void setDarkMode() {
    if (_themePreference != ThemePreference.dark) {
      _themePreference = ThemePreference.dark;
      _updateTheme();
      _saveThemeToPrefs();
      notifyListeners();
    }
  }

  void setSystemMode() {
    if (_themePreference != ThemePreference.system) {
      _themePreference = ThemePreference.system;
      _updateTheme();
      _saveThemeToPrefs();
      notifyListeners();
    }
  }

  void toggleTheme() {
    if (_themePreference == ThemePreference.light) {
      _themePreference = ThemePreference.dark;
    } else if (_themePreference == ThemePreference.dark) {
      _themePreference = ThemePreference.light;
    } else {
      // If system, toggle to opposite of current system state
      _themePreference = _systemIsDark ? ThemePreference.light : ThemePreference.dark;
    }
    _updateTheme();
    _saveThemeToPrefs();
    notifyListeners();
  }

  void updateSystemBrightness(bool isDark) {
    if (_systemIsDark != isDark) {
      _systemIsDark = isDark;
      if (_themePreference == ThemePreference.system) {
        _updateTheme();
        notifyListeners();
      }
    }
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

  void setTextScale(double scale) {
    if (_textScale != scale && scale >= 0.8 && scale <= 1.4) {
      _textScale = scale;
      _updateTheme();
      _saveThemeToPrefs();
      notifyListeners();
    }
  }

  void increaseTextSize() {
    final newScale = (_textScale + 0.1).clamp(0.8, 1.4);
    setTextScale(newScale);
  }

  void decreaseTextSize() {
    final newScale = (_textScale - 0.1).clamp(0.8, 1.4);
    setTextScale(newScale);
  }

  void setReduceMotion(bool enabled) {
    if (_reduceMotion != enabled) {
      _reduceMotion = enabled;
      _saveThemeToPrefs();
      notifyListeners();
    }
  }

  void _updateTheme() {
    ThemeData baseTheme = isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

    if (_isHighContrastEnabled) {
      _currentTheme = _createHighContrastTheme(baseTheme);
    } else {
      _currentTheme = baseTheme;
    }
  }

  ThemeData _createHighContrastTheme(ThemeData baseTheme) {
    // Apply text scaling to the base text theme
    final scaledTextTheme = baseTheme.textTheme.copyWith(
      displayLarge: baseTheme.textTheme.displayLarge?.copyWith(fontSize: (baseTheme.textTheme.displayLarge?.fontSize ?? 32) * _textScale),
      displayMedium: baseTheme.textTheme.displayMedium?.copyWith(fontSize: (baseTheme.textTheme.displayMedium?.fontSize ?? 28) * _textScale),
      displaySmall: baseTheme.textTheme.displaySmall?.copyWith(fontSize: (baseTheme.textTheme.displaySmall?.fontSize ?? 24) * _textScale),
      headlineLarge: baseTheme.textTheme.headlineLarge?.copyWith(fontSize: (baseTheme.textTheme.headlineLarge?.fontSize ?? 22) * _textScale),
      headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(fontSize: (baseTheme.textTheme.headlineMedium?.fontSize ?? 18) * _textScale),
      headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(fontSize: (baseTheme.textTheme.headlineSmall?.fontSize ?? 16) * _textScale),
      titleLarge: baseTheme.textTheme.titleLarge?.copyWith(fontSize: (baseTheme.textTheme.titleLarge?.fontSize ?? 16) * _textScale),
      titleMedium: baseTheme.textTheme.titleMedium?.copyWith(fontSize: (baseTheme.textTheme.titleMedium?.fontSize ?? 14) * _textScale),
      titleSmall: baseTheme.textTheme.titleSmall?.copyWith(fontSize: (baseTheme.textTheme.titleSmall?.fontSize ?? 12) * _textScale),
      bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
        fontSize: (baseTheme.textTheme.bodyLarge?.fontSize ?? 14) * _textScale,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
      bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
        fontSize: (baseTheme.textTheme.bodyMedium?.fontSize ?? 12) * _textScale,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
      bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
        fontSize: (baseTheme.textTheme.bodySmall?.fontSize ?? 12) * _textScale,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );

    return baseTheme.copyWith(
      textTheme: scaledTextTheme,
      cardTheme: baseTheme.cardTheme.copyWith(
        color: isDarkMode ? Colors.black : Colors.white,
        shadowColor: isDarkMode ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? Colors.yellow : Colors.blue.shade900,
          foregroundColor: isDarkMode ? Colors.black : Colors.white,
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
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}







