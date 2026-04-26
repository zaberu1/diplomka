// lib/screens/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/theme_controller.dart';
import '../../services/shared_prefs_service.dart';
import '../../services/database_service.dart';
import 'notification_settings_page.dart';
import '../setup/app_mode_selection_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _use24Hour = true;
  String _userRole = 'student';
  bool _isLoading = true;

  final List<Color> _availableColors = const [
    Colors.amber,
    Colors.blue,
    Colors.green,
    Colors.pinkAccent,
    Colors.deepPurpleAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _userRole = doc.data()?['role'] ?? 'student';
          _use24Hour = SharedPrefsService.getUse24HourFormat();
          _isLoading = false;
        });
      }
    }
  }

  void _toggle24Hour(bool val) {
    SharedPrefsService.setBool('use_24hour_format', val);
    setState(() => _use24Hour = val);
  }

  void _resetAndReconfigure() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Сбросить настройки?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Вы перейдете к выбору режима работы (Ручной ввод или Подключение к заведению).', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              await databaseService.updateUserData({
                'appMode': null,
                'institutionId': null,
                'setupCompleted': false,
                'groupId': null,
              });
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (_) => const AppModeSelectionPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, double opacity = 0.05}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(opacity) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.amber)));
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bool isTeacher = _userRole == 'teacher';
    final bool isAdmin = _userRole == 'admin';
    final bool isStaff = isTeacher || isAdmin;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Настройки', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ОФОРМЛЕНИЕ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white54)),
                  const SizedBox(height: 12),
                  _buildGlassCard(
                    child: Column(
                      children: [
                        ValueListenableBuilder<ThemeState>(
                          valueListenable: themeController,
                          builder: (context, state, _) {
                            return ListTile(
                              leading: Icon(state.mode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: state.accentColor),
                              title: const Text('Темная тема', style: TextStyle(fontWeight: FontWeight.w600)),
                              trailing: Switch(
                                value: state.mode == ThemeMode.dark,
                                activeColor: state.accentColor,
                                onChanged: (v) => themeController.toggleTheme(),
                              ),
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Цветовая схема', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<ThemeState>(
                          valueListenable: themeController,
                          builder: (context, state, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: _availableColors.map((color) {
                                bool isSelected = state.accentColor.value == color.value;
                                return GestureDetector(
                                  onTap: () => themeController.setAccentColor(color),
                                  child: Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? Colors.white : Colors.transparent,
                                        width: 3,
                                      ),
                                      boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)] : [],
                                    ),
                                    child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text('ПРИЛОЖЕНИЕ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white54)),
                  const SizedBox(height: 12),
                  _buildGlassCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.access_time_rounded, color: isDark ? Colors.white70 : Colors.black87),
                          title: const Text('24-часовой формат'),
                          trailing: Switch(
                            value: _use24Hour, 
                            onChanged: _toggle24Hour,
                            activeColor: primaryColor,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        // СКРЫВАЕМ УВЕДОМЛЕНИЯ ДЛЯ УЧИТЕЛЯ И АДМИНА
                        if (!isStaff) ...[
                          const Divider(color: Colors.white10),
                          ListTile(
                            leading: Icon(Icons.notifications_active_rounded, color: isDark ? Colors.white70 : Colors.black87),
                            title: const Text('Настроить уведомления'),
                            trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.black26),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsPage())),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                        
                        // СКРЫВАЕМ СБРОС НАСТРОЕК ДЛЯ УЧИТЕЛЯ И АДМИНА
                        if (!isStaff) ...[
                          const Divider(color: Colors.white10),
                          ListTile(
                            leading: Icon(Icons.restart_alt_rounded, color: isDark ? Colors.white70 : Colors.black87),
                            title: const Text('Перенастроить приложение'),
                            subtitle: const Text('Смена режима работы и заведения', style: TextStyle(fontSize: 11, color: Colors.white38)),
                            trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.black26),
                            onTap: _resetAndReconfigure,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      isTeacher 
                        ? 'ZvonOK Professional Console\nЛицензия преподавателя' 
                        : (isAdmin ? 'ZvonOK System Control\nЛицензия администратора' : 'ZvonOK Standard\nЛицензия студента'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
