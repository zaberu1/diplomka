// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_controller.dart';
import '../screens/onboarding/welcome_page.dart';
import '../screens/auth/auth_page.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/schedule/home_page.dart';
import '../screens/setup/place_selection_page.dart';
import '../screens/settings/settings_page.dart';
import '../screens/profile/profile_page.dart';
import '../screens/settings/history_page.dart';
import '../screens/profile/edit_profile_page.dart';

class ZvonOKApp extends StatefulWidget {
  const ZvonOKApp({super.key});

  @override
  State<ZvonOKApp> createState() => _ZvonOKAppState();
}

class _ZvonOKAppState extends State<ZvonOKApp> {
  bool _use24Hour = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode') ?? 'dark';
    themeController.value = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Widget _getInitialScreen() {
    // Эта функция определяет какой экран показать при запуске
    return FutureBuilder(
      future: _determineInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        return snapshot.data ?? const SplashScreen();
      },
    );
  }

  Future<Widget> _determineInitialRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final welcomeCompleted = prefs.getBool('welcome_completed') ?? false;
      final user = FirebaseAuth.instance.currentUser;
      final place = prefs.getString('selected_place');

      // Логика навигации:
      if (!welcomeCompleted) {
        return const WelcomePage(); // Первый запуск
      } else if (user == null) {
        return const AuthPage(); // Не авторизован
      } else if (place == null) {
        return const PlaceSelectionPage(); // Не выбрано место
      } else {
        return HomePage(place: place); // Все готово
      }
    } catch (e) {
      print('Error determining initial route: $e');
      return const WelcomePage(); // При ошибке показываем Welcome
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, theme, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ZvonOK',
          themeMode: theme,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.amber,
            scaffoldBackgroundColor: const Color(0xFFF3F4F6),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              elevation: 2,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.amber,
            scaffoldBackgroundColor: const Color(0xFF0A0E21),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1C2C),
              foregroundColor: Colors.white,
              elevation: 2,
            ),
            useMaterial3: true,
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: _use24Hour),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: _getInitialScreen(), // Динамический начальный экран
          routes: {
            '/welcome': (context) => const WelcomePage(),
            '/auth': (context) => const AuthPage(),
            '/home': (context) => HomePage(place: 'school'),
            '/settings': (context) => const SettingsPage(),
            '/profile': (context) => const ProfilePage(),
            '/history': (context) => const HistoryPage(),
            '/edit_profile': (context) => EditProfilePage(),
          },
        );
      },
    );
  }
}