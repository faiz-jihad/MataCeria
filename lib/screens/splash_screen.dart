
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
    debugPrint('SPLASH_DEBUG: Verifying session for token presence...');
    
    try {
      // Use a timeout to avoid getting stuck forever on splash
      final user = await apiService.getCurrentUser().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
           debugPrint('SPLASH_DEBUG: User fetch timed out, skipping to welcome/login');
           return null;
        },
      );
      
      if (user != null) {
        debugPrint('SPLASH_DEBUG: User verified: ${user.name}');
        _finishSplash(splashStart, '/home');
      } else {
        debugPrint('SPLASH_DEBUG: User verification failed or timed out');
        await apiService.logout(); // Clear token to be safe
        _finishSplash(splashStart, '/welcome');
      }
    } catch (e) {
      debugPrint('SPLASH_ERROR: Error during verification: $e');
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
