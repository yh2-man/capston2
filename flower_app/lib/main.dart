import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'theme/season_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('accessToken');
  final bool hasToken = token != null && token.isNotEmpty;

  runApp(OurTApp(hasToken: hasToken));
}

class OurTApp extends StatelessWidget {
  final bool hasToken;

  const OurTApp({super.key, this.hasToken = false});

  @override
  Widget build(BuildContext context) {
    final colors = SeasonTheme.getColors();

    return MaterialApp(
      title: 'OurT',
      debugShowCheckedModeBanner: false,
      theme: colors.toThemeData(),
      home: hasToken ? const MainScreen() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
