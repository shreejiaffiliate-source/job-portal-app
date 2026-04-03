import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // Helper to check if we are currently in Dark Mode (regardless of how we got there)
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // We can't know the system brightness here easily without context,
      // but for the switch logic, we usually rely on the UI checking Theme.of(context)
      return false;
    }
    return _themeMode == ThemeMode.dark;
  }

  // NEW KEY: Changing this forces the app to ignore old saved settings
  static const String _storageKey = 'theme_pref_v1';

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, isDark);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we have a saved preference with the NEW key
    if (!prefs.containsKey(_storageKey)) {
      _themeMode = ThemeMode.system; // <--- Default to System if no new key found
    } else {
      final isDark = prefs.getBool(_storageKey) ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }

    notifyListeners();
  }
}