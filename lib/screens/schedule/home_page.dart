// lib/screens/schedule/home_page.dart ГЛАВНАЯ СТРАНИЦА
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/app_drawer.dart';
import '../../../utils/helpers.dart';
import 'bell_schedule_page.dart';



class HomePage extends StatefulWidget {
  final String place;
  const HomePage({super.key, required this.place});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> schedule = [];
  String? currentLesson;
  String? nextLesson;
  String? remainingTime;
  Timer? _timer;
  bool isLoading = true;
  List<Map<String, dynamic>> localHistory = [];

  @override
  void initState() {
    super.initState();
    _loadLocalHistory();
    _loadSchedule();
  }

  Future<void> _loadLocalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('history_entries') ?? '[]';
    try {
      final List<dynamic> decoded = json.decode(raw);
      localHistory = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      localHistory = [];
    }
  }

  Future<void> _saveLocalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('history_entries', json.encode(localHistory));
  }

  Future<void> _addToHistory(String action, String lessonName) async {
    final entry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'action': action,
      'lessonName': lessonName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    localHistory.insert(0, entry);
    if (localHistory.length > 50) localHistory = localHistory.sublist(0, 50);
    await _saveLocalHistory();
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
      } else {
        schedule = [];
      }
    } catch (e) {
      debugPrint('Ошибка загрузки расписания: $e');
      schedule = [];
    }

    _updateNow();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateNow());
    setState(() => isLoading = false);
    _updateNow();
    debugPrint('✅ Расписание загружено: ${schedule.length} пар');
  }

  String _getDayName(DateTime date) {
    const days = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье'
    ];
    return days[date.weekday - 1];
  }

  String _normalizeTime(String t) {
    final parts = t.split(':');
    final h = parts[0].padLeft(2, '0');
    final m = parts[1].padLeft(2, '0');
    return '$h:$m';
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
    final nowMinutes = now.hour * 60 + now.minute;
    bool found = false;

    for (int i = 0; i < schedule.length; i++) {
      int startMinutes = _toMinutes(schedule[i]['start']);
      int endMinutes = _toMinutes(schedule[i]['end']);

      if (nowMinutes >= startMinutes && nowMinutes < endMinutes) {
        setState(() {
          currentLesson = schedule[i]['name'];
          nextLesson =
          (i + 1 < schedule.length) ? schedule[i + 1]['name'] : 'Конец пар';
          remainingTime = '${endMinutes - nowMinutes} мин до конца';
        });
        found = true;
        break;
      }
    }

    if (!found) {
      final first = schedule.first;
      final last = schedule.last;
      int firstStart = _toMinutes(first['start']);
      int lastEnd = _toMinutes(last['end']);

      if (nowMinutes < firstStart) {
        setState(() {
          currentLesson = 'Пары нет (до начала)';
          nextLesson = first['name'];
          remainingTime = 'До начала через ${firstStart - nowMinutes} мин';
        });
      } else if (nowMinutes >= lastEnd) {
        setState(() {
          currentLesson = 'Пары нет';
          nextLesson = 'Занятия закончились';
          remainingTime = null;
        });
      }
    }
  }

  int _toMinutes(String? t) {
    if (t == null) return 0;
    final parts = t.split(':');
    if (parts.length < 2) return 0;
    int h = int.tryParse(parts[0].trim()) ?? 0;
    int m = int.tryParse(parts[1].trim()) ?? 0;
    return h * 60 + m;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _getLessonProgressPct() {
    if (currentLesson == null || currentLesson == 'Пары нет') return 0;
    final now = TimeOfDay.now();
    final lst = schedule.firstWhere(
          (e) => e['name'] == currentLesson,
      orElse: () => {},
    );
    if (lst.isEmpty) return 0;
    final start = parseTime(lst['start']);
    final end = parseTime(lst['end']);
    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;
    final nowMin = now.hour * 60 + now.minute;
    if (nowMin <= startMin) return 0;
    if (nowMin >= endMin) return 100;
    return ((nowMin - startMin) / (endMin - startMin) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentWeekday = getCurrentWeekday();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Главная'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 3,
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      )
          : Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time,
                  color: isDark ? Colors.amberAccent : Colors.amber,
                  size: 80),
              const SizedBox(height: 15),
              Text(
                'Сегодня: $currentWeekday',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color:
                  isDark ? Colors.white70 : Colors.black.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                TimeOfDay.now().format(context),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 40),
              Card(
                color: isDark
                    ? const Color(0xFF1D1E33)
                    : Colors.white.withOpacity(0.95),
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 22, horizontal: 28),
                  child: Column(
                    children: [
                      Text(
                        'Сейчас:',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : Colors.black.withOpacity(0.7),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentLesson ?? 'Загрузка...',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (remainingTime != null)
                        Text(
                          remainingTime!,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Divider(),
                      Text(
                        'Следующая: ${nextLesson ?? '-'}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _getLessonProgressPct() / 100,
                        color: Colors.amberAccent,
                        backgroundColor:
                        isDark ? Colors.white12 : Colors.black12,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 8),
                      if (currentLesson != null && currentLesson != 'Пары нет') ...[
                        const SizedBox(height: 8),
                        Builder(
                          builder: (_) {
                            final lesson = schedule.firstWhere(
                                  (e) => e['name'] == currentLesson,
                              orElse: () => {},
                            );
                            if (lesson.isEmpty) return const SizedBox.shrink();

                            final start = parseTime(lesson['start']);
                            final end = parseTime(lesson['end']);
                            final now = TimeOfDay.now();

                            final startMin = start.hour * 60 + start.minute;
                            final endMin = end.hour * 60 + end.minute;
                            final nowMin = now.hour * 60 + now.minute;

                            final passed = (nowMin - startMin).clamp(0, endMin - startMin);
                            final remaining = (endMin - nowMin).clamp(0, endMin - startMin);

                            return Text(
                              'Прошло $passed мин · Осталось $remaining мин',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.schedule, color: Colors.black),
                label: const Text(
                  'Посмотреть расписание',
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BellSchedulePage(place: widget.place),
                    ),
                  ).then((_) => _loadSchedule());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}