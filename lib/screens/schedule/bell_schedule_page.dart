// lib/screens/schedule/bell_schedule_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/helpers.dart';
import '../../models/lesson_model.dart';
import '../../services/history_service.dart';
import 'edit_lesson_page.dart';
import '../profile/profile_page.dart';

class BellSchedulePage extends StatefulWidget {
  final String place;
  const BellSchedulePage({super.key, required this.place});

  @override
  State<BellSchedulePage> createState() => _BellSchedulePageState();
}

class _BellSchedulePageState extends State<BellSchedulePage> with SingleTickerProviderStateMixin {
  List<Lesson> schedule = [];
  Map<String, List<Lesson>> weeklySchedule = {};
  bool sameEveryday = true;
  final user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  final List<String> days = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: days.length, vsync: this);
    _loadSettingsAndSchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    sameEveryday = prefs.getBool('same_schedule') ?? true;
    if (sameEveryday) {
      await _loadSchedule();
    } else {
      await _loadWeeklySchedule();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadSchedule() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('schedules').doc(widget.place).get();
    if (doc.exists) {
      schedule = (doc.data()!['items'] as List).map((item) => Lesson.fromMap(item)).toList();
    } else {
      await _generateSchedule();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadWeeklySchedule() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('schedules').doc('${widget.place}_weekly').get();
    if (doc.exists) {
      weeklySchedule = Map<String, List<Lesson>>.fromEntries(
        (doc.data()!['days'] as Map<String, dynamic>).entries.map((entry) {
          return MapEntry(entry.key, (entry.value as List).map((e) => Lesson.fromMap(e)).toList());
        }),
      );
    } else {
      await _generateWeeklySchedule();
    }
    if (mounted) setState(() {});
  }

  Future<void> _generateSchedule() async {
    List<Lesson> generated = [];
    TimeOfDay current = widget.place == 'school' ? const TimeOfDay(hour: 8, minute: 0) : const TimeOfDay(hour: 9, minute: 0);
    for (int i = 1; i <= 7; i++) {
      final end = TimeOfDay(hour: (current.hour + ((current.minute + 45) ~/ 60)) % 24, minute: (current.minute + 45) % 60);
      generated.add(Lesson(name: widget.place == 'school' ? '$i урок' : '$i пара', start: formatTime24(current), end: formatTime24(end)));
      current = TimeOfDay(hour: (end.hour + ((end.minute + 10) ~/ 60)) % 24, minute: (end.minute + 10) % 60);
    }
    schedule = generated;
    await _saveSchedule();
  }

  Future<void> _generateWeeklySchedule() async {
    for (var day in days) {
      List<Lesson> generated = [];
      TimeOfDay current = widget.place == 'school' ? const TimeOfDay(hour: 8, minute: 0) : const TimeOfDay(hour: 9, minute: 0);
      for (int i = 1; i <= 7; i++) {
        final end = TimeOfDay(hour: (current.hour + ((current.minute + 45) ~/ 60)) % 24, minute: (current.minute + 45) % 60);
        generated.add(Lesson(name: widget.place == 'school' ? '$i урок' : '$i пара', start: formatTime24(current), end: formatTime24(end)));
        current = TimeOfDay(hour: (end.hour + ((end.minute + 10) ~/ 60)) % 24, minute: (end.minute + 10) % 60);
      }
      weeklySchedule[day] = generated;
    }
    await _saveWeeklySchedule();
  }

  Future<void> _saveSchedule() async {
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('schedules').doc(widget.place).set({'items': schedule.map((l) => l.toMap()).toList()});
  }

  Future<void> _saveWeeklySchedule() async {
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('schedules').doc('${widget.place}_weekly').set({
      'days': Map.fromEntries(weeklySchedule.entries.map((e) => MapEntry(e.key, e.value.map((l) => l.toMap()).toList())))
    });
  }

  Future<void> _addLesson(Lesson newLesson, [String? day]) async {
    setState(() {
      if (sameEveryday) {
        schedule.add(newLesson);
        schedule.sort((a, b) => compareTime(a.start, b.start));
      } else {
        final d = day ?? days[_tabController.index];
        weeklySchedule[d] ??= [];
        weeklySchedule[d]!.add(newLesson);
        weeklySchedule[d]!.sort((a, b) => compareTime(a.start, b.start));
      }
    });
    await HistoryService.addHistoryEntry(action: 'added', lessonName: newLesson.name, place: widget.place);
    sameEveryday ? await _saveSchedule() : await _saveWeeklySchedule();
  }

  Future<void> _editLesson(int index, Lesson updated, [String? day]) async {
    setState(() {
      if (sameEveryday) {
        schedule[index] = updated;
        schedule.sort((a, b) => compareTime(a.start, b.start));
      } else {
        final d = day ?? days[_tabController.index];
        weeklySchedule[d]![index] = updated;
        weeklySchedule[d]!.sort((a, b) => compareTime(a.start, b.start));
      }
    });
    await HistoryService.addHistoryEntry(action: 'edited', lessonName: updated.name, place: widget.place);
    sameEveryday ? await _saveSchedule() : await _saveWeeklySchedule();
  }

  Future<void> _deleteLesson(int index, [String? day]) async {
    final lesson = sameEveryday ? schedule[index] : weeklySchedule[day ?? days[_tabController.index]]![index];
    setState(() {
      sameEveryday ? schedule.removeAt(index) : weeklySchedule[day ?? days[_tabController.index]]!.removeAt(index);
    });
    await HistoryService.addHistoryEntry(action: 'deleted', lessonName: lesson.name, place: widget.place);
    sameEveryday ? await _saveSchedule() : await _saveWeeklySchedule();
  }

  Widget _buildGlassCard({required Widget child, double opacity = 0.05, double blur = 15}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
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
      drawer: const AppDrawer(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.place == "school" ? "Школьное расписание" : "Пары в колледже", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [_buildUserAvatar(context), const SizedBox(width: 16)],
        bottom: sameEveryday ? null : TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          tabs: [for (var d in days) Tab(text: d)],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditLessonPage(name: '', start: '08:00', end: '08:45')));
          if (res != null && mounted) await _addLesson(res);
        },
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Добавить', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber,
      ),
      body: Stack(
        children: [
          // Фон
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)],
              ),
            ),
          ),
          // Стабильные декоративные сферы (без ImageFiltered)
          Positioned(
            top: 50, right: -30,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.15), blurRadius: 100, spreadRadius: 20)],
              ),
            ),
          ),
          Positioned(
            bottom: 50, left: -30,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 120, spreadRadius: 30)],
              ),
            ),
          ),
          SafeArea(
            child: sameEveryday ? _buildScheduleList(schedule) : TabBarView(controller: _tabController, children: [for (var d in days) _buildScheduleList(weeklySchedule[d] ?? [], d)]),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
      child: CircleAvatar(radius: 18, backgroundColor: Colors.white10, backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null, child: user?.photoURL == null ? const Icon(Icons.person, size: 20, color: Colors.white70) : null),
    );
  }

  Widget _buildScheduleList(List<Lesson> lessons, [String? day]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (lessons.isEmpty) return Center(child: Text('Пока пусто', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)));

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildGlassCard(
            opacity: 0.04,
            child: Dismissible(
              key: ValueKey('${lesson.name}-$index-${day ?? ''}'),
              direction: DismissDirection.endToStart,
              background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.7), borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.delete_outline, color: Colors.white)),
              confirmDismiss: (_) async => await showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Удалить?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Нет')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Да'))])),
              onDismissed: (_) => _deleteLesson(index, day),
              child: ListTile(
                leading: Icon(Icons.access_time_filled, color: Color(lesson.colorValue)),
                title: Text(lesson.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(lesson.time, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                trailing: IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white38), onPressed: () async {
                  final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditLessonPage(name: lesson.name, start: lesson.start, end: lesson.end, room: lesson.room, homework: lesson.homework, color: Color(lesson.colorValue))));
                  if (res != null && mounted) await _editLesson(index, res, day);
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
