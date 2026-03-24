// lib/providers/eye_rest_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EyeRestProvider with ChangeNotifier {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isEnabled = true;
  int _reminderIntervalMinutes = 20; // Default 20-20-20 rule
  bool _shouldShowAlert = false;

  bool get isEnabled => _isEnabled;
  int get reminderIntervalMinutes => _reminderIntervalMinutes;
  bool get shouldShowAlert => _shouldShowAlert;
  int get secondsRemaining => (_reminderIntervalMinutes * 60) - _secondsElapsed;

  EyeRestProvider() {
    _loadSettings();
    _startTimer();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('eye_rest_enabled') ?? true;
    _reminderIntervalMinutes = prefs.getInt('eye_rest_interval') ?? 20;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_isEnabled) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;
      if (_secondsElapsed >= (_reminderIntervalMinutes * 60)) {
        _shouldShowAlert = true;
        _timer?.cancel();
        notifyListeners();
      }
    });
  }

  void resetTimer() {
    _secondsElapsed = 0;
    _shouldShowAlert = false;
    _startTimer();
    notifyListeners();
  }

  void dismissAlert() {
    _shouldShowAlert = false;
    resetTimer();
  }

  Future<void> toggleEnabled(bool value) async {
    _isEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eye_rest_enabled', value);
    if (_isEnabled) {
      resetTimer();
    } else {
      _timer?.cancel();
    }
    notifyListeners();
  }

  Future<void> setInterval(int minutes) async {
    _reminderIntervalMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('eye_rest_interval', minutes);
    resetTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
