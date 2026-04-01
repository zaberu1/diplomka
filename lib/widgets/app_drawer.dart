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
import '../screens/setup/join_institution_page.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/teacher/teacher_dashboard.dart';
import '../screens/onboarding/welcome_page.dart';

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
        content: const Text('Вы отключитесь от группы. Ваши личные настройки расписания снова станут основными.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                  'appMode': 'manual',
                  'institutionId': null,
                  'institutionName': null,
                  'groupId': null,
                  'setupCompleted': false,
                  'pendingRequest': false,
                });
              }
              if (context.mounted) { Navigator.pop(context); Navigator.pop(context); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.8)),
            child: const Text('Отключиться'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Подключить заведение', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Вы сможете выбрать свою группу и получать готовое расписание автоматически.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinInstitutionPage())); },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
            child: const Text('Перейти'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
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
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final role = userData['role'] ?? 'student';
                final appMode = userData['appMode'] ?? 'manual';
                final bool isPending = userData['pendingRequest'] == true;
                final bool isOfficiallyInGroup = appMode == 'join' && !isPending;

                return Column(
                  children: [
                    _buildDrawerHeader(context, user, role, isDark, userData),
                    const SizedBox(height: 10),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: role == 'admin' 
                            ? _buildAdminItems(context)
                            : role == 'teacher'
                                ? _buildTeacherItems(context)
                                : _buildUserItems(context, isOfficiallyInGroup, isPending, userData),
                        ),
                      ),
                    ),

                    if (role == 'student')
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
                                  final prefs = SharedPreferences.getInstance();
                                  prefs.then((p) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(place: p.getString('selected_place') ?? 'school'))));
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

  List<Widget> _buildUserItems(BuildContext context, bool isJoined, bool isPending, Map<String, dynamic> userData) {
    return [
      _buildDrawerItem(context, icon: Icons.home_rounded, label: 'Главная', onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        final place = prefs.getString('selected_place') ?? 'school';
        if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(place: place)));
      }),
      _buildDrawerItem(context, icon: Icons.person_outline_rounded, label: 'Мой профиль', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
      if (!isPending) ...[
        _buildDrawerItem(context, icon: Icons.calendar_today_rounded, label: 'Расписание', onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          final place = prefs.getString('selected_place') ?? 'school';
          if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BellSchedulePage(place: place)));
        }),
        if (!isJoined) ...[
          _buildDrawerItem(context, icon: Icons.bar_chart_rounded, label: 'Статистика', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsPage()))),
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('selected_place');
        if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthPage()), (route) => false);
      },
      leading: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
      title: const Text('Выйти', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, User? user, String role, bool isDark, Map<String, dynamic> userData) {
    final String name = userData['displayName'] ?? user?.displayName ?? (role == 'admin' ? 'Админ' : 'Студент');
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); },
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white10,
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null ? Icon(Icons.person, size: 30, color: primaryColor) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(user?.email ?? '', style: const TextStyle(fontSize: 11, color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
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
