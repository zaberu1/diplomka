// lib/screens/setup/place_selection_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'schedule_mode_selection_page.dart';
import 'app_mode_selection_page.dart';
import '../../services/shared_prefs_service.dart';
import '../../services/database_service.dart';

class PlaceSelectionPage extends StatelessWidget {
  const PlaceSelectionPage({super.key});

  Future<void> _savePlaceAndOpen(BuildContext context, String place) async {
    final user = databaseService.user;
    if (user != null) {
      await databaseService.updateUserData({
        'institutionId': place,
      });
    }

    await SharedPrefsService.setPlace(place);
    
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ScheduleModeSelectionPage()),
      );
    }
  }

  Widget _buildGlassButton(
    BuildContext context, {
    required IconData icon,
    required String label,
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
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.amber, size: 64),
                const SizedBox(height: 16),
                Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Настройка'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AppModeSelectionPage()),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Где вы учитесь?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 40),
                _buildGlassButton(context, icon: Icons.school_outlined, label: 'Школа', onTap: () => _savePlaceAndOpen(context, 'school')),
                _buildGlassButton(context, icon: Icons.account_balance_outlined, label: 'Колледж', onTap: () => _savePlaceAndOpen(context, 'college')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
