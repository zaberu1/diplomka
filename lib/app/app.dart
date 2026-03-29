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
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.amber,
            useMaterial3: true,
          ),
          // Используем StreamBuilder для мгновенного отслеживания статуса входа
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              // Пока ждем ответа от Firebase, показываем Splash
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              
              // Если пользователь авторизован
              if (snapshot.hasData && snapshot.data != null) {
                return FutureBuilder<SharedPreferences>(
                  future: SharedPreferences.getInstance(),
                  builder: (context, prefsSnapshot) {
                    if (!prefsSnapshot.hasData) return const SplashScreen();
                    
                    final place = prefsSnapshot.data!.getString('selected_place');
                    // Если место уже выбрано, идем на главную, иначе на выбор места
                    if (place != null) {
                      return HomePage(place: place);
                    } else {
                      return const PlaceSelectionPage();
                    }
                  },
                );
              }
              
              // Если не авторизован — проверяем, видел ли он приветствие
              return FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, prefsSnapshot) {
                  if (!prefsSnapshot.hasData) return const SplashScreen();
                  final completed = prefsSnapshot.data!.getBool('welcome_completed') ?? false;
                  return completed ? const AuthPage() : const WelcomePage();
                },
              );
            },
          ),
          routes: {
            '/welcome': (context) => const WelcomePage(),
            '/auth': (context) => const AuthPage(),
            '/settings': (context) => const SettingsPage(),
            '/profile': (context) => const ProfilePage(),
            '/history': (context) => const HistoryPage(),
            '/edit_profile': (context) => const EditProfilePage(),
          },
        );
      },
    );
  }
}
