import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.init();
  final prefs = await SharedPreferences.getInstance();
  final skipWelcome = prefs.getBool('skip_welcome_screen') ?? false;

  runApp(IpbConferenciaApp(skipWelcome: skipWelcome));
}

class IpbConferenciaApp extends StatelessWidget {
  final bool skipWelcome;

  const IpbConferenciaApp({super.key, this.skipWelcome = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPB • Gestão Integrada',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF047857),
          primary: const Color(0xFF047857),
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
        ),
      ),
      home: SplashScreen(skipWelcome: skipWelcome),
    );
  }
}
