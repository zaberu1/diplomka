// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/schedule/home_page.dart';
import '../screens/schedule/bell_schedule_page.dart';
import '../screens/settings/settings_page.dart';
import '../screens/settings/history_page.dart';
import '../screens/auth/auth_page.dart';
import '../screens/profile/profile_page.dart';
import '../screens/setup/join_institution_page.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/teacher/teacher_dashboard.dart';
import '../screens/onboarding/welcome_page.dart';
import '../screens/setup/place_selection_page.dart';
import '../services/shared_prefs_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showInstitutionInfo(BuildContext context, Map<String, dynamic> userData) async {
    final groupId = userData['groupId'];
    if (groupId == null) return;

    final groupDoc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
    final groupData = groupDoc.data();
    if (groupData == null) return;

    final teacherId = groupData['teacherId'];
    final teacherDoc = await FirebaseFirestore.instance.collection('users').doc(teacherId).get();
    final teacherData = teacherDoc.data();

    if (!context.mounted) return;

    final primaryColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Icon(Icons.school_rounded, color: primaryColor),
            const SizedBox(width: 12),
            const Text('Моё обучение', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Заведение:', userData['institutionName'] ?? 'Не указано'),
            _buildInfoRow('Группа:', groupData['name'] ?? 'Не указана'),
            _buildInfoRow('Куратор:', teacherData?['displayName'] ?? 'Преподаватель'),
            const Divider(color: Colors.white10, height: 24),
            const Text('Расписание синхронизируется автоматически при изменениях со стороны преподавателя.',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Закрыть', style: TextStyle(color: primaryColor))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$label ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
            TextSpan(text: value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Вернуться в ручной режим?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Вы отключитесь от группы. Вам потребуется заново выбрать место обучения и настроить расписание.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              await databaseService.updateUserData({
                'appMode': 'manual',
                'institutionId': null,
                'institutionName': null,
                'groupId': null,
                'setupCompleted': false,
                'pendingRequest': false,
              });
              
              if (context.mounted) { 
                Navigator.pop(context); // Закрыть диалог
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (_) => const PlaceSelectionPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.8)),
            child: const Text('Отключиться'),
          ),
        ],
      ),
    );
  }

  void _showFinishRegistrationDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isLoading = false;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1C2C).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: Colors.amber, size: 40),
                      ),
                      const SizedBox(height: 20),
                      const Text('Создать аккаунт', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Text(
                        'Привяжите почту, чтобы синхронизировать данные и получить доступ к функциям заведения.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      _buildDialogField(
                        controller: emailCtrl,
                        label: 'Email',
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogField(
                        controller: passCtrl,
                        label: 'Пароль',
                        icon: Icons.lock_outline_rounded,
                        obscureText: obscure,
                      ),
                      const SizedBox(height: 16),
                      _buildDialogField(
                        controller: confirmPassCtrl,
                        label: 'Подтвердите пароль',
                        icon: Icons.lock_reset_rounded,
                        obscureText: obscure,
                        suffix: IconButton(
                          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white24, size: 20),
                          onPressed: () => setDialogState(() => obscure = !obscure),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('ПОЗЖЕ', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : () async {
                                final email = emailCtrl.text.trim();
                                final pass = passCtrl.text.trim();
                                final confirm = confirmPassCtrl.text.trim();

                                if (email.isEmpty || pass.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заполните все поля')));
                                  return;
                                }
                                if (pass != confirm) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пароли не совпадают')));
                                  return;
                                }

                                setDialogState(() => isLoading = true);
                                try {
                                  await authService.linkAnonymousWithEmail(email, pass);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Успешно! Теперь у вас полноценный аккаунт'),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(() => isLoading = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.redAccent),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)))
                                : const Text('СОХРАНИТЬ', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.amber, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

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
              stream: databaseService.getUserStream(),
              builder: (context, snapshot) {
                final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final role = userData['role'] ?? 'student';
                final appMode = userData['appMode'] ?? 'manual';
                final bool isPending = userData['pendingRequest'] == true;
                final bool isOfficiallyInGroup = appMode == 'join' && !isPending;
                final bool isAnonymous = userData['isAnonymous'] == true;

                return Column(
                  children: [
                    _buildDrawerHeader(context, role, primaryColor, userData, isAnonymous),
                    const SizedBox(height: 10),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: _buildItemsByRole(context, role, isOfficiallyInGroup, isPending, userData, isAnonymous),
                        ),
                      ),
                    ),

                    if (role == 'student' && !isAnonymous)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            const Divider(color: Colors.white10),
                            if (isPending)
                              _buildDrawerItem(
                                context, 
                                icon: Icons.timer_outlined, 
                                label: 'Заявка на рассмотрении', 
                                color: primaryColor, 
                                onTap: () {
                                  Navigator.pop(context);
                                  final place = SharedPrefsService.getPlace();
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(place: place)));
                                }
                              )
                            else if (isOfficiallyInGroup) ...[
                              _buildDrawerItem(context, icon: Icons.info_outline_rounded, label: 'Где я учусь?', color: primaryColor, onTap: () => _showInstitutionInfo(context, userData)),
                              _buildDrawerItem(context, icon: Icons.sync_disabled_rounded, label: 'Вернуться к "Я сам"', color: Colors.white38, onTap: () => _showLeaveDialog(context)),
                            ] else ...[
                              _buildDrawerItem(context, icon: Icons.add_business_rounded, label: 'Подключить заведение', color: primaryColor, onTap: () {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinInstitutionPage()));
                              }),
                            ],
                          ],
                        ),
                      ),
                      
                    if (isAnonymous)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber.withOpacity(0.2), Colors.orange.withOpacity(0.1)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: _buildDrawerItem(
                            context, 
                            icon: Icons.auto_awesome_rounded, 
                            label: 'Создать аккаунт', 
                            color: Colors.amber, 
                            onTap: () {
                              Navigator.pop(context);
                              _showFinishRegistrationDialog(context);
                            }
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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

  List<Widget> _buildItemsByRole(BuildContext context, String role, bool isJoined, bool isPending, Map<String, dynamic> userData, bool isAnonymous) {
    switch (role) {
      case 'admin': return _buildAdminItems(context);
      case 'teacher': return _buildTeacherItems(context);
      default: return _buildUserItems(context, isJoined, isPending, isAnonymous);
    }
  }

  List<Widget> _buildAdminItems(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return [
      _buildDrawerItem(context, icon: Icons.admin_panel_settings_rounded, label: 'Панель управления', color: primaryColor, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()))),
      _buildDrawerItem(context, icon: Icons.person_outline_rounded, label: 'Мой профиль', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
      _buildDrawerItem(context, icon: Icons.people_alt_rounded, label: 'Пользователи', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()))),
      _buildDrawerItem(context, icon: Icons.account_balance_rounded, label: 'Учреждения', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()))),
      _buildDrawerItem(context, icon: Icons.settings_rounded, label: 'Настройки', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
      _buildDrawerItem(context, icon: Icons.info_outline, label: 'О приложении', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WelcomePage()))),
    ];
  }

  List<Widget> _buildTeacherItems(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return [
      _buildDrawerItem(context, icon: Icons.dashboard_rounded, label: 'Панель учителя', color: primaryColor, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherDashboard()))),
      _buildDrawerItem(context, icon: Icons.person_outline_rounded, label: 'Мой профиль', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
      _buildDrawerItem(context, icon: Icons.settings_rounded, label: 'Настройки', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
      _buildDrawerItem(context, icon: Icons.info_outline, label: 'О приложении', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WelcomePage()))),
    ];
  }

  List<Widget> _buildUserItems(BuildContext context, bool isJoined, bool isPending, bool isAnonymous) {
    return [
      _buildDrawerItem(context, icon: Icons.home_rounded, label: 'Главная', onTap: () {
        final place = SharedPrefsService.getPlace();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(place: place)));
      }),
      if (!isAnonymous)
        _buildDrawerItem(context, icon: Icons.person_outline_rounded, label: 'Мой профиль', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
      if (!isPending) ...[
        _buildDrawerItem(context, icon: Icons.calendar_today_rounded, label: 'Расписание', onTap: () {
          final place = SharedPrefsService.getPlace();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BellSchedulePage(place: place)));
        }),
        if (!isJoined && !isAnonymous) ...[
          _buildDrawerItem(context, icon: Icons.history_edu_rounded, label: 'История', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()))),
        ],
      ],
      _buildDrawerItem(context, icon: Icons.settings_rounded, label: 'Настройки', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
      _buildDrawerItem(context, icon: Icons.info_outline, label: 'О приложении', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WelcomePage()))),
    ];
  }

  Widget _buildExitButton(BuildContext context) {
    return ListTile(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        await SharedPrefsService.clearAll(); // Очистка при выходе
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthPage()), (route) => false);
        }
      },
      leading: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
      title: const Text('Выйти', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, String role, Color primaryColor, Map<String, dynamic> userData, bool isAnonymous) {
    final user = databaseService.user;
    final String name = isAnonymous ? 'Гость' : (userData['displayName'] ?? user?.displayName ?? (role == 'admin' ? 'Админ' : 'Студент'));
    
    return GestureDetector(
      onTap: isAnonymous ? null : () { 
        Navigator.pop(context); 
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); 
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white10,
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null ? Icon(isAnonymous ? Icons.person_outline : Icons.person, size: 30, color: primaryColor) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(isAnonymous ? 'Временный аккаунт' : (user?.email ?? ''), style: const TextStyle(fontSize: 11, color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: color ?? primaryColor, size: 22),
      title: Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w500)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
