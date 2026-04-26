// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme_controller.dart';
import '../auth/auth_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  String _searchQuery = "";
  String _selectedRoleFilter = "все";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    _announcementController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthPage()), (route) => false);
    }
  }

  // КРАСИВЫЙ ПИКЕР ВУЗА ДЛЯ УЧИТЕЛЯ
  void _showInstitutionPicker(String uid, String email) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              color: const Color(0xFF0F2027).withOpacity(0.95),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  const Text('ВЫБОР ОРГАНИЗАЦИИ', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
                  const Text('Привязка преподавателя к базе', style: TextStyle(color: Colors.white24, fontSize: 11)),
                  const SizedBox(height: 24),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _db.collection('institutions').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
                        final docs = snapshot.data!.docs;
                        return ListView.builder(
                          controller: controller,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final inst = docs[index].data() as Map<String, dynamic>;
                            final instId = docs[index].id;
                            final name = inst['name'];
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildGlassCard(
                                opacity: 0.05,
                                child: ListTile(
                                  leading: const Icon(Icons.account_balance_rounded, color: Colors.amber),
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  trailing: const Icon(Icons.check_circle_outline, color: Colors.white10),
                                  onTap: () async {
                                    await _db.collection('users').doc(uid).update({
                                      'role': 'teacher',
                                      'institutionId': instId,
                                      'institutionName': name,
                                    });
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Учитель назначен в $name')));
                                    }
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
          ),
        ),
      ),
    );
  }

  void _showUserManagement(String uid, String email, String currentRole) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C2C).withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                Text(email, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('УПРАВЛЕНИЕ ДОСТУПОМ', style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.5)),
                const SizedBox(height: 40),

                _buildRoleCard(
                  title: 'СТУДЕНТ',
                  desc: 'Доступ к личному расписанию.',
                  icon: Icons.person_rounded,
                  isSelected: currentRole == 'student',
                  color: Colors.blueAccent,
                  onTap: () {
                    _db.collection('users').doc(uid).update({'role': 'student', 'institutionId': null});
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                _buildRoleCard(
                  title: 'ПРЕПОДАВАТЕЛЬ',
                  desc: 'Управление группами заведения.',
                  icon: Icons.school_rounded,
                  isSelected: currentRole == 'teacher',
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.pop(context);
                    _showInstitutionPicker(uid, email);
                  },
                ),
                const SizedBox(height: 12),
                _buildRoleCard(
                  title: 'АДМИНИСТРАТОР',
                  desc: 'Полный доступ к системе.',
                  icon: Icons.admin_panel_settings_rounded,
                  isSelected: currentRole == 'admin',
                  color: Colors.redAccent,
                  onTap: () {
                    _db.collection('users').doc(uid).update({'role': 'admin', 'institutionId': null});
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 32),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDeleteUser(uid, email);
                  },
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                  label: const Text('УДАЛИТЬ ПОЛЬЗОВАТЕЛЯ', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({required String title, required String desc, required IconData icon, required bool isSelected, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: isSelected ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color.withOpacity(0.5) : Colors.white.withOpacity(0.05), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.white24, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? color : Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  Text(desc, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
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
    if (_tabController == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Column(
          children: [
            Text('CONSOLE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 4)),
            Text('Система управления ZvonOK', style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.amber),
          onPressed: () => themeController.toggleTheme(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: _logout),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 4,
          labelColor: Colors.amber,
          unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
          tabs: const [
            Tab(text: 'ЛЮДИ'),
            Tab(text: 'ВУЗЫ'),
            Tab(text: 'ИНФО'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, 
                end: Alignment.bottomRight,
                colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)],
              ),
            ),
          ),
          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildInstitutionsTab(),
                _buildAnnouncementsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        _buildStatsHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: _buildGlassCard(
            opacity: 0.03,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Поиск по базе...', 
                hintStyle: TextStyle(color: Colors.white12), 
                prefixIcon: Icon(Icons.search, color: Colors.amber, size: 20), 
                border: InputBorder.none
              ),
            ),
          ),
        ),
        _buildFilterRow(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
              
              var users = snapshot.data!.docs;
              final now = DateTime.now();

              users = users.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final bool isGuest = data['isAnonymous'] == true || data['email'] == null;
                final email = data['email']?.toString().toLowerCase() ?? "";
                final role = data['role'] ?? "student";
                final lastSeenTs = data['lastSeen'] as Timestamp?;

                if (isGuest) return false;
                if (lastSeenTs != null) {
                  final diff = now.difference(lastSeenTs.toDate()).inDays;
                  if (diff > 7 && email != 'admin@zvonok.ru') return false;
                }

                return email.contains(_searchQuery) && (_selectedRoleFilter == "все" || role == _selectedRoleFilter);
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final data = users[index].data() as Map<String, dynamic>;
                  final uid = users[index].id;
                  final role = data['role'] ?? 'student';
                  final email = data['email'] ?? 'No Email';
                  final lastSeen = data['lastSeen'] as Timestamp?;
                  
                  final isOnline = lastSeen != null && DateTime.now().difference(lastSeen.toDate()).inMinutes < 15;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGlassCard(
                      opacity: 0.05,
                      child: ListTile(
                        onTap: () => _showUserManagement(uid, email, role),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getRoleColor(role).withOpacity(0.1),
                              child: Text(email[0].toUpperCase(), style: TextStyle(color: _getRoleColor(role), fontWeight: FontWeight.bold)),
                            ),
                            Positioned(bottom: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: isOnline ? Colors.greenAccent : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1A1C2C), width: 2)))),
                          ],
                        ),
                        title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(role.toUpperCase(), style: TextStyle(color: _getRoleColor(role), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white10),
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

  Widget _buildStatsHeader() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final users = snapshot.data!.docs.where((d) => (d.data() as Map)['isAnonymous'] != true).toList();
        final now = DateTime.now();
        int online = users.where((d) {
          final ls = (d.data() as Map)['lastSeen'] as Timestamp?;
          return ls != null && now.difference(ls.toDate()).inMinutes < 15;
        }).length;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _buildStatBox('ВСЕГО', users.length.toString(), Icons.people_outline_rounded),
              const SizedBox(width: 12),
              _buildStatBox('ОНЛАЙН', online.toString(), Icons.bolt_rounded, color: Colors.greenAccent),
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
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: ["все", "student", "teacher", "admin"].map((f) => _buildFilterChip(f)).toList(),
      ),
    );
  }

  Widget _buildFilterChip(String value) {
    bool isSel = _selectedRoleFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(value.toUpperCase(), style: TextStyle(fontSize: 10, color: isSel ? Colors.black : Colors.white60)),
        selected: isSel,
        onSelected: (s) => setState(() => _selectedRoleFilter = value),
        selectedColor: Colors.amber,
        backgroundColor: Colors.white.withOpacity(0.05),
        side: BorderSide.none,
        showCheckmark: false,
      ),
    );
  }

  Widget _buildInstitutionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: _buildGlassCard(
            opacity: 0.1,
            child: InkWell(
              onTap: _showAddInstitutionDialog,
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_business_rounded, color: Colors.amber), SizedBox(width: 12), Text('НОВАЯ ОРГАНИЗАЦИЯ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1))]),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('institutions').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final inst = docs[index].data() as Map<String, dynamic>;
                  final instId = docs[index].id;
                  return _buildInstitutionCard(instId, inst['name'], inst['type']);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInstitutionCard(String id, String name, String type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.account_balance_rounded, color: Colors.amber, size: 20)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(type.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1))])),
                IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => _db.collection('institutions').doc(id).delete()),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10, height: 1)),
            const Text('ПРЕПОДАВАТЕЛИ:', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('users').where('role', isEqualTo: 'teacher').where('institutionId', isEqualTo: id).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final teachers = snapshot.data!.docs;
                if (teachers.isEmpty) return const Text('Нет назначенных учителей', style: TextStyle(color: Colors.white12, fontSize: 12));
                return Wrap(
                  spacing: 8, runSpacing: 8,
                  children: teachers.map((t) {
                    final email = (t.data() as Map)['email'] ?? 'Учитель';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.05))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_pin_rounded, size: 12, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text(email, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BROADCAST CENTER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.amber, letterSpacing: 2)),
          const SizedBox(height: 32),
          _buildGlassCard(
            opacity: 0.02,
            child: TextField(
              controller: _announcementController,
              maxLines: 5,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(hintText: 'Текст объявления для всех пользователей...', hintStyle: TextStyle(color: Colors.white12), border: InputBorder.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_announcementController.text.isNotEmpty) {
                  await _db.collection('system').doc('announcement').set({'text': _announcementController.text, 'timestamp': FieldValue.serverTimestamp(), 'active': true});
                  _announcementController.clear();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Опубликовано!')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('ВЫПУСТИТЬ В ЭФИР', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: TextButton(onPressed: () => _db.collection('system').doc('announcement').update({'active': false}), child: const Text('СНЯТЬ ТЕКУЩЕЕ ОБЪЯВЛЕНИЕ', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  void _confirmDeleteUser(String uid, String email) {
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1A1C2C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), title: const Text('Удалить аккаунт?'), content: Text('Профиль $email будет стерт.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ОТМЕНА', style: TextStyle(color: Colors.white38))), ElevatedButton(onPressed: () { _db.collection('users').doc(uid).delete(); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('УДАЛИТЬ'))]));
  }

  void _showAddInstitutionDialog() {
    final nameCtrl = TextEditingController();
    String type = 'school';
    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(backgroundColor: const Color(0xFF1A1C2C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), title: const Text('Новое заведение'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Название', labelStyle: TextStyle(color: Colors.white54))), const SizedBox(height: 24), Row(children: [_buildTypeOption('school', 'Школа', type, (v) => setDialogState(() => type = v)), const SizedBox(width: 12), _buildTypeOption('college', 'Колледж', type, (v) => setDialogState(() => type = v))])]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ОТМЕНА', style: TextStyle(color: Colors.white38))), ElevatedButton(onPressed: () { if (nameCtrl.text.isNotEmpty) { _db.collection('institutions').add({'name': nameCtrl.text, 'type': type}); Navigator.pop(context); } }, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber), child: const Text('ДОБАВИТЬ', style: TextStyle(color: Colors.black)))])));
  }

  Widget _buildTypeOption(String value, String label, String current, Function(String) onSelect) {
    bool isSel = value == current;
    return Expanded(child: InkWell(onTap: () => onSelect(value), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isSel ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSel ? Colors.amber : Colors.white10)), child: Center(child: Text(label, style: TextStyle(color: isSel ? Colors.amber : Colors.white38, fontWeight: isSel ? FontWeight.bold : FontWeight.normal))))));
  }

  Color _getRoleColor(String role) {
    if (role == 'admin') return Colors.redAccent;
    if (role == 'teacher') return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  String _formatLastSeen(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    return '${diff.inDays} д назад';
  }
}
