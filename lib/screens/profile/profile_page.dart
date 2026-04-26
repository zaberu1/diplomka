// lib/screens/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/app_drawer.dart';
import '../../services/shared_prefs_service.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'edit_profile_page.dart';
import '../../../widgets/loading_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = 'Пользователь';
  String userEmail = '';
  String? role;
  String? phone;
  String? bio;
  String? institutionName;
  bool isLoading = true;
  bool isAnonymous = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final user = databaseService.user;
    if (user == null) return;
    
    try {
      final doc = await databaseService.getUserData();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            isAnonymous = user.isAnonymous;
            userEmail = user.email ?? (isAnonymous ? 'Гостевой аккаунт' : '');
            userName = data['displayName'] ?? user.displayName ?? 'Пользователь';
            role = data['role'] ?? 'student';
            phone = data['phone'];
            bio = data['bio'];
            institutionName = data['institutionName'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки профиля: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _linkAccount() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заполните все поля')));
      return;
    }

    setState(() => isLoading = true);
    try {
      await authService.linkAnonymousWithEmail(email, pass);
      await _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Аккаунт успешно привязан!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await SharedPrefsService.clearAll();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
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
    if (isLoading) return const LoadingScreen(message: 'Загрузка профиля...');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final user = databaseService.user;

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
                begin: Alignment.topLeft, 
                end: Alignment.bottomRight, 
                colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)]
              )
            )
          ),
          
          Positioned(
            top: 100, right: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withOpacity(0.1))),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryColor, width: 2)),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white12,
                            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                            child: user?.photoURL == null ? Icon(Icons.person, size: 60, color: primaryColor) : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(userEmail, style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            role == 'teacher' ? 'ПРЕПОДАВАТЕЛЬ' : 'СТУДЕНТ',
                            style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  if (isAnonymous) ...[
                    _buildGlassCard(
                      opacity: 0.1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                              SizedBox(width: 8),
                              Text('Временный аккаунт', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Привяжите почту, чтобы не потерять данные при смене устройства или переустановке приложения.', 
                            style: TextStyle(fontSize: 12, color: Colors.white70)),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email', hintText: 'example@mail.com'),
                          ),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Придумайте пароль'),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _linkAccount,
                              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
                              child: const Text('Привязать почту', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  _buildGlassCard(
                    child: Column(
                      children: [
                        _buildInfoTile(Icons.email_outlined, 'Электронная почта', userEmail, primaryColor, isDark),
                        if (phone != null && phone!.isNotEmpty) ...[
                          const Divider(color: Colors.white10),
                          _buildInfoTile(Icons.phone_android_rounded, 'Телефон', phone!, primaryColor, isDark),
                        ],
                        if (role == 'teacher') ...[
                          const Divider(color: Colors.white10),
                          _buildInfoTile(Icons.work_outline_rounded, 'Должность / Кафедра', bio ?? 'Не указано', primaryColor, isDark),
                          const Divider(color: Colors.white10),
                          _buildInfoTile(Icons.account_balance_rounded, 'Место работы', institutionName ?? 'Не привязано', primaryColor, isDark),
                        ] else ...[
                          const Divider(color: Colors.white10),
                          _buildInfoTile(Icons.school_outlined, 'Учебное заведение', institutionName ?? 'Самостоятельное обучение', primaryColor, isDark),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildProfileButton(
                    icon: Icons.edit_rounded,
                    text: 'Редактировать данные',
                    color: primaryColor,
                    onTap: () async {
                      final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()));
                      if (updated == true) _loadAllData();
                    },
                  ),
                  _buildProfileButton(
                    icon: Icons.logout_rounded,
                    text: 'Выйти из системы',
                    color: Colors.redAccent,
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

  Widget _buildInfoTile(IconData icon, String title, String subtitle, Color color, bool isDark) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildProfileButton({required IconData icon, required String text, required Color color, required VoidCallback onTap, bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildGlassCard(
        opacity: 0.03,
        child: ListTile(
          leading: Icon(icon, color: color, size: 22),
          title: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          trailing: isLogout ? null : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24),
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
