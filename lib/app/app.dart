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
import '../screens/setup/join_institution_page.dart';
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
    themeController.loadSettings(); // Загружаем сохраненную тему и цвет
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeState>(
      valueListenable: themeController,
      builder: (context, state, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ZvonOK',
          themeMode: state.mode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: state.accentColor,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: state.accentColor,
              brightness: Brightness.dark,
            ),
          ),
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

                    final String? mode = userData['appMode'];
                    final String? instId = userData['institutionId'];
                    final bool setupDone = userData['setupCompleted'] ?? false;

                    if (mode == null) return const AppModeSelectionPage();
                    
                    if (mode == 'manual') {
                      if (instId == null) return const PlaceSelectionPage();
                      if (!setupDone) return const ScheduleModeSelectionPage();
                      return HomePage(place: instId);
                    } else {
                      if (instId == null || !setupDone) return const JoinInstitutionPage();
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
