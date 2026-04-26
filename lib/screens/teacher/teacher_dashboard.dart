// lib/screens/teacher/teacher_dashboard.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/theme_controller.dart';
import '../auth/auth_page.dart';
import 'group_schedule_page.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/loading_screen.dart';

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
  String? institutionName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        institutionName = doc.data()?['institutionName'];
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

  void _approveRequest(String requestId, String studentId, String groupId, String instId, String instName) async {
    await _db.collection('users').doc(studentId).update({
      'groupId': groupId,
      'institutionId': instId,
      'institutionName': instName,
      'setupCompleted': true,
      'pendingRequest': false,
    });
    await _db.collection('requests').doc(requestId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Студент успешно зачислен в группу'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.green),
      );
    }
  }

  void _rejectRequest(String requestId, String studentId) async {
    await _db.collection('users').doc(studentId).update({
      'pendingRequest': false,
      'appMode': 'manual',
    });
    await _db.collection('requests').doc(requestId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заявка отклонена'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget _buildGlassCard({required Widget child, double opacity = 0.05, double blur = 15}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
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
    if (isLoading) return const LoadingScreen(message: 'Загрузка кабинета...');
    
    if (selectedInstitution == null) {
      return Scaffold(
        body: Stack(
          children: [
            _buildBackground(),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: _buildGlassCard(
                  opacity: 0.1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_person_rounded, size: 80, color: Colors.amber),
                      const SizedBox(height: 24),
                      const Text('Доступ ограничен', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 16),
                      const Text('Администратор еще не привязал вас к учебному заведению. Пожалуйста, свяжитесь с поддержкой.', 
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _logout, 
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, minimumSize: const Size(200, 50)),
                        child: const Text('ВЫХОД', style: TextStyle(fontWeight: FontWeight.bold))
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('TEACHER CONSOLE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
            if (institutionName != null) 
              Text(institutionName!.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.amber, letterSpacing: 1)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.amber),
            onPressed: () => themeController.toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Colors.amber,
          unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'ГРУППЫ'),
            Tab(text: 'ГРАФИК'),
            Tab(text: 'ЗАЯВКИ'),
          ],
        ),
      ),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGroupsTab(),
                _buildSchedulesTab(),
                _buildRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight, 
          colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)]
        )
      )
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('requests').where('teacherId', isEqualTo: user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        final reqs = snapshot.data!.docs;
        
        if (reqs.isEmpty) {
          return _buildEmptyState(Icons.person_add_disabled_rounded, 'Новых заявок пока нет');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: reqs.length,
          itemBuilder: (context, index) {
            final req = reqs[index].data() as Map<String, dynamic>;
            final id = reqs[index].id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildGlassCard(
                opacity: 0.1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.amber.withOpacity(0.1),
                          child: Text(req['studentName']?[0] ?? 'S', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(req['studentName'] ?? 'Студент', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(req['studentEmail'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(req['groupName'] ?? '-', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10, height: 1)),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _rejectRequest(id, req['studentId']),
                            icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                            label: const Text('ОТКЛОНИТЬ', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approveRequest(id, req['studentId'], req['groupId'], req['institutionId'], req['institutionName']),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.withOpacity(0.2), foregroundColor: Colors.greenAccent, elevation: 0),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('ПРИНЯТЬ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsTab() {
    return Column(
      children: [
        _buildTeacherStats(),
        Padding(
          padding: const EdgeInsets.all(20),
          child: _buildGlassCard(
            opacity: 0.1,
            child: InkWell(
              onTap: _showAddGroupDialog,
              borderRadius: BorderRadius.circular(16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: Colors.amber),
                  SizedBox(width: 12),
                  Text('СОЗДАТЬ УЧЕБНУЮ ГРУППУ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('groups').where('teacherId', isEqualTo: user?.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
              final groups = snapshot.data!.docs;
              
              if (groups.isEmpty) {
                return _buildEmptyState(Icons.group_off_rounded, 'Список групп пуст');
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index].data() as Map<String, dynamic>;
                  final groupId = groups[index].id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGlassCard(
                      opacity: 0.05,
                      child: ListTile(
                        onTap: () => _showStudentsList(groupId, group['name']),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.groups_rounded, color: Colors.amber),
                        ),
                        title: Text(group['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('ID: ${groupId.substring(0, 8)}...', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), 
                          onPressed: () => _confirmDeleteGroup(groupId, group['name'])
                        ),
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        final groups = snapshot.data!.docs;
        
        if (groups.isEmpty) {
          return _buildEmptyState(Icons.calendar_today_rounded, 'Сначала создайте учебную группу');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index].data() as Map<String, dynamic>;
            final groupId = groups[index].id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildGlassCard(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.edit_calendar_rounded, color: Colors.blueAccent),
                  ),
                  title: Text('График звонков: ${group['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Редактировать расписание пары', style: TextStyle(color: Colors.white24, fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white10),
                  onTap: () => _manageGroupSchedule(groupId, group['name']),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTeacherStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('groups').where('teacherId', isEqualTo: user?.uid).snapshots(),
      builder: (context, snapshot) {
        int groupsCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              _buildStatBox('ВАШИ ГРУППЫ', groupsCount.toString(), Icons.folder_shared_rounded),
              const SizedBox(width: 12),
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('requests').where('teacherId', isEqualTo: user?.uid).snapshots(),
                builder: (context, snapReq) {
                  int reqCount = snapReq.hasData ? snapReq.data!.docs.length : 0;
                  return _buildStatBox('НОВЫЕ ЗАЯВКИ', reqCount.toString(), Icons.notifications_active_rounded, color: reqCount > 0 ? Colors.orangeAccent : Colors.white24);
                }
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, {Color color = Colors.amber}) {
    return Expanded(
      child: _buildGlassCard(
        opacity: 0.1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white24, fontSize: 14)),
        ],
      ),
    );
  }

  void _showAddGroupDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: _buildGlassCard(
            opacity: 0.1,
            blur: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_add_rounded, color: Colors.amber, size: 40),
                const SizedBox(height: 16),
                const Text('НОВАЯ ГРУППА', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
                const SizedBox(height: 24),
                TextField(
                  controller: ctrl,
                  style: const TextStyle(color: Colors.white),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Название (например, П-41)',
                    labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.amber)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.02),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('ОТМЕНА', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (ctrl.text.isNotEmpty) {
                            _db.collection('groups').add({
                              'name': ctrl.text.trim().toUpperCase(),
                              'teacherId': user!.uid,
                              'institutionId': selectedInstitution,
                              'schedule': {},
                            });
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('СОЗДАТЬ', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteGroup(String id, String name) {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Удалить группу?'),
        content: Text('Все данные группы $name и расписание будут стерты.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ОТМЕНА', style: TextStyle(color: Colors.white38))),
          ElevatedButton(onPressed: () { _db.collection('groups').doc(id).delete(); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('УДАЛИТЬ')),
        ],
      )
    );
  }

  void _showStudentsList(String groupId, String groupName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              color: const Color(0xFF1A1C2C).withOpacity(0.95),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  Text('ГРУППА $groupName', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5)),
                  const Text('Список зачисленных студентов', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 24),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _db.collection('users').where('groupId', isEqualTo: groupId).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
                        final students = snapshot.data!.docs;
                        if (students.isEmpty) return _buildEmptyState(Icons.person_off_rounded, 'В группе пока нет студентов');
                        
                        return ListView.builder(
                          controller: controller,
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final s = students[index].data() as Map<String, dynamic>;
                            final String studentName = s['displayName'] ?? s['email'] ?? 'Без имени';
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildGlassCard(
                                opacity: 0.05,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.white.withOpacity(0.05),
                                    child: const Icon(Icons.person_rounded, color: Colors.white70),
                                  ),
                                  title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text(s['email'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white24)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20), 
                                    onPressed: () => _db.collection('users').doc(students[index].id).update({'groupId': null})
                                  ),
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
          ),
        ),
      ),
    );
  }

  void _manageGroupSchedule(String groupId, String groupName) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupSchedulePage(groupId: groupId, groupName: groupName)));
  }
}
