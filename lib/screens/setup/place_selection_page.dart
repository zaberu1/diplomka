// lib/screens/setup/place_selection_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'schedule_mode_selection_page.dart';

class PlaceSelectionPage extends StatelessWidget {
  const PlaceSelectionPage({super.key});

  Future<void> _savePlaceAndOpen(BuildContext context, String place) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_place', place);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleModeSelectionPage()),
    );
  }

  Widget _buildPlaceButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? [const Color(0xFF2A2D3E), const Color(0xFF1A1C2C)]
        : [Colors.amber.shade100, Colors.orange.shade100];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.amberAccent.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
          border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.orangeAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите место'),
        centerTitle: true,
        backgroundColor:
        isDark ? const Color(0xFF1A1C2C) : Colors.amber.shade100,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 2,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Выберите место',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            _buildPlaceButton(
              context,
              icon: Icons.school_outlined,
              label: 'Школа',
              onTap: () => _savePlaceAndOpen(context, 'school'),
            ),
            _buildPlaceButton(
              context,
              icon: Icons.school_rounded,
              label: 'Колледж',
              onTap: () => _savePlaceAndOpen(context, 'college'),
            ),
          ],
        ),
      ),
    );
  }
}