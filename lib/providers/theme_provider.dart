import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  static const String _fontKey = 'selected_font';
  static const String _radiusKey = 'corner_radius';
  static const String _elevationKey = 'elevation_level';
  static const String _isDynamicKey = 'is_dynamic';
  final SharedPreferences _prefs;

  // Default values
  static const String defaultTheme = 'Ocean Breeze Light';
  static const String defaultFont = 'Default';
  static const double defaultCornerRadius = 8.0;
  static const double defaultElevation = 2.0;
  static const bool defaultDynamic = false;

  // Current values with defaults
  String _currentTheme = defaultTheme;
  String _currentFont = defaultFont;
  double _cornerRadius = defaultCornerRadius;
  double _elevationLevel = defaultElevation;
  bool _isDynamic = defaultDynamic;

  ThemeProvider(this._prefs) {
    _loadPreferences();
  }

  // Available fonts
  static final Map<String, TextTheme Function(TextTheme)> fonts = {
    'Default': (theme) => theme,
    'Poppins': (theme) => GoogleFonts.poppinsTextTheme(theme),
    'Roboto': (theme) => GoogleFonts.robotoTextTheme(theme),
    'Montserrat': (theme) => GoogleFonts.montserratTextTheme(theme),
    'Lato': (theme) => GoogleFonts.latoTextTheme(theme),
    'Ubuntu': (theme) => GoogleFonts.ubuntuTextTheme(theme),
    'Quicksand': (theme) => GoogleFonts.quicksandTextTheme(theme),
    'Raleway': (theme) => GoogleFonts.ralewayTextTheme(theme),
  };

  // Modern color schemes
  static final Map<String, ColorScheme> colorSchemes = {
    'Ocean Breeze Light': const ColorScheme.light(
      primary: Color(0xFF1A73E8),
      secondary: Color(0xFF66B2FF),
      surface: Colors.white,
      background: Color(0xFFF8F9FA),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
    ),
    'Ocean Breeze Dark': const ColorScheme.dark(
      primary: Color(0xFF66B2FF),
      secondary: Color(0xFF1A73E8),
      surface: Color(0xFF202124),
      background: Color(0xFF202124),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    'Mint Fresh Light': const ColorScheme.light(
      primary: Color(0xFF00897B),
      secondary: Color(0xFF4DB6AC),
      surface: Colors.white,
      background: Color(0xFFF1F8E9),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
    ),
    'Mint Fresh Dark': const ColorScheme.dark(
      primary: Color(0xFF4DB6AC),
      secondary: Color(0xFF00897B),
      surface: Color(0xFF202124),
      background: Color(0xFF202124),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
  };

  // Getters
  String get currentTheme => _currentTheme;
  String get currentFont => _currentFont;
  double get cornerRadius => _cornerRadius;
  double get elevationLevel => _elevationLevel;
  bool get isDynamic => _isDynamic;
  bool get isDarkMode => _currentTheme.contains('Dark');

  // Load preferences with defaults
  void _loadPreferences() {
    try {
      _currentTheme = _prefs.getString(_themeKey) ?? defaultTheme;
      _currentFont = _prefs.getString(_fontKey) ?? defaultFont;
      _cornerRadius = _prefs.getDouble(_radiusKey) ?? defaultCornerRadius;
      _elevationLevel = _prefs.getDouble(_elevationKey) ?? defaultElevation;
      _isDynamic = _prefs.getBool(_isDynamicKey) ?? defaultDynamic;

      // Validate theme
      if (!colorSchemes.containsKey(_currentTheme)) {
        _currentTheme = defaultTheme;
      }

      // Validate font
      if (!fonts.containsKey(_currentFont)) {
        _currentFont = defaultFont;
      }

      // Validate ranges
      _cornerRadius = _cornerRadius.clamp(0.0, 20.0);
      _elevationLevel = _elevationLevel.clamp(0.0, 8.0);
    } catch (e) {
      print('Error loading preferences: $e');
      // Reset to defaults on error
      _currentTheme = defaultTheme;
      _currentFont = defaultFont;
      _cornerRadius = defaultCornerRadius;
      _elevationLevel = defaultElevation;
      _isDynamic = defaultDynamic;
    }
    notifyListeners();
  }

  // Theme getter with fallback
  ThemeData get theme {
    try {
      final colorScheme = colorSchemes[_currentTheme] ?? colorSchemes[defaultTheme]!;
      final fontFunction = fonts[_currentFont] ?? fonts[defaultFont]!;

      return ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: colorScheme.background,
        cardTheme: CardTheme(
          elevation: _elevationLevel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cornerRadius),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: _elevationLevel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_cornerRadius),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_cornerRadius),
          ),
          filled: true,
          fillColor: colorScheme.surface,
        ),
        appBarTheme: AppBarTheme(
          elevation: _elevationLevel,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        tabBarTheme: TabBarTheme(
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
          indicator: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.onPrimary,
                width: 2,
              ),
            ),
          ),
        ),
        textTheme: fontFunction(ThemeData.light().textTheme),
      );
    } catch (e) {
      print('Error creating theme: $e');
      // Return a basic fallback theme
      return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      );
    }
  }

  // Theme setters with validation
  Future<void> setTheme(String themeName) async {
    if (colorSchemes.containsKey(themeName)) {
      _currentTheme = themeName;
      await _prefs.setString(_themeKey, themeName);
      notifyListeners();
    }
  }

  Future<void> setFont(String fontName) async {
    if (fonts.containsKey(fontName)) {
      _currentFont = fontName;
      await _prefs.setString(_fontKey, fontName);
      notifyListeners();
    }
  }

  Future<void> setCornerRadius(double radius) async {
    _cornerRadius = radius.clamp(0.0, 20.0);
    await _prefs.setDouble(_radiusKey, _cornerRadius);
    notifyListeners();
  }

  Future<void> setElevation(double elevation) async {
    _elevationLevel = elevation.clamp(0.0, 8.0);
    await _prefs.setDouble(_elevationKey, _elevationLevel);
    notifyListeners();
  }

  Future<void> setDynamic(bool value) async {
    _isDynamic = value;
    await _prefs.setBool(_isDynamicKey, value);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_currentTheme.contains('Light')) {
      await setTheme(_currentTheme.replaceAll('Light', 'Dark'));
    } else {
      await setTheme(_currentTheme.replaceAll('Dark', 'Light'));
    }
  }
}
