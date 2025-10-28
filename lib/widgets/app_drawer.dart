// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/schedule/home_page.dart';
import '../screens/schedule/bell_schedule_page.dart';
import '../screens/settings/settings_page.dart';
import '../screens/auth/auth_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.amberAccent : Colors.amber.shade700;
    final dividerColor = isDark ? Colors.white24 : Colors.black26;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.amber.shade700, Colors.orange.shade600]
                    : [Colors.amber.shade300, Colors.orange.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_active,
                    size: 50, color: isDark ? Colors.black : Colors.white),
                const SizedBox(height: 10),
                Text(
                  'ZvonOK',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
                Text(
                  'расписание звонков',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? Colors.black.withOpacity(0.7)
                        : Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // ---- Элементы меню ----
          _buildMenuItem(
            context,
            icon: Icons.dashboard,
            label: 'Главная',
            iconColor: iconColor,
            textColor: textColor,
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final place = prefs.getString('selected_place') ?? 'school';
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomePage(place: place)),
                );
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.schedule,
            label: 'Моё расписание',
            iconColor: iconColor,
            textColor: textColor,
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final place = prefs.getString('selected_place') ?? 'school';
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => BellSchedulePage(place: place)),
                );
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings,
            label: 'Настройки',
            iconColor: iconColor,
            textColor: textColor,
            onTap: () {
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              }
            },
          ),

          Divider(color: dividerColor),

          _buildMenuItem(
            context,
            icon: Icons.exit_to_app,
            label: 'Выйти',
            iconColor: Colors.redAccent,
            textColor: textColor,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('selected_place');
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color iconColor,
        required Color textColor,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 16),
      ),
      onTap: onTap,
      hoverColor: Colors.amber.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}