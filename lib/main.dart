import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/skill_service.dart';
import 'services/theme_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF5F0E8),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SkillKeeperApp());
}

class SkillKeeperApp extends StatelessWidget {
  const SkillKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => SkillService()),
        ChangeNotifierProvider(create: (_) => ThemeService()..load()),
        ChangeNotifierProvider(create: (_) {
          final s = NotificationService();
          s.init();
          return s;
        }),
      ],
      child: Consumer2<ThemeService, AuthService>(
        builder: (context, themeService, authService, _) {
          return MaterialApp(
            title: 'SkillKeeper',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            home: authService.isLoggedIn ? const MainScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
