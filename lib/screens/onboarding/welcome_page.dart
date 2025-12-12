// lib/screens/onboarding/welcome_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme_controller.dart'; // Импортируем themeController

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _completeWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_completed', true);
  }

  // Функция для смены темы
  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTheme = themeController.value;
    final newTheme = currentTheme == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    await prefs.setString('theme_mode', newTheme == ThemeMode.light ? 'light' : 'dark');
    themeController.value = newTheme;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E21) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1D1E33) : Colors.amber.shade50;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Кнопка смены темы в правом верхнем углу
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // Для балансировки
                  Expanded(
                    child: Center(
                      child: Text(
                        'Добро пожаловать!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleTheme,
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: Colors.amber,
                      size: 28,
                    ),
                    tooltip: isDark ? 'Светлая тема' : 'Темная тема',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Логотип
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 80,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 20),

              // Название приложения
              Text(
                'ZvonOK',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              // Подзаголовок
              Text(
                'Умное расписание звонков',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white70 : Colors.amber.shade600,
                ),
              ),
              const SizedBox(height: 40),

              // Карточка с информацией
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок карточки
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'О приложении',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Информационные пункты
                    _buildFeatureItem(
                      icon: Icons.schedule_rounded,
                      title: 'Индивидуальное расписание',
                      description: 'Создавайте свое расписание звонков для школы или колледжа',
                      color: Colors.green,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    _buildFeatureItem(
                      icon: Icons.notifications_active_rounded,
                      title: 'Умные уведомления',
                      description: 'Получайте напоминания о начале и конце занятий',
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    _buildFeatureItem(
                      icon: Icons.edit_calendar_rounded,
                      title: 'Простое управление',
                      description: 'Легко добавляйте и редактируйте пары',
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    _buildFeatureItem(
                      icon: Icons.cloud_sync_rounded,
                      title: 'Облачная синхронизация',
                      description: 'Доступ к расписанию с любого устройства',
                      color: Colors.purple,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    _buildFeatureItem(
                      icon: Icons.history_rounded,
                      title: 'История изменений',
                      description: 'Отслеживайте все изменения в расписании',
                      color: Colors.red,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Дополнительная информация
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Для кого это приложение?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Для школьников и студентов\n'
                          '• Для учителей и преподавателей\n'
                          '• Для администрации учебных заведений\n'
                          '• Для всех, кто работает с расписанием',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Кнопка начать использовать
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await _completeWelcome();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/auth');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Начать использовать',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward_rounded, size: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Кнопка смены темы (дополнительная)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _toggleTheme,
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.amber,
                  ),
                  label: Text(
                    isDark ? 'Переключить на светлую тему' : 'Переключить на темную тему',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.amber.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Примечание
              Text(
                'Нажимая "Начать использовать", вы принимаете условия использования',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}