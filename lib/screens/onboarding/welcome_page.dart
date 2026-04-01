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

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.canPop(context);

    return Scaffold(
      body: Stack(
        children: [
          // Фон реагирует на тему
          ValueListenableBuilder<ThemeState>(
            valueListenable: themeController,
            builder: (context, state, _) {
              final isDark = state.mode == ThemeMode.dark;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark 
                      ? [const Color(0xFF0F2027), const Color(0xFF203A43)] 
                      : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)],
                  ),
                ),
              );
            },
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
                      if (canPop)
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.amber, size: 28),
                        )
                      else
                        const SizedBox(height: 40),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
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
                  const Text('Твой умный график звонков', style: TextStyle(fontSize: 16, color: Colors.white54)),
                  
                  const SizedBox(height: 32),

                  _buildGlassCard(context, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Возможности', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildFeatureItem(Icons.groups_rounded, 'Для студентов', 'Подключайся к своей группе и получай расписание от преподавателя.', Colors.amber),
                      _buildFeatureItem(Icons.edit_note_rounded, 'Для всех', 'Настраивай личный график звонков вручную.', Colors.blue),
                      _buildFeatureItem(Icons.cloud_sync_rounded, 'Синхронизация', 'Данные хранятся в облаке и доступны везде.', Colors.purple),
                    ],
                  )),

                  const SizedBox(height: 20),

                  _buildGlassCard(context, opacity: 0.02, child: const Column(
                    children: [
                      Text('О проекте', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Text(
                        'ZvonOK объединяет учебные заведения в единую цифровую сеть. Наша цель — удобство и точность времени.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.white60, height: 1.5),
                      ),
                    ],
                  )),

                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!canPop) {
                          await _completeWelcome();
                          if (context.mounted) Navigator.pushReplacementNamed(context, '/auth');
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 10,
                      ),
                      child: Text(canPop ? 'Понятно, закрыть' : 'Начать использовать', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child, double opacity = 0.05}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
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

  Widget _buildFeatureItem(IconData icon, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(desc, style: const TextStyle(fontSize: 13, color: Colors.white54, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
