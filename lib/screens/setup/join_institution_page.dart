// lib/screens/setup/join_institution_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../schedule/home_page.dart';
import 'app_mode_selection_page.dart';

class JoinInstitutionPage extends StatefulWidget {
  const JoinInstitutionPage({super.key});

  @override
  State<JoinInstitutionPage> createState() => _JoinInstitutionPageState();
}

class _JoinInstitutionPageState extends State<JoinInstitutionPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? selectedInstId;
  String? selectedGroupId;
  bool isLoading = true;
  bool hasActiveRequest = false;

  @override
  void initState() {
    super.initState();
    _checkActiveRequest();
  }

  Future<void> _checkActiveRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          hasActiveRequest = doc.data()?['pendingRequest'] ?? false;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelRequest() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final reqs = await _db.collection('requests').where('studentId', isEqualTo: user.uid).get();
      for (var doc in reqs.docs) { await doc.reference.delete(); }
      await _db.collection('users').doc(user.uid).update({
        'pendingRequest': false,
        'appMode': 'manual',
      });
    }
    if (mounted) setState(() { hasActiveRequest = false; isLoading = false; });
  }

  Future<void> _sendJoinRequest() async {
    if (selectedInstId == null || selectedGroupId == null) return;
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null) {
        final groupDoc = await _db.collection('groups').doc(selectedGroupId).get();
        final groupData = groupDoc.data();
        final teacherId = groupData?['teacherId'];
        final groupName = groupData?['name'];
        final instDoc = await _db.collection('institutions').doc(selectedInstId).get();
        final instName = instDoc.data()?['name'] ?? 'Учебное заведение';

        await _db.collection('requests').add({
          'studentId': user.uid,
          'studentName': user.displayName ?? user.email?.split('@')[0] ?? 'Студент',
          'studentEmail': user.email,
          'institutionId': selectedInstId,
          'institutionName': instName,
          'groupId': selectedGroupId,
          'groupName': groupName,
          'teacherId': teacherId,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _db.collection('users').doc(user.uid).update({'pendingRequest': true, 'appMode': 'join'});
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppModeSelectionPage())))),
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)]))),
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
        const Text('Заявка уже отправлена', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Вы не можете отправить вторую заявку, пока текущая не будет рассмотрена куратором.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 40),
        ElevatedButton(onPressed: _cancelRequest, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 55)), child: const Text('Отменить текущую заявку')),
      ],
    );
  }

  Widget _buildSelectionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Присоединиться', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const Text('Выберите вашу группу для получения расписания', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 32),
        _buildDropdownHeader('Учебное заведение'),
        _buildInstDropdown(),
        const SizedBox(height: 24),
        _buildDropdownHeader('Группа'),
        _buildGroupDropdown(),
        const Spacer(),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (selectedInstId != null && selectedGroupId != null) ? _sendJoinRequest : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Отправить заявку', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
      ],
    );
  }

  Widget _buildDropdownHeader(String title) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)));

  Widget _buildInstDropdown() {
    return _buildGlassCard(
      child: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('institutions').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          return DropdownButtonHideUnderline(child: DropdownButton<String>(value: selectedInstId, isExpanded: true, dropdownColor: const Color(0xFF1A1C2C), items: snapshot.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text((doc.data() as Map)['name'], style: const TextStyle(color: Colors.white)))).toList(), onChanged: (v) => setState(() { selectedInstId = v; selectedGroupId = null; })));
        }
      ),
    );
  }

  Widget _buildGroupDropdown() {
    return _buildGlassCard(
      child: selectedInstId == null ? const Text('Сначала выберите заведение', style: TextStyle(color: Colors.white24)) : StreamBuilder<QuerySnapshot>(
        stream: _db.collection('groups').where('institutionId', isEqualTo: selectedInstId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          if (snapshot.data!.docs.isEmpty) return const Text('Нет доступных групп', style: TextStyle(color: Colors.white38));
          return DropdownButtonHideUnderline(child: DropdownButton<String>(value: selectedGroupId, isExpanded: true, dropdownColor: const Color(0xFF1A1C2C), items: snapshot.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text((doc.data() as Map)['name'], style: const TextStyle(color: Colors.white)))).toList(), onChanged: (v) => setState(() => selectedGroupId = v)));
        }
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))), child: child)));
  }
}
