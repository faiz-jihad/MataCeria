import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // ========== CONFIGURATION FOR DEBUGGING ==========
  // 1. Jika di Web: gunakan 127.0.0.1
  // 2. Jika di Emulator Android: gunakan 10.0.2.2
  // 3. Jika di HP Fisik: gunakan IP LAN Laptop/PC Anda (Contoh: 192.168.1.XX)

  static const String _pcIP = '192.168.1.5'; // IP Laptop dari ipconfig

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    } else if (Platform.isAndroid) {
      // DEBUG HP FISIK: Gunakan _pcIP
      return 'http://$_pcIP:8000';
      // DEBUG EMULATOR: Gunakan 10.0.2.2
      // return 'http://10.0.2.2:8000';
      // DEBUG HP FISIK: Gunakan IP LAN Laptop/PC Anda (Contoh: 192.168.1.XX)
    } else {
      return 'https://assured-highways-auditor-headset.trycloudflare.com/';
    }
  }

  static String get mlBaseUrl => baseUrl;
  static const String apiVersion = 'v1';

  // Ini akan menghasilkan: http://.../api/v1
  static String get fullBaseUrl => '$baseUrl/api/$apiVersion';
  static String get v2BaseUrl => '$baseUrl/api/v2';

  // ========== ENDPOINTS SESUAI MAIN.PY ==========

  // Endpoint Autentikasi
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Endpoint Refraksi Mata (Upload Gambar)
  static const String uploadTest = '/refraction-test';

  // (Tambahkan endpoint lain di sini nanti jika ada fitur baru)
  static const String user = '/user/me';
  static const String logout = '/logout';

  // Endpoint Dinamis Baru
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/user/change-password';
  static const String articles = '/articles';
  static const String notifications = '/notifications';
  static const String activities = '/user/activities';
  static const String predictions = '/predictions';
  static const String unreadChats = '/chat/unread-count';
  static const String chatHistory = '/chat/history';
  static const String chatMessages = '/chat/messages';
  static const String chatSessions = '/chat/sessions';
  static const String chatSend = '/chat/send';
  static const String chatFeedback = '/chat/feedback';
  static const String analyticsUser = '/analytics/user';
  static const String analyticsCategories = '/analytics/categories';
  static const String analyticsFrequent = '/analytics/frequent';
  static const String emergencyContacts = '/emergency/contacts';
  static const String cameraRefractionTest = '/refraction/test';
  static const String aiRefractionV2 = '/refraction/ai';

  // Endpoint ML (Khusus untuk EyeRefractionService lama)
  static const String mlHealth = '/health';
  static const String mlConditions = '/conditions';
  static const String mlPredict = '/refraction-test';

  // ========== GENERAL SETTINGS ==========
  static const int connectionTimeout = 30;
}
