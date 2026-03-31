// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  String _searchQuery = "";
  String _selectedRoleFilter = "все";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Вернули к 3
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _announcementController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_place');
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthPage()), (route) => false);
    }
  }

  Widget _buildGlassCard({required Widget child, double opacity = 0.05, double blur = 10}) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold)),
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
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'Люди'),
            Tab(icon: Icon(Icons.account_balance_rounded), text: 'Заведения'),
            Tab(icon: Icon(Icons.campaign_rounded), text: 'Объявления'),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: _buildGlassCard(
            opacity: 0.03,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Поиск пользователя...', hintStyle: TextStyle(color: Colors.white24), prefixIcon: Icon(Icons.search, color: Colors.amber), border: InputBorder.none),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("все"),
                      _buildFilterChip("student", label: "Студенты"),
                      _buildFilterChip("teacher", label: "Учителя"),
                      _buildFilterChip("admin", label: "Админы"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
              var users = snapshot.data!.docs;
              users = users.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final email = data['email']?.toString().toLowerCase() ?? "";
                final role = data['role'] ?? "student";
                return email.contains(_searchQuery) && (_selectedRoleFilter == "все" || role == _selectedRoleFilter);
              }).toList();
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final data = users[index].data() as Map<String, dynamic>;
                  final uid = users[index].id;
                  final role = data['role'] ?? 'student';
                  final email = data['email'] ?? 'No Email';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGlassCard(
                      child: ListTile(
                        title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Роль: ${role.toUpperCase()}', style: TextStyle(color: _getRoleColor(role), fontSize: 12, fontWeight: FontWeight.bold)),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.manage_accounts, color: Colors.amber),
                          onSelected: (newRole) {
                            if (newRole == 'delete') _confirmDeleteUser(uid, email);
                            else _db.collection('users').doc(uid).update({'role': newRole});
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'student', child: Text('Сделать Студентом')),
                            const PopupMenuItem(value: 'teacher', child: Text('Сделать Учителем')),
                            const PopupMenuItem(value: 'admin', child: Text('Сделать Админом')),
                            const PopupMenuDivider(),
                            const PopupMenuItem(value: 'delete', child: Text('Удалить аккаунт', style: TextStyle(color: Colors.redAccent))),
                          ],
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

  Widget _buildFilterChip(String value, {String? label}) {
    bool isSelected = _selectedRoleFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label ?? value.toUpperCase(), style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white70)), selected: isSelected, onSelected: (selected) { if (selected) setState(() => _selectedRoleFilter = value); }, selectedColor: Colors.amber, backgroundColor: Colors.white10),
    );
  }

  Widget _buildInstitutionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            onPressed: _showAddInstitutionDialog,
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('Добавить заведение', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGlassCard(
                      child: ListTile(
                        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.school, color: Colors.amber)),
                        title: Text(inst['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(inst['type'] == 'school' ? 'Школа' : 'Колледж', style: const TextStyle(color: Colors.white54)),
                        trailing: IconButton(icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent), onPressed: () => _db.collection('institutions').doc(docs[index].id).delete()),
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

  Widget _buildAnnouncementsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Глобальное оповещение', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Это сообщение увидят все пользователи на главной странице.', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 24),
          _buildGlassCard(
            opacity: 0.03,
            child: TextField(
              controller: _announcementController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Введите текст объявления...', hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              if (_announcementController.text.isNotEmpty) {
                await _db.collection('system').doc('announcement').set({'text': _announcementController.text, 'timestamp': FieldValue.serverTimestamp(), 'active': true});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Объявление опубликовано!')));
                  _announcementController.clear();
                }
              }
            },
            icon: const Icon(Icons.send_rounded, color: Colors.black),
            label: const Text('Опубликовать', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: () => _db.collection('system').doc('announcement').update({'active': false}), child: const Center(child: Text('Убрать текущее объявление', style: TextStyle(color: Colors.redAccent)))),
        ],
      ),
    );
  }

  void _confirmDeleteUser(String uid, String email) {
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1A1C2C), title: const Text('Удалить пользователя?'), content: Text('Вы уверены, что хотите удалить $email?'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')), TextButton(onPressed: () { _db.collection('users').doc(uid).delete(); Navigator.pop(context); }, child: const Text('Удалить', style: TextStyle(color: Colors.redAccent)))]));
  }

  void _showAddInstitutionDialog() {
    final nameCtrl = TextEditingController();
    String type = 'school';
    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(backgroundColor: const Color(0xFF1A1C2C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Новое заведение'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Название', labelStyle: TextStyle(color: Colors.white54))), const SizedBox(height: 10), DropdownButton<String>(value: type, dropdownColor: const Color(0xFF1A1C2C), isExpanded: true, items: const [DropdownMenuItem(value: 'school', child: Text('Школа', style: TextStyle(color: Colors.white))), DropdownMenuItem(value: 'college', child: Text('Колледж', style: TextStyle(color: Colors.white)))], onChanged: (v) => setDialogState(() => type = v!))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')), ElevatedButton(onPressed: () { if (nameCtrl.text.isNotEmpty) { _db.collection('institutions').add({'name': nameCtrl.text, 'type': type}); Navigator.pop(context); } }, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber), child: const Text('Добавить', style: TextStyle(color: Colors.black)))])));
  }

  Color _getRoleColor(String role) {
    if (role == 'admin') return Colors.redAccent;
    if (role == 'teacher') return Colors.orangeAccent;
    return Colors.greenAccent;
  }
}
