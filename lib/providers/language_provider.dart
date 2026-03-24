import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'id';
  
  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language_code') ?? 'id';
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    if (_currentLanguage == langCode) return;
    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', langCode);
    notifyListeners();
  }
}
