// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/schedule/home_page.dart';
import '../screens/schedule/bell_schedule_page.dart';
import '../screens/settings/settings_page.dart';
import '../screens/settings/history_page.dart';
import '../screens/settings/statistics_page.dart';
import '../screens/auth/auth_page.dart';
import '../screens/profile/profile_page.dart';
import '../screens/setup/coming_soon_page.dart';
import '../screens/admin/admin_dashboard.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showJoinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Сменить режим?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Вы хотите присоединиться к готовому расписанию учебного заведения? Текущие ручные настройки сохранятся.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Закрыть диалог
              Navigator.pop(context); // Закрыть Drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ComingSoonPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Присоединиться'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.75,
      child: Stack(
        children: [
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F2027).withOpacity(0.8) : Colors.white.withOpacity(0.8),
                  border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
              ),
            ),
          ),
          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final bool isAdmin = (userData?['role'] == 'admin') || (user?.email == 'admin@zvonok.ru');

                return Column(
                  children: [
                    _buildDrawerHeader(context, user, isAdmin, isDark),
                    const SizedBox(height: 20),
                    const Divider(indent: 20, endIndent: 20, color: Colors.white12),
                    
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: isAdmin 
                            ? _buildAdminItems(context) // МЕНЮ ДЛЯ АДМИНА
                            : _buildUserItems(context), // МЕНЮ ДЛЯ СТУДЕНТА
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildExitButton(context),
                    ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  // --- Пункты для Админа ---
  List<Widget> _buildAdminItems(BuildContext context) {
    return [
      _buildDrawerItem(
        context, icon: Icons.admin_panel_settings_rounded, label: 'Панель управления', color: Colors.amber,
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
      ),
      _buildDrawerItem(context, icon: Icons.people_alt_rounded, label: 'Пользователи', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()))),
      _buildDrawerItem(context, icon: Icons.account_balance_rounded, label: 'Учреждения', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()))),
      _buildDrawerItem(context, icon: Icons.settings_suggest_rounded, label: 'Общие настройки', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
    ];
  }

  // --- Пункты для Студента ---
  List<Widget> _buildUserItems(BuildContext context) {
    return [
      _buildDrawerItem(
        context, icon: Icons.dashboard_rounded, label: 'Главная',
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          final place = prefs.getString('selected_place') ?? 'school';
          if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(place: place)));
        },
      ),
      _buildDrawerItem(
        context, icon: Icons.calendar_month_rounded, label: 'Расписание',
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          final place = prefs.getString('selected_place') ?? 'school';
          if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BellSchedulePage(place: place)));
        },
      ),
      _buildDrawerItem(context, icon: Icons.analytics_rounded, label: 'Статистика', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsPage()))),
      
      // Кнопка присоединения для Студента
      _buildDrawerItem(
        context, 
        icon: Icons.account_balance_rounded, 
        label: 'Подключить заведение', 
        onTap: () => _showJoinDialog(context),
      ),

      _buildDrawerItem(context, icon: Icons.history_rounded, label: 'История', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()))),
      _buildDrawerItem(context, icon: Icons.settings_suggest_rounded, label: 'Настройки', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
    ];
  }

  Widget _buildExitButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.1), blurRadius: 10)]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), border: Border.all(color: Colors.redAccent.withOpacity(0.2)), borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('selected_place');
                if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthPage()), (route) => false);
              },
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Выйти', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, User? user, bool isAdmin, bool isDark) {
    return GestureDetector(
      onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); },
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isAdmin ? Colors.amber : Colors.blueAccent, width: 2)),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white10,
                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                child: user?.photoURL == null ? Icon(Icons.person, size: 40, color: isAdmin ? Colors.amber : Colors.blueAccent) : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.displayName ?? (isAdmin ? 'Администратор' : 'Студент'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(user?.email ?? '', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: color ?? (isDark ? Colors.amberAccent : Colors.amber.shade700), size: 24),
      title: Text(label, style: TextStyle(color: color ?? (isDark ? Colors.white : Colors.black87), fontSize: 16, fontWeight: FontWeight.w600)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
    );
  }
}
