// lib/screens/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/theme_controller.dart';
import '../../widgets/app_drawer.dart';
import '../setup/place_selection_page.dart';
import '../profile/profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool remindersEnabled = true;
  int reminderMinutes = 5;
  bool use24HourFormat = true; // Новая настройка

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      remindersEnabled = prefs.getBool('reminders_enabled') ?? true;
      reminderMinutes = prefs.getInt('reminder_minutes') ?? 5;
      use24HourFormat = prefs.getBool('use_24hour_format') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', remindersEnabled);
    await prefs.setInt('reminder_minutes', reminderMinutes);
    await prefs.setBool('use_24hour_format', use24HourFormat);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Настройки сохранены'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _changePlace(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_place');
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PlaceSelectionPage()));
    }
  }

  Widget _buildGlassCard({required Widget child, double opacity = 0.05, double blur = 15}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: const EdgeInsets.all(16),
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
      drawer: const AppDrawer(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Настройки', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [_buildUserAvatar(context), const SizedBox(width: 16)],
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
          Positioned(
            top: 50, right: -30,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 80, spreadRadius: 20)],
              ),
            ),
          ),
          
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                _buildGlassCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Тёмная тема', style: TextStyle(fontWeight: FontWeight.w600)),
                        secondary: const Icon(Icons.dark_mode_outlined, color: Colors.amber),
                        value: themeController.value == ThemeMode.dark,
                        onChanged: (v) async {
                          await themeController.toggleTheme();
                          setState(() {});
                        },
                        activeColor: Colors.amber,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(color: Colors.white10),
                      SwitchListTile(
                        title: const Text('Формат 24ч', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Использовать 24-часовой формат', style: TextStyle(fontSize: 12, color: Colors.white54)),
                        secondary: const Icon(Icons.access_time_rounded, color: Colors.amber),
                        value: use24HourFormat,
                        onChanged: (v) => setState(() => use24HourFormat = v),
                        activeColor: Colors.amber,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(color: Colors.white10),
                      ListTile(
                        leading: const Icon(Icons.swap_horiz_rounded, color: Colors.amber),
                        title: const Text('Сменить место', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Школа / Колледж', style: TextStyle(fontSize: 12, color: Colors.white54)),
                        onTap: () => _changePlace(context),
                        contentPadding: EdgeInsets.zero,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined, color: Colors.amber, size: 20),
                          const SizedBox(width: 12),
                          const Text('Уведомления', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          Switch(
                            value: remindersEnabled,
                            onChanged: (v) => setState(() => remindersEnabled = v),
                            activeColor: Colors.amber,
                          ),
                        ],
                      ),
                      if (remindersEnabled) ...[
                        const SizedBox(height: 16),
                        Text('Напомнить за $reminderMinutes минут', style: const TextStyle(color: Colors.white70)),
                        Slider(
                          value: reminderMinutes.toDouble(),
                          min: 1, max: 30,
                          divisions: 29,
                          label: '$reminderMinutes',
                          onChanged: (v) => setState(() => reminderMinutes = v.round()),
                          activeColor: Colors.amber,
                          inactiveColor: Colors.white10,
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 8,
                  ),
                  child: const Text('Сохранить изменения', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white10,
        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
        child: user?.photoURL == null ? const Icon(Icons.person, size: 20, color: Colors.white70) : null,
      ),
    );
  }
}
