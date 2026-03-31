// lib/screens/setup/app_mode_selection_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'place_selection_page.dart';
import 'coming_soon_page.dart';

class AppModeSelectionPage extends StatelessWidget {
  const AppModeSelectionPage({super.key});

  Future<void> _setMode(BuildContext context, String mode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Сохраняем в Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'appMode': mode,
      }, SetOptions(merge: true));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_operating_mode', mode);
    
    if (context.mounted) {
      if (mode == 'manual') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PlaceSelectionPage()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ComingSoonPage()));
      }
    }
  }

  Widget _buildModeButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.amber, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.white24 : Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Как будем работать?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 40),
                _buildModeButton(
                  context,
                  icon: Icons.account_balance_rounded,
                  title: 'Присоединиться',
                  subtitle: 'Найти свое учебное заведение в базе',
                  onTap: () => _setMode(context, 'join'),
                ),
                _buildModeButton(
                  context,
                  icon: Icons.edit_calendar_rounded,
                  title: 'Я сам',
                  subtitle: 'Вручную создать свое расписание звонков',
                  onTap: () => _setMode(context, 'manual'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
