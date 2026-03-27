import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // ========== CONFIGURATION ==========
  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ??
        'https://using-students-categories-discovery.trycloudflare.com';
  }

  static String get mlBaseUrl => baseUrl;
  static const String apiVersion = 'v1';
  static String get fullBaseUrl => '$baseUrl/api/$apiVersion';
  static String get v2BaseUrl => '$baseUrl/api/v2';

  // ========== 1. AUTENTIKASI (/auth) ==========
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/logout';

  // ========== 2. PROFIL PENGGUNA (/user) ==========
  static const String userMe = '/user/me';
  static const String user = '/user/me'; // Compatibility
  static const String profileImage = '/user/profile-image';
  static const String activities = '/user/activities';
  static const String changePassword = '/user/change-password';

  // ========== 3. TES REFRAKSI (/refraction & /api/v2) ==========
  static const String refractionTest = '/refraction-test'; // Standard V1
  static const String uploadTest = '/refraction-test'; // Compatibility
  static const String cameraRefractionTest =
      '/refraction/test'; // Compatibility
  static const String aiRefractionV2 = '/refraction/ai'; // AI Hybrid V2
  static const String detectDistance = '/refraction/detect-distance'; // V2

  // ========== 4. ARTIKEL & RISET (/articles) ==========
  static const String articles = '/articles';
  static const String researchSearch = '/articles/research-search';
  static const String uploadArticleImage = '/articles/upload-image';

  // ========== 5. NOTIFIKASI (/notifications) ==========
  static const String notifications = '/notifications';
  static const String markRead = '/read'; // append to notification ID
  static const String readAll = '/notifications/read-all';

  // ========== 6. ADMIN TOOLS (/admin) ==========
  static const String adminStats = '/admin/stats/overview';
  static const String adminUsers = '/admin/users';
  static const String adminExport = '/admin/users/export';
  static const String adminBroadcast = '/admin/notifications/broadcast';
  static const String adminTests = '/admin/tests';

  // ========== 7. KONTAK DARURAT (/emergency/contacts) ==========
  static const String emergencyContacts = '/emergency/contacts';

  // ========== 8. AI CHATBOT (/chat) ==========
  static const String chat = '/chat';
  static const String chatV2 = '/chat/v2';
  static const String chatHistory = '/chat/history';
  static const String chatSessions = '/chat/sessions';
  static const String chatFeedback = '/chat/feedback';
  static const String unreadChats = '/chat/unread-count';

  // ========== 9. ANALYTICS & PREDICTIONS (Legacy/ML) ==========
  static const String analyticsUser = '/analytics/user';
  static const String analyticsCategories = '/analytics/categories';
  static const String analyticsFrequent = '/analytics/frequent';
  static const String predictions = '/predictions';
  static const String mlHealth = '/health';
  static const String mlConditions = '/conditions';
  static const String mlPredict = '/refraction-test';

  // ========== GENERAL SETTINGS ==========
  static const int connectionTimeout = 30;
}
