// lib/screens/setup/join_institution_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../schedule/home_page.dart';
import 'app_mode_selection_page.dart';
import '../../services/database_service.dart';

class JoinInstitutionPage extends StatefulWidget {
  const JoinInstitutionPage({super.key});

  @override
  State<JoinInstitutionPage> createState() => _JoinInstitutionPageState();
}

class _JoinInstitutionPageState extends State<JoinInstitutionPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? selectedInstId;
  String? selectedInstName;
  String? selectedGroupId;
  String? selectedGroupName;
  bool isLoading = true;
  bool hasActiveRequest = false;

  @override
  void initState() {
    super.initState();
    _checkActiveRequest();
  }

  Future<void> _checkActiveRequest() async {
    final user = databaseService.user;
    if (user != null) {
      final doc = await databaseService.getUserData();
      if (mounted) {
        setState(() {
          hasActiveRequest = (doc.data() as Map<String, dynamic>?)?['pendingRequest'] ?? false;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelRequest() async {
    setState(() => isLoading = true);
    await databaseService.cancelJoinRequest();
    if (mounted) setState(() { hasActiveRequest = false; isLoading = false; });
  }

  void _showSearchPicker({
    required String title,
    required Stream<QuerySnapshot> stream,
    required Function(String id, String name) onSelect,
    Set<String>? filterIds,
  }) {
    String searchQuery = "";
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      autofocus: true,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      onChanged: (v) => setDialogState(() => searchQuery = v.toLowerCase()),
                      decoration: const InputDecoration(
                        hintText: 'Поиск...',
                        hintStyle: TextStyle(color: Colors.white24),
                        prefixIcon: Icon(Icons.search, color: Colors.amber, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: stream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));

                        var docs = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'].toString().toLowerCase();
                          if (filterIds != null && !filterIds.contains(data['teacherId'])) return false;
                          return name.contains(searchQuery);
                        }).toList();

                        if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('Ничего не найдено', style: TextStyle(color: Colors.white24)));

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final name = (docs[index].data() as Map)['name'];
                            return ListTile(
                              title: Text(name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
                              trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white10 : Colors.black12, size: 16),
                              onTap: () {
                                onSelect(docs[index].id, name);
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('ЗАКРЫТЬ', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendJoinRequest() async {
    if (selectedInstId == null || selectedGroupId == null) return;
    setState(() => isLoading = true);
    final user = databaseService.user;
    try {
      if (user != null) {
        final groupDoc = await _db.collection('groups').doc(selectedGroupId).get();
        final groupData = groupDoc.data();
        final teacherId = groupData?['teacherId'];
        
        await _db.collection('requests').add({
          'studentId': user.uid,
          'studentName': user.displayName ?? user.email?.split('@')[0] ?? 'Студент',
          'studentEmail': user.email,
          'institutionId': selectedInstId,
          'institutionName': selectedInstName,
          'groupId': selectedGroupId,
          'groupName': selectedGroupName,
          'teacherId': teacherId,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        await databaseService.updateUserData({
          'pendingRequest': true, 
          'appMode': 'join',
          'institutionId': selectedInstId,
          'institutionName': selectedInstName,
        });
      }
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage(place: 'school')), (route) => false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally { if (mounted) setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.amber)));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppModeSelectionPage()))
        )
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                  ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
                  : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)]
              )
            )
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: hasActiveRequest ? _buildAlreadyRequestedView() : _buildSelectionView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyRequestedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.amber),
        const SizedBox(height: 24),
        const Text('Заявка отправлена', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Ваша заявка находится на рассмотрении у куратора группы. Пожалуйста, подождите.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, height: 1.5)),
        const SizedBox(height: 40),
        ElevatedButton(onPressed: _cancelRequest, style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('ОТМЕНИТЬ ЗАЯВКУ', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildSelectionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Присоединиться', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const Text('Найдите свою группу для синхронизации', style: TextStyle(color: Colors.white30)),
        const SizedBox(height: 48),
        
        _buildSelectionCard(
          label: 'УЧЕБНОЕ ЗАВЕДЕНИЕ',
          value: selectedInstName,
          icon: Icons.account_balance_rounded,
          onTap: () => _showSearchPicker(
            title: 'ВЫБЕРИТЕ ЗАВЕДЕНИЕ',
            stream: _db.collection('institutions').snapshots(),
            onSelect: (id, name) => setState(() {
              selectedInstId = id;
              selectedInstName = name;
              selectedGroupId = null;
              selectedGroupName = null;
            }),
          ),
        ),
        
        const SizedBox(height: 24),
        
        _buildSelectionCard(
          label: 'ВАША ГРУППА',
          value: selectedGroupName,
          icon: Icons.groups_rounded,
          isEnabled: selectedInstId != null,
          onTap: () async {
            final teacherSnap = await _db.collection('users').where('role', isEqualTo: 'teacher').get();
            final activeTeacherIds = teacherSnap.docs.map((d) => d.id).toSet();

            _showSearchPicker(
              title: 'ВЫБЕРИТЕ ГРУППУ',
              stream: _db.collection('groups').where('institutionId', isEqualTo: selectedInstId).snapshots(),
              filterIds: activeTeacherIds,
              onSelect: (id, name) => setState(() {
                selectedGroupId = id;
                selectedGroupName = name;
              }),
            );
          },
        ),
        
        const Spacer(),
        SizedBox(
          width: double.infinity, 
          child: ElevatedButton(
            onPressed: (selectedInstId != null && selectedGroupId != null) ? _sendJoinRequest : null, 
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber, 
              foregroundColor: Colors.black, 
              padding: const EdgeInsets.symmetric(vertical: 20), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 10,
              disabledBackgroundColor: Colors.white10,
            ), 
            child: const Text('ОТПРАВИТЬ ЗАЯВКУ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1))
          )
        ),
      ],
    );
  }

  Widget _buildSelectionCard({required String label, String? value, required IconData icon, required VoidCallback? onTap, bool isEnabled = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.amber, letterSpacing: 1.5)),
        ),
        InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(isEnabled ? 0.05 : 0.02) : Colors.white.withOpacity(isEnabled ? 0.7 : 0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isSelected ? Colors.amber.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: isEnabled ? (isSelected ? Colors.amber : (isDark ? Colors.white24 : Colors.black26)) : Colors.white10),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        value ?? (isEnabled ? 'Нажмите, чтобы выбрать...' : 'Сначала выберите заведение'),
                        style: TextStyle(
                          color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white24 : Colors.black26),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(Icons.search_rounded, color: isEnabled ? (isDark ? Colors.white24 : Colors.black26) : Colors.transparent, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
