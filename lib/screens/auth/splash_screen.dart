// lib/screens/auth/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../schedule/bell_schedule_page.dart';
import '../setup/schedule_mode_selection_page.dart';
import 'auth_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), _goNext);
  }

  Future<void> _goNext() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final savedPlace = prefs.getString('selected_place');

    if (user != null) {
      if (savedPlace != null) {
        _navigateWithFade(context, BellSchedulePage(place: savedPlace));
      } else {
        _navigateWithFade(context, const ScheduleModeSelectionPage());
      }
    } else {
      _navigateWithFade(context, const AuthPage());
    }
  }

  void _navigateWithFade(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.notifications_active, size: 80, color: Colors.amber),
            SizedBox(height: 20),
            Text(
              'ZvonOK',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text('Расписание звонков', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}