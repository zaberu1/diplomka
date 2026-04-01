// lib/screens/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/app_drawer.dart';
import '../settings/settings_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String userName = 'Пользователь';
  String userEmail = '';
  String? role;
  String? phone;
  String? bio;
  String? institutionName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          userEmail = user!.email ?? '';
          userName = data['displayName'] ?? user!.displayName ?? 'Пользователь';
          role = data['role'] ?? 'student';
          phone = data['phone'];
          bio = data['bio'];
          institutionName = data['institutionName'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки профиля: $e');
      setState(() => isLoading = false);
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
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.amber)));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Мой профиль', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // АВАТАР И ИМЯ
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white12,
                          backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                          child: user?.photoURL == null ? const Icon(Icons.person, size: 60, color: Colors.amber) : null,
                        ),
                        const SizedBox(height: 16),
                        Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(userEmail, style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            role == 'teacher' ? 'ПРЕПОДАВАТЕЛЬ' : 'СТУДЕНТ',
                            style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // ИНФОРМАЦИОННАЯ КАРТОЧКА
                  _buildGlassCard(
                    child: Column(
                      children: [
                        _buildInfoTile(Icons.email_outlined, 'Электронная почта', userEmail),
                        if (phone != null && phone!.isNotEmpty) ...[
                          const Divider(color: Colors.white10),
                          _buildInfoTile(Icons.phone_android_rounded, 'Телефон', phone!),
                        ],
                        if (role == 'teacher') ...[
                          const Divider(color: Colors.white10),
                          _buildInfoTile(Icons.work_outline_rounded, 'Должность / Кафедра', bio ?? 'Не указано'),
                          const Divider(color: Colors.white10),
                          _buildInfoTile(Icons.account_balance_rounded, 'Место работы', institutionName ?? 'Не привязано'),
                        ] else ...[
                          const Divider(color: Colors.white10),
                          _buildInfoTile(Icons.school_outlined, 'Учебное заведение', institutionName ?? 'Самостоятельное обучение'),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // КНОПКИ
                  _buildProfileButton(
                    icon: Icons.edit_rounded,
                    text: 'Редактировать данные',
                    onTap: () async {
                      final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()));
                      if (updated == true) _loadAllData();
                    },
                  ),
                  _buildProfileButton(
                    icon: Icons.logout_rounded,
                    text: 'Выйти из системы',
                    onTap: _logout,
                    isLogout: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildProfileButton({required IconData icon, required String text, required VoidCallback onTap, bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildGlassCard(
        opacity: 0.03,
        child: ListTile(
          leading: Icon(icon, color: isLogout ? Colors.redAccent : Colors.amber, size: 22),
          title: Text(text, style: TextStyle(color: isLogout ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24),
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
