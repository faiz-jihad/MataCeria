import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // ========== CONFIGURATION ==========
  static String get baseUrl {
    try {
      final raw = dotenv.env['API_BASE_URL'] ??
          'https://estimate-known-latex-library.trycloudflare.com/';
      return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    } catch (_) {
      // Fallback if dotenv is not initialized
      return 'https://estimate-known-latex-library.trycloudflare.com';
    }
  }

  static String get mlBaseUrl => baseUrl;
  
  /// The backend confirmed the prefix is /api/v1
  static String get fullBaseUrl => '$baseUrl/api/v1';
  static String get v2BaseUrl => '$baseUrl/api/v2';

  // ========== 1. AUTH (/api/v1/auth) ==========
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/logout'; // misc router

  // ========== 2. USER (/api/v1/user) ==========
  static const String user = '/user/me';
  static const String userSettings = '/user/settings';
  static const String profileImage = '/user/profile-image';
  static const String changePassword = '/user/change-password';
  static const String activities = '/user/activities';

  // ========== 3. REFRACTION (/api/v1/refraction + /api/v2/refraction) ==========
  // V1 – Snellen test result
  static const String cameraRefractionTest = '/refraction/test';
  // V2 – AI processing (via v2BaseUrl)
  static const String aiRefractionV2 = '/refraction/ai';
  static const String detectDistance = '/refraction/detect-distance';

  // ========== 4. TESTING HISTORY (/api/v1) ==========
  /// POST / GET – save & fetch refraction test history
  static const String refractionTest = '/refraction-test';
  static const String uploadTest = '/refraction-test'; // compatibility alias
  static const String predictions = '/predictions';

  // ========== 5. ARTICLES (/api/v1/articles) ==========
  static const String articles = '/articles';
  static const String researchSearch = '/articles/research-search';
  static const String uploadArticleImage = '/articles/upload-image';

  // ========== 6. CHAT (/api/v1/chat) ==========
  static const String chat = '/chat/send'; // ← correct endpoint is /chat/send
  static const String chatHistory = '/chat/history';
  static const String chatMessages = '/chat/messages';
  static const String chatSessions = '/chat/sessions';
  static const String chatFeedback = '/chat/feedback';
  static const String unreadChats = '/chat/unread-count';

  // ========== 7. NOTIFICATIONS (/api/v1/notifications) ==========
  static const String notifications = '/notifications';
  static const String readAll = '/notifications/read-all';

  // ========== 8. EMERGENCY (/api/v1/emergency) ==========
  static const String emergencyContacts = '/emergency/contacts';

  // ========== 9. ADMIN (/api/v1/admin) ==========
  static const String adminStats = '/admin/stats/overview';
  static const String adminUsers = '/admin/users';
  static const String adminExport = '/admin/users/export';
  static const String adminBroadcast = '/admin/notifications/broadcast';
  static const String adminTests = '/admin/tests';

  // ========== 10. MISC (/api/v1) ==========
  static const String mlConditions = '/conditions';
  static const String mlHealth = '/health';

  // ========== GENERAL ==========
  static const int connectionTimeout = 30;
}
