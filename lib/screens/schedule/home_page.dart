// lib/screens/schedule/home_page.dart ГЛАВНАЯ СТРАНИЦА
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
  bool _use24Hour = true;
  AnimationController? _pulseController;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
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
    setState(() {
      _noteController.text = prefs.getString('quick_note') ?? '';
    });
  }

  Future<void> _saveNote(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quick_note', val);
  }

  Future<void> _loadSchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final sameEveryday = prefs.getBool('same_schedule') ?? true;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('schedules')
          .doc(sameEveryday ? widget.place : '${widget.place}_weekly')
          .get();

      if (doc.exists) {
        if (sameEveryday) {
          schedule = (doc.data()!['items'] as List)
              .map((e) => {
                    'name': e['name'],
                    'start': _normalizeTime(e['start']),
                    'end': _normalizeTime(e['end']),
                    'time': '${e['start']} - ${e['end']}',
                  })
              .toList();
        } else {
          final data = doc.data()!['days'] as Map<String, dynamic>;
          final today = _getDayName(DateTime.now());
          final todayLessons = (data[today] ?? []) as List;
          schedule = todayLessons
              .map((e) => {
                    'name': e['name'],
                    'start': _normalizeTime(e['start']),
                    'end': _normalizeTime(e['end']),
                    'time': '${e['start']} - ${e['end']}',
                  })
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки: $e');
    }

    _updateNow();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateNow());
    setState(() => isLoading = false);
  }

  String _getDayName(DateTime date) {
    const days = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    return days[date.weekday - 1];
  }

  String _normalizeTime(String t) {
    final parts = t.split(':');
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  void _updateNow() {
    if (schedule.isEmpty) {
      setState(() {
        currentLesson = 'Пары нет';
        nextLesson = '-';
        remainingTime = null;
      });
      return;
    }

    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
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
      if (nowMin < firstStart) {
        setState(() {
          currentLesson = 'Перемена';
          nextLesson = first['name'];
          remainingTime = 'До начала: ${firstStart - nowMin} мин';
        });
      } else {
        setState(() {
          currentLesson = 'Пары нет';
          nextLesson = 'Занятия закончились';
          remainingTime = null;
        });
      }
    }
  }

  int _toMinutes(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Доброй ночи';
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  Widget _buildLessonDots() {
    if (schedule.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(schedule.length, (index) {
        bool isCurrent = schedule[index]['name'] == currentLesson;
        bool isPast = _toMinutes(schedule[index]['end']) < (TimeOfDay.now().hour * 60 + TimeOfDay.now().minute);
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isCurrent 
              ? Colors.amber 
              : (isPast ? Colors.amber.withOpacity(0.3) : Colors.white24),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isCurrent ? [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 8)] : null,
          ),
        );
      }),
    );
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

  Widget _buildSummaryRow() {
    final nowMin = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
    final remainingCount = schedule.where((e) => _toMinutes(e['start']) > nowMin).length;
    final endTime = schedule.isNotEmpty ? schedule.last['end'] : '--:--';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryItem(Icons.book_outlined, "$remainingCount", "Осталось"),
        _buildSummaryItem(Icons.flag_outlined, endTime, "Финиш"),
        _buildSummaryItem(Icons.timer_outlined, schedule.isEmpty ? "0" : "${schedule.length}", "Всего"),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }

  Widget _buildRemainingLessonsList() {
    final nowMin = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
    final remaining = schedule.where((e) => _toMinutes(e['start']) > nowMin).toList();
    if (remaining.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Text('ПЛАН НА СЕГОДНЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white54)),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: remaining.length,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: _buildGlassCard(
                  opacity: 0.03,
                  blur: 10,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(remaining[index]['start'], style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(remaining[index]['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickNote() {
    return _buildGlassCard(
      opacity: 0.02,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.edit_note, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('ЗАМЕТКА ДНЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54)),
            ],
          ),
          TextField(
            controller: _noteController,
            onChanged: _saveNote,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Запишите что-нибудь важное...',
              hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
              border: InputBorder.none,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    if (_use24Hour) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }

  // --- Виджет объявления от админа ---
  Widget _buildSystemAnnouncement() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('system').doc('announcement').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null || data['active'] == false) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildGlassCard(
            opacity: 0.1,
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded, color: Colors.amber, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    data['text'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final currentWeekday = _getDayName(DateTime.now());

    return Scaffold(
      drawer: const AppDrawer(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('ZvonOK', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [_buildUserAvatar(context), const SizedBox(width: 16)],
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
                  : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)],
              ),
            ),
          ),
          Positioned(
            top: 100, right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber.withOpacity(0.15))),
            ),
          ),
          Positioned(
            bottom: 100, left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.1))),
            ),
          ),

          isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_getGreeting(), style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                              Text(user?.displayName ?? 'Студент', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text(currentWeekday, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // ВСТАВКА ОБЪЯВЛЕНИЯ
                      _buildSystemAnnouncement(),

                      _buildSummaryRow(),
                      const SizedBox(height: 30),
                      Text(_formatTime(TimeOfDay.now()), style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w200, letterSpacing: -2)),
                      _buildLessonDots(),
                      const SizedBox(height: 40),

                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('СЕЙЧАС', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2, color: Colors.amber)),
                                if (_pulseController != null)
                                  FadeTransition(
                                    opacity: _pulseController!,
                                    child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                                  )
                                else
                                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(currentLesson ?? 'Пары нет', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                            if (remainingTime != null) Text(remainingTime!, style: const TextStyle(fontSize: 16, color: Colors.white60)),
                            const SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _getLessonProgress(),
                                minHeight: 6,
                                backgroundColor: Colors.white10,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      _buildRemainingLessonsList(),
                      
                      const SizedBox(height: 24),
                      _buildQuickNote(),

                      const SizedBox(height: 40),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BellSchedulePage(place: widget.place))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 10,
                            shadowColor: Colors.amber.withOpacity(0.3),
                          ),
                          child: const Text('Открыть всё расписание', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  double _getLessonProgress() {
    if (currentLesson == null || currentLesson == 'Пары нет' || currentLesson == 'Перемена') return 0.0;
    final nowMin = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
    final lst = schedule.firstWhere((e) => e['name'] == currentLesson, orElse: () => {});
    if (lst.isEmpty) return 0.0;
    final start = _toMinutes(lst['start']);
    final end = _toMinutes(lst['end']);
    return ((nowMin - start) / (end - start)).clamp(0.0, 1.0);
  }

  Widget _buildUserAvatar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white10,
        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
        child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.white70) : null,
      ),
    );
  }
}
