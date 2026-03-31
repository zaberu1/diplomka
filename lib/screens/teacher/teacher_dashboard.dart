// lib/screens/teacher/teacher_dashboard.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_page.dart';
import '../schedule/edit_lesson_page.dart';
import '../../models/lesson_model.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  String? selectedInstitution;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkInstitution();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkInstitution() async {
    if (user == null) return;
    final doc = await _db.collection('users').doc(user!.uid).get();
    if (mounted) {
      setState(() {
        selectedInstitution = doc.data()?['institutionId'];
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthPage()), (route) => false);
    }
  }

  Widget _buildGlassCard({required Widget child, double opacity = 0.05}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
    if (selectedInstitution == null) return _buildInstitutionSelection();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Панель Учителя', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: _logout)],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.groups_rounded), text: 'Мои группы'),
            Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Расписание'),
          ],
        ),
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGroupsTab(),
                _buildSchedulesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            onPressed: _showAddGroupDialog,
            icon: const Icon(Icons.group_add_rounded, color: Colors.black),
            label: const Text('Создать учебную группу', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('groups').where('teacherId', isEqualTo: user?.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final groups = snapshot.data!.docs;
              if (groups.isEmpty) return const Center(child: Text('У вас еще нет групп', style: TextStyle(color: Colors.white54)));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index].data() as Map<String, dynamic>;
                  final groupId = groups[index].id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGlassCard(
                      child: ListTile(
                        leading: const Icon(Icons.people_outline, color: Colors.amber),
                        title: Text(group['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('ID: $groupId', style: const TextStyle(fontSize: 10, color: Colors.white24)),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _db.collection('groups').doc(groupId).delete()),
                        onTap: () => _showStudentsList(groupId, group['name']),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('groups').where('teacherId', isEqualTo: user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final groups = snapshot.data!.docs;
        if (groups.isEmpty) return const Center(child: Text('Сначала создайте группу', style: TextStyle(color: Colors.white54)));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index].data() as Map<String, dynamic>;
            final groupId = groups[index].id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildGlassCard(
                child: ListTile(
                  leading: const Icon(Icons.edit_calendar_rounded, color: Colors.amber),
                  title: Text('Расписание для ${group['name']}'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white24),
                  onTap: () => _manageGroupSchedule(groupId, group['name']),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInstitutionSelection() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.school_rounded, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            const Text('Где вы преподаете?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('Выберите ваше учебное заведение из списка.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 40),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('institutions').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  final institutions = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: institutions.length,
                    itemBuilder: (context, index) {
                      final inst = institutions[index].data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildGlassCard(
                          child: ListTile(
                            title: Text(inst['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            onTap: () {
                              _db.collection('users').doc(user!.uid).update({'institutionId': institutions[index].id});
                              setState(() => selectedInstitution = institutions[index].id);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGroupDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C2C),
        title: const Text('Новая группа'),
        content: TextField(controller: ctrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Название группы (например, П-41)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                _db.collection('groups').add({
                  'name': ctrl.text,
                  'teacherId': user!.uid,
                  'institutionId': selectedInstitution,
                  'schedule': [],
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _showStudentsList(String groupId, String groupName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1C2C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Студенты группы $groupName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('users').where('groupId', isEqualTo: groupId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final students = snapshot.data!.docs;
                if (students.isEmpty) return const Center(child: Text('В группе пока нет студентов'));
                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.person, color: Colors.amber),
                      title: Text(s['email'] ?? 'No Email'),
                      trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), onPressed: () => _db.collection('users').doc(students[index].id).update({'groupId': null})),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _manageGroupSchedule(String groupId, String groupName) {
    // Редактирование расписания группы
  }
}
