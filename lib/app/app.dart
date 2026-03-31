// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../screens/setup/app_mode_selection_page.dart';
import '../screens/setup/schedule_mode_selection_page.dart';
import '../screens/setup/coming_soon_page.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/teacher/teacher_dashboard.dart';

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
          theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.amber, useMaterial3: true),
          darkTheme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.amber, useMaterial3: true),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SplashScreen();
              final user = snapshot.data;

              if (user != null) {
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) return const SplashScreen();
                    
                    final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                    if (userData == null) return const AuthPage();

                    final role = userData['role'] ?? 'student';
                    if (role == 'admin') return const AdminDashboard();
                    if (role == 'teacher') return const TeacherDashboard();

                    // --- СТУДЕНТ: ЛОГИКА ОБЛАКА ---
                    final String? mode = userData['appMode'];
                    final String? instId = userData['institutionId'];
                    final bool setupDone = userData['setupCompleted'] ?? false;

                    if (mode == null) {
                      return const AppModeSelectionPage();
                    }
                    
                    if (mode == 'manual') {
                      if (instId == null) return const PlaceSelectionPage();
                      if (!setupDone) return const ScheduleModeSelectionPage();
                      return HomePage(place: instId);
                    } else {
                      // Если режим "Присоединиться", но заведение еще не выбрано (или нет базы)
                      if (instId == null) return const ComingSoonPage();
                      return HomePage(place: instId);
                    }
                  },
                );
              }

              return FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, prefsSnapshot) {
                  if (!prefsSnapshot.hasData) return const SplashScreen();
                  final prefs = prefsSnapshot.data!;
                  final welcomeCompleted = prefs.getBool('welcome_completed') ?? false;
                  return welcomeCompleted ? const AuthPage() : const WelcomePage();
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
            '/mode_selection': (context) => const AppModeSelectionPage(),
            '/place_selection': (context) => const PlaceSelectionPage(),
            '/schedule_mode': (context) => const ScheduleModeSelectionPage(),
            '/admin': (context) => const AdminDashboard(),
            '/teacher': (context) => const TeacherDashboard(),
          },
        );
      },
    );
  }
}
