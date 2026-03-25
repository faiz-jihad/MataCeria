// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/eye_refraction_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/prediction/camera_screen.dart';
import 'screens/prediction/result_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/chat_history_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/eye_rest_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/article_detail_screen.dart';
import 'providers/refraction_test_provider.dart';
import 'screens/prediction/ai_refraction_test_screen.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_article_list_screen.dart';
import 'screens/admin/admin_emergency_list_screen.dart';
import 'screens/admin/admin_export_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Production Error Handling
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Oops, terjadi kesalahan!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exception.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Restart Aplikasi'),
              ),
            ],
          ),
        ),
      ),
    );
  };

  final prefs = await SharedPreferences.getInstance();
  final hasToken = prefs.containsKey('access_token');
  runApp(MyApp(isLoggedIn: hasToken));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EyeRefractionProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => EyeRestProvider()),
        ChangeNotifierProvider(create: (_) => RefractionTestProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Eye Refraksi',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
            ),
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
              fontFamily: 'GoogleSans',
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/welcome': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/camera': (context) => const CameraScreen(),
              '/refraction_test': (context) => const AIRefractionTestScreen(),
              '/result': (context) => const ResultScreen(),
              '/chat': (context) => const ChatScreen(),
              '/chat-history': (context) => const ChatHistoryScreen(),
              '/analytics': (context) => const AnalyticsScreen(),
              '/article-detail': (context) {
                final article = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                return ArticleDetailScreen(article: article);
              },
              '/admin': (context) => const AdminDashboardScreen(),
              '/admin/articles': (context) => const AdminArticleListScreen(),
              '/admin/emergency': (context) => const AdminEmergencyListScreen(),
              '/admin/export': (context) => const AdminExportScreen(),
            },
          );
        },
      ),
    );
  }
}

