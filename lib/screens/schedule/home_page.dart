// lib/screens/schedule/home_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/app_drawer.dart';
import 'bell_schedule_page.dart';
import '../profile/profile_page.dart';

class HomePage extends StatefulWidget {
  final String place;
  const HomePage({super.key, required this.place});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> schedule = [];
  String? currentLesson;
  String? nextLesson;
  String? remainingTime;
  Timer? _timer;
  bool isLoading = true;
  bool isPending = false; 
  bool _use24Hour = true;
  AnimationController? _pulseController;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  Future<void> _loadData() async {
    await _loadSettings();
    await _loadSchedule();
    await _loadNote();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController?.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _use24Hour = prefs.getBool('use_24hour_format') ?? true;
    });
  }

  Future<void> _loadNote() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _noteController.text = prefs.getString('quick_note') ?? ''; });
  }

  Future<void> _saveNote(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quick_note', val);
  }

  Future<void> _cancelRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final reqs = await FirebaseFirestore.instance.collection('requests').where('studentId', isEqualTo: user.uid).get();
    for (var doc in reqs.docs) { await doc.reference.delete(); }
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'pendingRequest': false,
      'appMode': 'manual',
    });
    _loadData();
  }

  Future<void> _loadSchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => isLoading = false); return; }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      if (userData['pendingRequest'] == true) {
        setState(() { isPending = true; isLoading = false; });
        return;
      } else { setState(() => isPending = false); }

      final appMode = userData['appMode'] ?? 'manual';
      final groupId = userData['groupId'];

      if (appMode == 'join' && groupId != null) {
        final groupDoc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
        if (groupDoc.exists) {
          final groupData = groupDoc.data()!;
          final rawSchedule = groupData['schedule'];
          Map<String, dynamic> scheduleMap = (rawSchedule is Map) ? Map<String, dynamic>.from(rawSchedule) : {};
          final todayIndex = (DateTime.now().weekday - 1).toString();
          final todayLessons = (scheduleMap[todayIndex] ?? []) as List;
          schedule = todayLessons.map((e) => {
            'name': e['name'] ?? 'Урок',
            'start': _normalizeTime(e['start'] ?? '08:00'),
            'end': _normalizeTime(e['end'] ?? '08:45'),
            'time': '${e['start']} - ${e['end']}',
          }).toList();
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final sameEveryday = prefs.getBool('same_schedule') ?? true;
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('schedules').doc(sameEveryday ? widget.place : '${widget.place}_weekly').get();
        if (doc.exists) {
          if (sameEveryday) {
            schedule = (doc.data()!['items'] as List).map((e) => {
              'name': e['name'], 'start': _normalizeTime(e['start']), 'end': _normalizeTime(e['end']), 'time': '${e['start']} - ${e['end']}',
            }).toList();
          } else {
            final data = doc.data()!['days'] as Map<String, dynamic>;
            final today = _getDayName(DateTime.now());
            final todayLessons = (data[today] ?? []) as List;
            schedule = todayLessons.map((e) => {
              'name': e['name'], 'start': _normalizeTime(e['start']), 'end': _normalizeTime(e['end']), 'time': '${e['start']} - ${e['end']}',
            }).toList();
          }
        }
      }
    } catch (e) { debugPrint('Ошибка загрузки: $e'); }
    _updateNow();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateNow());
    setState(() => isLoading = false);
  }

  String _getDayName(DateTime date) {
    const days = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    return days[date.weekday - 1];
  }

  String _normalizeTime(String t) {
    if (!t.contains(':')) return t;
    final parts = t.split(':');
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  void _updateNow() {
    if (schedule.isEmpty) { setState(() { currentLesson = 'Пары нет'; nextLesson = '-'; remainingTime = null; }); return; }
    final nowMin = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
    bool found = false;
    for (int i = 0; i < schedule.length; i++) {
      int start = _toMinutes(schedule[i]['start']);
      int end = _toMinutes(schedule[i]['end']);
      if (nowMin >= start && nowMin < end) {
        setState(() {
          currentLesson = schedule[i]['name'];
          nextLesson = (i + 1 < schedule.length) ? schedule[i + 1]['name'] : 'Конец пар';
          remainingTime = '${end - nowMin} мин до конца';
        });
        found = true;
        break;
      }
    }
    if (!found) {
      final first = schedule.first;
      int firstStart = _toMinutes(first['start']);
      if (nowMin < firstStart) { setState(() { currentLesson = 'Перемена'; nextLesson = first['name']; remainingTime = 'До начала: ${firstStart - nowMin} мин'; }); }
      else { setState(() { currentLesson = 'Пары нет'; nextLesson = 'Занятия закончились'; remainingTime = null; }); }
    }
  }

  int _toMinutes(String t) {
    final parts = t.split(':');
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  Widget _buildGlassCard({required Widget child, double opacity = 0.05, double blur = 15}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(opacity) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLessonDots() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    if (schedule.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(schedule.length, (index) {
        bool isCurrent = schedule[index]['name'] == currentLesson;
        bool isPast = _toMinutes(schedule[index]['end']) < (TimeOfDay.now().hour * 60 + TimeOfDay.now().minute);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 12 : 8, height: 8,
          decoration: BoxDecoration(
            color: isCurrent ? primaryColor : (isPast ? primaryColor.withOpacity(0.3) : Colors.white24),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isCurrent ? [BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 8)] : null,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      drawer: const AppDrawer(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('ZvonOK', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5)), backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, actions: [_buildUserAvatar(context), const SizedBox(width: 16)]),
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)]))),
          Positioned(
            top: 100, right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withOpacity(0.15))),
            ),
          ),
          if (isLoading) const Center(child: CircularProgressIndicator())
          else if (isPending) _buildPendingScreen()
          else _buildMainContent(isDark, user),
        ],
      ),
    );
  }

  Widget _buildPendingScreen() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.timer_outlined, size: 80, color: primaryColor)),
            const SizedBox(height: 32),
            const Text('Заявка отправлена', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Ваша заявка на вступление в группу находится на рассмотрении у куратора. Пожалуйста, подождите.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, height: 1.5)),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: _cancelRequest, style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Отменить заявку')),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDark, User? user) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildHeader(isDark, user),
            const SizedBox(height: 20),
            _buildSystemAnnouncement(),
            _buildSummaryRow(),
            const SizedBox(height: 30),
            Text(_formatTime(TimeOfDay.now()), style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w200, letterSpacing: -2)),
            _buildLessonDots(),
            const SizedBox(height: 40),
            _buildCurrentLessonCard(),
            const SizedBox(height: 24),
            _buildRemainingLessonsList(),
            const SizedBox(height: 24),
            _buildQuickNote(),
            const SizedBox(height: 40),
            _buildFullScheduleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, User? user) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Добрый день,', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
          Text(user?.displayName ?? 'Студент', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ]),
        Text(_getDayName(DateTime.now()), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCurrentLessonCard() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('СЕЙЧАС', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2, color: primaryColor)),
            FadeTransition(opacity: _pulseController!, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle))),
          ]),
          const SizedBox(height: 12),
          Text(currentLesson ?? 'Пары нет', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          if (remainingTime != null) Text(remainingTime!, style: const TextStyle(fontSize: 16, color: Colors.white60)),
          const SizedBox(height: 20),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: _getLessonProgress(), minHeight: 6, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(primaryColor))),
        ],
      ),
    );
  }

  Widget _buildFullScheduleButton() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BellSchedulePage(place: widget.place))), style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 10), child: const Text('Открыть всё расписание', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))));
  }

  Widget _buildUserAvatar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())), child: CircleAvatar(radius: 20, backgroundColor: Colors.white10, backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null, child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.white70) : null));
  }

  String _formatTime(TimeOfDay time) { return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'; }

  double _getLessonProgress() {
    if (currentLesson == null || currentLesson == 'Пары нет' || currentLesson == 'Перемена') return 0.0;
    final nowMin = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
    final lst = schedule.firstWhere((e) => e['name'] == currentLesson, orElse: () => {});
    if (lst.isEmpty) return 0.0;
    final start = _toMinutes(lst['start']);
    final end = _toMinutes(lst['end']);
    if (end == start) return 0.0;
    return ((nowMin - start) / (end - start)).clamp(0.0, 1.0);
  }

  Widget _buildSummaryRow() {
    final nowMin = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
    final remainingCount = schedule.where((e) => _toMinutes(e['start']) > nowMin).length;
    final endTime = schedule.isNotEmpty ? schedule.last['end'] : '--:--';
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildSummaryItem(Icons.book_outlined, "$remainingCount", "Осталось"), _buildSummaryItem(Icons.flag_outlined, endTime, "Финиш"), _buildSummaryItem(Icons.timer_outlined, schedule.isEmpty ? "0" : "${schedule.length}", "Всего")]);
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Column(children: [Icon(icon, color: primaryColor, size: 20), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54))]);
  }

  Widget _buildRemainingLessonsList() {
    final nowMin = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
    final remaining = schedule.where((e) => _toMinutes(e['start']) > nowMin).toList();
    final primaryColor = Theme.of(context).colorScheme.primary;
    if (remaining.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12), child: Text('ПЛАН НА СЕГОДНЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white54))), SizedBox(height: 110, child: ListView.builder(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: remaining.length, itemBuilder: (context, index) { return Container(width: 160, margin: const EdgeInsets.only(right: 12), child: _buildGlassCard(opacity: 0.03, blur: 10, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(remaining[index]['start'], style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(remaining[index]['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))]))); }))]);
  }

  Widget _buildQuickNote() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return _buildGlassCard(opacity: 0.02, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(Icons.edit_note, color: primaryColor, size: 20), const SizedBox(width: 8), const Text('ЗАМЕТКА ДНЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54))]), TextField(controller: _noteController, onChanged: _saveNote, style: const TextStyle(fontSize: 14, color: Colors.white), decoration: const InputDecoration(hintText: 'Запишите что-нибудь важное...', hintStyle: TextStyle(color: Colors.white24, fontSize: 14), border: InputBorder.none), maxLines: 2)]));
  }

  Widget _buildSystemAnnouncement() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return StreamBuilder<DocumentSnapshot>(stream: FirebaseFirestore.instance.collection('system').doc('announcement').snapshots(), builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox.shrink();
      final data = snapshot.data!.data() as Map<String, dynamic>?;
      if (data == null || data['active'] == false) return const SizedBox.shrink();
      return Padding(padding: const EdgeInsets.only(bottom: 20), child: _buildGlassCard(opacity: 0.1, child: Row(children: [Icon(Icons.campaign_rounded, color: primaryColor, size: 28), const SizedBox(width: 16), Expanded(child: Text(data['text'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)))])));
    });
  }
}
