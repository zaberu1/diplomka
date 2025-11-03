// lib/screens/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/app_drawer.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String userName = 'Пользователь';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (user != null) {
      setState(() {
        userEmail = user!.email ?? '';
        userName = user!.displayName ?? user!.email!.split('@')[0];
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_place');

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
    }
  }

  Widget _buildProfileButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : Colors.amber),
        title: Text(text, style: TextStyle(color: isLogout ? Colors.red : null)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Мой профиль'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Аватарка
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.amber.withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 20),

            // Информация о пользователе
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.person, color: Colors.amber),
                      title: Text('Имя'),
                      subtitle: Text(userName),
                    ),
                    ListTile(
                      leading: Icon(Icons.email, color: Colors.amber),
                      title: Text('Email'),
                      subtitle: Text(userEmail),
                    ),
                    ListTile(
                      leading: Icon(Icons.school, color: Colors.amber),
                      title: Text('Учебное заведение'),
                      subtitle: FutureBuilder<SharedPreferences>(
                        future: SharedPreferences.getInstance(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final place = snapshot.data!.getString('selected_place') ?? 'school';
                            return Text(place == 'school' ? 'Школа' : 'Колледж');
                          }
                          return Text('Загрузка...');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Действия
            Expanded(
              child: ListView(
                children: [
                  _buildProfileButton(
                    icon: Icons.edit,
                    text: 'Редактировать профиль',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Редактирование профиля'),
                          content: Text('Функция в разработке'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _buildProfileButton(
                    icon: Icons.settings,
                    text: 'Настройки',
                    onTap: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  _buildProfileButton(
                    icon: Icons.history,
                    text: 'История изменений',
                    onTap: () {
                      Navigator.pushNamed(context, '/history');
                    },
                  ),
                  _buildProfileButton(
                    icon: Icons.analytics,
                    text: 'Статистика',
                    onTap: () {
                      Navigator.pushNamed(context, '/statistics');
                    },
                  ),
                  _buildProfileButton(
                    icon: Icons.exit_to_app,
                    text: 'Выйти',
                    onTap: _logout,
                    isLogout: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}