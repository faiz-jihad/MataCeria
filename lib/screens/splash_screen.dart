
// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final splashStart = DateTime.now();
    
    final prefs = await SharedPreferences.getInstance();
    
    final hasToken = prefs.containsKey('access_token');
    if (!hasToken) {
      _finishSplash(splashStart, '/welcome');
      return;
    }

    // Verify token by fetching user
    final apiService = ApiService();
    final user = await apiService.getCurrentUser();
    
    if (user != null) {
      _finishSplash(splashStart, '/home');
    } else {
      // Token is invalid/expired
      await apiService.logout(); // Clear token
      _finishSplash(splashStart, '/welcome');
    }
  }

  Future<void> _finishSplash(DateTime startTime, String route) async {
    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(seconds: 2) - elapsed;
    
    if (remaining.inMilliseconds > 0) {
      await Future.delayed(remaining);
    }
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2563EB), // Prime Blue
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Typography Logo
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 50),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
