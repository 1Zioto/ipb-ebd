import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_service.dart';
import 'core/context_controller.dart';
import 'core/theme_controller.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.init();
  await ThemeController.instance.init();
  await ContextController.instance.init();

  final prefs = await SharedPreferences.getInstance();
  final skipWelcome = prefs.getBool('skip_welcome_screen') ?? false;

  runApp(ConciliaApp(skipWelcome: skipWelcome));
}

class ConciliaApp extends StatelessWidget {
  final bool skipWelcome;

  const ConciliaApp({super.key, this.skipWelcome = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Concilia-IPB',
          debugShowCheckedModeBanner: false,
          theme: ThemeController.instance.lightTheme,
          darkTheme: ThemeController.instance.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          home: SplashScreen(skipWelcome: skipWelcome),
        );
      },
    );
  }
}
