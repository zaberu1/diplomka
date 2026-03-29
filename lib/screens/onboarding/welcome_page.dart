// lib/screens/onboarding/welcome_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme_controller.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _completeWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_completed', true);
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTheme = themeController.value;
    final newTheme = currentTheme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await prefs.setString('theme_mode', newTheme == ThemeMode.light ? 'light' : 'dark');
    themeController.value = newTheme;
  }

  Widget _buildGlassCard({required Widget child, double opacity = 0.05, double blur = 15, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
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
          // Фон
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [const Color(0xFF0F2027), const Color(0xFF203A43)] 
                  : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)],
              ),
            ),
          ),
          // Сферы
          Positioned(
            top: 50, right: -30,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber.withOpacity(0.1))),
            ),
          ),
          Positioned(
            bottom: 50, left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.05))),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildGlassCard(
                        padding: EdgeInsets.zero,
                        blur: 10,
                        opacity: 0.1,
                        child: IconButton(
                          onPressed: _toggleTheme,
                          icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Логотип
                  Hero(
                    tag: 'logo',
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber.withOpacity(0.1),
                        border: Border.all(color: Colors.amber.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 80),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('ZvonOK', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  Text('Твой умный график звонков', style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.black54)),
                  
                  const SizedBox(height: 40),

                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('О приложении', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        _buildFeatureItem(Icons.schedule_rounded, 'Индивидуальность', 'Своё расписание для школы или вуза', Colors.green),
                        _buildFeatureItem(Icons.notifications_active_rounded, 'Уведомления', 'Напоминания о начале и конце пар', Colors.orange),
                        _buildFeatureItem(Icons.cloud_sync_rounded, 'Синхронизация', 'Доступ к графику с любого устройства', Colors.blue),
                        _buildFeatureItem(Icons.history_rounded, 'История', 'Все изменения всегда под рукой', Colors.purple),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _completeWelcome();
                        if (context.mounted) Navigator.pushReplacementNamed(context, '/auth');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 10,
                        shadowColor: Colors.amber.withOpacity(0.3),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Начать использовать', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(width: 12),
                          Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Версия 1.0.0 • Сделано с любовью для студентов',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.black26),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(desc, style: const TextStyle(fontSize: 13, color: Colors.white54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
