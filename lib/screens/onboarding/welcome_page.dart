// lib/screens/onboarding/welcome_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/theme_controller.dart';
import '../../services/auth_service.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutBack,
    ));

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _completeWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_completed', true);
  }

  Future<void> _startAnonymously() async {
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Гостевой вход', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('В этом режиме вам будут доступны только базовые функции:', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 12),
            Text('• Личное расписание (ручной ввод)', style: TextStyle(color: Colors.white54, fontSize: 13)),
            Text('• Локальные уведомления', style: TextStyle(color: Colors.white54, fontSize: 13)),
            SizedBox(height: 12),
            Text('Функции синхронизации с вузом и группами будут отключены до регистрации.', style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Понятно', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    setState(() => _isLoading = true);
    try {
      await _completeWelcome();
      await _authService.signInAnonymously();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.canPop(context);
    // ПРОВЕРКА: Авторизован ли пользователь (включая анонимов)
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      body: Stack(
        children: [
          ValueListenableBuilder<ThemeState>(
            valueListenable: themeController,
            builder: (context, state, _) {
              final isDark = state.mode == ThemeMode.dark;
              final accentColor = state.accentColor;
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
                child: Stack(
                  children: [
                    Positioned(
                      bottom: -150,
                      right: -50,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withOpacity(0.03),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
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
                      
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, 10 * _floatController.value),
                            child: child,
                          );
                        },
                        child: Hero(
                          tag: 'logo',
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber.withOpacity(0.1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                )
                              ],
                              border: Border.all(color: Colors.amber.withOpacity(0.2)),
                            ),
                            child: const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 80),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('ZvonOK', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 4)),
                      const Text('Твой умный график звонков', style: TextStyle(fontSize: 16, color: Colors.white54, fontWeight: FontWeight.w300)),
                      
                      const SizedBox(height: 40),

                      _buildGlassCard(context, child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Возможности', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('PRO', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildFeatureItem(Icons.groups_rounded, 'Групповой доступ', 'Синхронизация с одногруппниками и получение актуального расписания в реальном времени.', Colors.amber),
                          _buildFeatureItem(Icons.alarm_on_rounded, 'Умные уведомления', 'Гибкая настройка напоминаний. Приложение заранее предупредит о начале и конце пары.', Colors.blueAccent),
                          _buildFeatureItem(Icons.auto_awesome_rounded, 'Персонализация', 'Выбирай из множества тем и настраивай акцентные цвета под свой стиль.', Colors.purpleAccent),
                          _buildFeatureItem(Icons.offline_pin_rounded, 'Работа оффлайн', 'Твое расписание всегда доступно без интернета благодаря локальному кэшированию.', Colors.greenAccent),
                          _buildFeatureItem(Icons.history_rounded, 'История изменений', 'Отслеживай все правки в своем графике, чтобы ничего не упустить.', Colors.orangeAccent),
                          _buildFeatureItem(Icons.notes_rounded, 'Быстрые заметки', 'Добавляй важную информацию к каждой паре прямо на главном экране.', Colors.tealAccent),
                        ],
                      )),

                      const SizedBox(height: 24),

                      _buildGlassCard(context, child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Как это работает?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildStepItem('1', 'Выбери режим работы: "Я сам" или "Присоединиться к учебному заведению".'),
                          _buildStepItem('2', 'Настрой свои пары или дождись подтверждения от куратора группы.'),
                          _buildStepItem('3', 'Получай уведомления и всегда будь вовремя на занятиях!'),
                        ],
                      )),

                      const SizedBox(height: 24),

                      _buildGlassCard(context, opacity: 0.02, child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.security_rounded, size: 16, color: Colors.white38),
                              SizedBox(width: 8),
                              Text('Конфиденциальность', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Твои данные зашифрованы и хранятся в безопасности на серверах Google Firebase. Мы ценим твою приватность.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.white38, height: 1.5),
                          ),
                        ],
                      )),

                      const SizedBox(height: 48),
                      
                      if (_isLoading)
                        const CircularProgressIndicator(color: Colors.amber)
                      else if (!isLoggedIn)
                        Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _startAnonymously,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text('Гостевой вход', 
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: () async {
                                await _completeWelcome();
                                if (context.mounted) Navigator.pushReplacementNamed(context, '/auth');
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.amber,
                              ),
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 15),
                                  children: [
                                    TextSpan(text: 'Уже есть аккаунт? ', style: TextStyle(color: Colors.white54)),
                                    TextSpan(text: 'Войти', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        // ЕСЛИ ПОЛЬЗОВАТЕЛЬ УЖЕ В СИСТЕМЕ
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Вернуться назад', 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child, double opacity = 0.05}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 13, color: Colors.white54, height: 1.4, fontWeight: FontWeight.w300)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
