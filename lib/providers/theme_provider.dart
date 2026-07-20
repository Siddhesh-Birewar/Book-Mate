import 'package:flutter/material.dart';

/// Manages the application's theme state (light/dark mode)
/// and the PDF color inversion toggle for dark mode reading.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _invertColors = false;

  bool get isDarkMode => _isDarkMode;
  bool get invertColors => _invertColors;

  /// The active [ThemeData], built from curated color palettes
  /// for a premium reading experience.
  ThemeData get theme => _isDarkMode ? _darkTheme : _lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    // Auto-enable color inversion when switching to dark mode
    _invertColors = _isDarkMode;
    notifyListeners();
  }

  void toggleInvertColors() {
    _invertColors = !_invertColors;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Premium Light Theme
  // ──────────────────────────────────────────────

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFF6B4EFF),
    scaffoldBackgroundColor: const Color(0xFFF8F6FF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Color(0xFF6B4EFF)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF6B4EFF),
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
  // Premium Dark Theme
  // ──────────────────────────────────────────────

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFF9B85FF),
    scaffoldBackgroundColor: const Color(0xFF0D0D1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFFE8E4F0),
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Color(0xFF9B85FF)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF9B85FF),
      foregroundColor: Colors.white,
      elevation: 8,
      shape: CircleBorder(),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1A1A2E),
      surfaceTintColor: Colors.transparent,
    ),
  );
}
