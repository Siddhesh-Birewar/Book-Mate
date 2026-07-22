import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the application's theme state (light/dark mode)
/// and the PDF color inversion toggle for dark mode reading.
///
/// Persists theme preference to SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'bookmate_dark_mode';

  bool _isDarkMode = true; // Default to dark for OLED experience
  bool _invertColors = true;

  ThemeProvider() {
    _loadPreference();
  }

  bool get isDarkMode => _isDarkMode;
  bool get invertColors => _invertColors;

  /// The active [ThemeData], built from curated OLED-optimized palettes.
  ThemeData get theme => _isDarkMode ? _darkTheme : _lightTheme;

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_themeKey);
    if (saved != null) {
      _isDarkMode = saved;
      _invertColors = saved;
      notifyListeners();
    }
  }

  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    // Auto-enable color inversion when switching to dark mode
    _invertColors = _isDarkMode;
    _savePreference();
    notifyListeners();
  }

  void toggleInvertColors() {
    _invertColors = !_invertColors;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Warm Light Theme
  // ──────────────────────────────────────────────

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFFD4AF37),
    scaffoldBackgroundColor: const Color(0xFFFAF8F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Color(0xFFB8941F)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFD4AF37),
      foregroundColor: Colors.white,
      elevation: 8,
      shape: CircleBorder(),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
  );

  // ──────────────────────────────────────────────
  // OLED Dark Theme — True Black + Gold Accent
  // ──────────────────────────────────────────────

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFFD4AF37),
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFFE5E0D8),
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Color(0xFFD4AF37)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFD4AF37),
      foregroundColor: Color(0xFF0A0A0A),
      elevation: 8,
      shape: CircleBorder(),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF141414),
      surfaceTintColor: Colors.transparent,
    ),
  );
}
