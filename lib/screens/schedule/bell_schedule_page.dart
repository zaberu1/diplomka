// lib/screens/schedule/bell_schedule_page.dart
import 'package:flutter/material.dart';
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

  final List<String> days = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота'
  ];

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
    setState(() {});
  }

  Future<void> _loadSchedule() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('schedules')
        .doc(widget.place)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final items = data['items'] as List;
      schedule = items.map((item) => Lesson.fromMap(item)).toList();
    } else {
      await _generateSchedule();
    }
    setState(() {});
  }

  Future<void> _loadWeeklySchedule() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('schedules')
        .doc('${widget.place}_weekly')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      weeklySchedule = Map<String, List<Lesson>>.fromEntries(
        (data['days'] as Map<String, dynamic>).entries.map((entry) {
          final day = entry.key;
          final list = (entry.value as List)
              .map((e) => Lesson.fromMap(e))
              .toList();
          return MapEntry(day, list);
        }),
      );
    } else {
      await _generateWeeklySchedule();
    }
    setState(() {});
  }

  Future<void> _generateSchedule() async {
    List<Lesson> generated = [];
    TimeOfDay current = widget.place == 'school'
        ? const TimeOfDay(hour: 8, minute: 0)
        : const TimeOfDay(hour: 9, minute: 0);

    for (int i = 1; i <= 7; i++) {
      final end = TimeOfDay(
          hour: (current.hour + ((current.minute + 45) ~/ 60)) % 24,
          minute: (current.minute + 45) % 60);
      generated.add(Lesson(
        name: widget.place == 'school' ? '$i урок' : '$i пара',
        start: formatTime24(current),
        end: formatTime24(end),
      ));
      current = TimeOfDay(
          hour: (end.hour + ((end.minute + 10) ~/ 60)) % 24,
          minute: (end.minute + 10) % 60);
    }
    schedule = generated;
    await _saveSchedule();
  }

  Future<void> _generateWeeklySchedule() async {
    for (var day in days) {
      List<Lesson> generated = [];
      TimeOfDay current = widget.place == 'school'
          ? const TimeOfDay(hour: 8, minute: 0)
          : const TimeOfDay(hour: 9, minute: 0);

      for (int i = 1; i <= 7; i++) {
        final end = TimeOfDay(
            hour: (current.hour + ((current.minute + 45) ~/ 60)) % 24,
            minute: (current.minute + 45) % 60);
        generated.add(Lesson(
          name: widget.place == 'school' ? '$i урок' : '$i пара',
          start: formatTime24(current),
          end: formatTime24(end),
        ));
        current = TimeOfDay(
            hour: (end.hour + ((end.minute + 10) ~/ 60)) % 24,
            minute: (end.minute + 10) % 60);
      }
      weeklySchedule[day] = generated;
    }
    await _saveWeeklySchedule();
  }

  Future<void> _saveSchedule() async {
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('schedules')
        .doc(widget.place)
        .set({'items': schedule.map((lesson) => lesson.toMap()).toList()});
  }

  Future<void> _saveWeeklySchedule() async {
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('schedules')
        .doc('${widget.place}_weekly')
        .set({
      'days': Map.fromEntries(
          weeklySchedule.entries.map((entry) =>
              MapEntry(entry.key, entry.value.map((lesson) => lesson.toMap()).toList())
          )
      )
    });
  }

  Future<void> _addLesson(Lesson newLesson, [String? day]) async {
    setState(() {
      if (sameEveryday) {
        schedule.add(newLesson);
        schedule.sort((a, b) => compareTime(a.start, b.start));
      } else {
        final currentDay = day ?? days[_tabController.index];
        weeklySchedule[currentDay] ??= [];
        weeklySchedule[currentDay]!.add(newLesson);
        weeklySchedule[currentDay]!.sort((a, b) => compareTime(a.start, b.start));
      }
    });

    // Добавляем запись в историю
    await HistoryService.addHistoryEntry(
      action: 'added',
      lessonName: newLesson.name,
      place: widget.place,
    );

    if (sameEveryday) {
      await _saveSchedule();
    } else {
      await _saveWeeklySchedule();
    }
  }

  Future<void> _editLesson(int index, Lesson updatedLesson, [String? day]) async {
    final oldLesson = sameEveryday ? schedule[index] : weeklySchedule[day ?? days[_tabController.index]]![index];

    setState(() {
      if (sameEveryday) {
        schedule[index] = updatedLesson;
        schedule.sort((a, b) => compareTime(a.start, b.start));
      } else {
        weeklySchedule[day ?? days[_tabController.index]]![index] = updatedLesson;
        weeklySchedule[day ?? days[_tabController.index]]!.sort((a, b) => compareTime(a.start, b.start));
      }
    });

    // Добавляем запись в историю только если имя изменилось
    if (oldLesson.name != updatedLesson.name) {
      await HistoryService.addHistoryEntry(
        action: 'edited',
        lessonName: updatedLesson.name,
        place: widget.place,
      );
    }

    if (sameEveryday) {
      await _saveSchedule();
    } else {
      await _saveWeeklySchedule();
    }
  }

  Future<void> _deleteLesson(int index, [String? day]) async {
    final lessonToDelete = sameEveryday ? schedule[index] : weeklySchedule[day ?? days[_tabController.index]]![index];

    setState(() {
      if (sameEveryday) {
        schedule.removeAt(index);
      } else {
        weeklySchedule[day ?? days[_tabController.index]]!.removeAt(index);
      }
    });

    // Добавляем запись в историю
    await HistoryService.addHistoryEntry(
      action: 'deleted',
      lessonName: lessonToDelete.name,
      place: widget.place,
    );

    if (sameEveryday) {
      await _saveSchedule();
    } else {
      await _saveWeeklySchedule();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Пара "${lessonToDelete.name}" удалена'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Расписание (${widget.place == "school" ? "Школа" : "Колледж"})',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1C2C) : Colors.amber.shade100,
        elevation: 3,
        actions: [
          _buildUserAvatar(context),
          const SizedBox(width: 16),
        ],
        bottom: sameEveryday
            ? null
            : PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: isDark
                ? const Color(0xFF2A2D3E)
                : Colors.amber.withOpacity(0.2),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.amberAccent,
              unselectedLabelColor:
              isDark ? Colors.white70 : Colors.black54,
              indicator: BoxDecoration(
                color: Colors.amberAccent.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              tabs: [for (var d in days) Tab(text: d)],
            ),
          ),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newLesson = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EditLessonPage(
                name: '',
                start: '08:00',
                end: '08:45',
              ),
            ),
          );
          if (newLesson != null && mounted) {
            await _addLesson(newLesson);
          }
        },
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Добавить', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.amberAccent,
      ),
      body: sameEveryday
          ? _buildScheduleList(schedule)
          : TabBarView(
        controller: _tabController,
        children: [
          for (var d in days)
            _buildScheduleList(weeklySchedule[d] ?? [], d)
        ],
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
      },
      child: CircleAvatar(
        radius: 18,
        backgroundColor: isDark ? Colors.amber : Colors.amber.shade100,
        child: user?.photoURL != null
            ? CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(user!.photoURL!),
        )
            : Icon(
          Icons.person,
          size: 20,
          color: isDark ? Colors.black : Colors.amber.shade800,
        ),
      ),
    );
  }

  Widget _buildScheduleList(List<Lesson> lessons, [String? day]) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (lessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 80,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              'Расписание пусто',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите + чтобы добавить пару',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          final color = Color(lesson.colorValue);

          return Dismissible(
            key: ValueKey('${lesson.name}-$index-${day ?? ''}'),
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Удалить пару?'),
                  content: Text('Вы уверены, что хотите удалить пару "${lesson.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      child: const Text('Удалить', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              return result ?? false;
            },
            onDismissed: (_) => _deleteLesson(index, day),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: isDark
                    ? const Color(0xFF1D1E33)
                    : Colors.white.withOpacity(0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.access_time, color: color),
                  ),
                  title: Text(
                    lesson.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    lesson.time,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.edit, color: color),
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditLessonPage(
                            name: lesson.name,
                            start: lesson.start,
                            end: lesson.end,
                            room: lesson.room,
                            homework: lesson.homework,
                            color: color,
                          ),
                        ),
                      );

                      if (updated != null && mounted) {
                        await _editLesson(index, updated, day);
                      }
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}