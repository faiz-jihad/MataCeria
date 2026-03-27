import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {

  ThemeProvider() {
    _loadTheme();
  }
  bool _isDarkMode = false;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode_enabled') ?? false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isOn) async {
    if (_isDarkMode == isOn) return;
    _isDarkMode = isOn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode_enabled', isOn);
    notifyListeners();
  }
}
