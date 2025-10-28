// lib/screens/setup/schedule_mode_selection_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../schedule/bell_schedule_page.dart';

class ScheduleModeSelectionPage extends StatelessWidget {
  const ScheduleModeSelectionPage({super.key});

  Future<void> _saveModeAndContinue(BuildContext context, bool sameEveryday) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('same_schedule', sameEveryday);
    final place = prefs.getString('selected_place') ?? 'school';
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BellSchedulePage(place: place)),
    );
  }

  Widget _buildModeCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
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
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.amberAccent.withOpacity(0.15),
              offset: const Offset(0, 6),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.orangeAccent, size: 46),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
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
        title: const Text('Тип расписания'),
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
              'Тип расписания',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Выберите формат отображения уроков',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 30),
            _buildModeCard(
              context,
              icon: Icons.calendar_today_outlined,
              title: 'Одинаковое на каждый день',
              subtitle: 'Расписание повторяется каждый день',
              onTap: () => _saveModeAndContinue(context, true),
            ),
            _buildModeCard(
              context,
              icon: Icons.event_note_outlined,
              title: 'Разное на каждый день недели',
              subtitle: 'Уникальное расписание для каждого дня',
              onTap: () => _saveModeAndContinue(context, false),
            ),
          ],
        ),
      ),
    );
  }
}