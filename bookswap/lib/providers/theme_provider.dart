// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true; // Start with dark mode enabled

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Return the appropriate theme based on the current setting
  ThemeData get currentTheme {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  // Define your dark theme
  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF12122F),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF12122F),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF12122F),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey[400],
    ),
    // Add other dark theme properties as needed
  );

  // Define your light theme
  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    // Add other light theme properties as needed
    // Example:
    // scaffoldBackgroundColor: Colors.white,
    // appBarTheme: AppBarTheme(
    //   backgroundColor: Colors.blue,
    //   foregroundColor: Colors.white,
    // ),
  );
}