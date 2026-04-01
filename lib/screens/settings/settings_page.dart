// lib/screens/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _use24Hour = true;
  bool _notifications = true;

  final List<Color> _availableColors = [
    Colors.amber,
    Colors.blue,
    Colors.green,
    Colors.pinkAccent,
    Colors.deepPurpleAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _use24Hour = prefs.getBool('use_24hour_format') ?? true;
      _notifications = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggle24Hour(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_24hour_format', val);
    setState(() => _use24Hour = val);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  // СЕКЦИЯ: ТЕМА
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

                  // СЕКЦИЯ: ПРИЛОЖЕНИЕ
                  const Text('ПРИЛОЖЕНИЕ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white54)),
                  const SizedBox(height: 12),
                  _buildGlassCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.access_time_rounded, color: Colors.white70),
                          title: const Text('24-часовой формат'),
                          trailing: Switch(value: _use24Hour, onChanged: _toggle24Hour),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(color: Colors.white10),
                        ListTile(
                          leading: const Icon(Icons.notifications_active_rounded, color: Colors.white70),
                          title: const Text('Уведомления'),
                          trailing: Switch(value: _notifications, onChanged: (v) => setState(() => _notifications = v)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'ZvonOK v1.1.0\nЛицензия студента',
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
