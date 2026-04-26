// lib/screens/schedule/bell_schedule_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/helpers.dart';
import '../../models/lesson_model.dart';
import '../../services/history_service.dart';
import '../../services/database_service.dart';
import '../../services/shared_prefs_service.dart';
import '../../services/notification_service.dart';
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
  bool isReadOnly = false; 
  late TabController _tabController;
  StreamSubscription? _weeklySubscription;

  final List<String> daysLong = const ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота'];
  final List<String> daysShort = const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: daysLong.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadSettingsAndSchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weeklySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSettingsAndSchedule() async {
    try {
      final userDataDoc = await databaseService.getUserData();
      final userData = userDataDoc.data() as Map<String, dynamic>? ?? {};
      final appMode = userData['appMode'] ?? 'manual';
      final groupId = userData['groupId'];

      _weeklySubscription?.cancel();

      if (appMode == 'join' && groupId != null) {
        isReadOnly = true;
        sameEveryday = false;
        
        _weeklySubscription = databaseService.getGroupWeeklyScheduleStream(groupId).listen((newWeekly) {
          if (mounted) {
            setState(() {
              weeklySchedule = newWeekly;
              // Планируем уведомления для группы в фоне
              final allLessons = newWeekly.values.expand((x) => x).toList();
              NotificationService.scheduleNotifications(allLessons);
            });
          }
        });
      } else {
        isReadOnly = false;
        sameEveryday = SharedPrefsService.getScheduleMode();
        if (sameEveryday) {
          schedule = await databaseService.getSchedule(widget.place, isWeekly: false);
          NotificationService.scheduleNotifications(schedule);
        } else {
          weeklySchedule = await databaseService.getFullWeeklySchedule(widget.place);
          final allLessons = weeklySchedule.values.expand((x) => x).toList();
          NotificationService.scheduleNotifications(allLessons);
        }
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _addLesson(Lesson newLesson) async {
    if (isReadOnly || isSaving) return;
    
    final day = sameEveryday ? null : daysLong[_tabController.index];
    
    setState(() { 
      if (sameEveryday) { 
        schedule.add(newLesson); 
        schedule.sort((a, b) => compareTime(a.start, b.start)); 
      } else { 
        final d = day!;
        weeklySchedule[d] ??= []; 
        weeklySchedule[d]!.add(newLesson); 
        weeklySchedule[d]!.sort((a, b) => compareTime(a.start, b.start)); 
      } 
    });

    try {
      // Сохраняем в облако БЕЗ блокировки интерфейса на долгое время
      databaseService.saveSchedule(
        widget.place, 
        sameEveryday ? schedule : weeklySchedule[day]!, 
        isWeekly: !sameEveryday,
        day: day
      );
      
      // Планируем уведомления асинхронно
      final allLessons = sameEveryday ? schedule : weeklySchedule.values.expand((x) => x).toList();
      NotificationService.scheduleNotifications(allLessons);
      
      HistoryService.addHistoryEntry(action: 'added', lessonName: newLesson.name, place: widget.place);
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  Future<void> _editLesson(int index, Lesson updated) async {
    if (isReadOnly || isSaving) return;
    
    final day = sameEveryday ? null : daysLong[_tabController.index];

    setState(() {
      if (sameEveryday) { 
        schedule[index] = updated; 
        schedule.sort((a, b) => compareTime(a.start, b.start)); 
      } else { 
        final d = day!;
        weeklySchedule[d]![index] = updated; 
        weeklySchedule[d]!.sort((a, b) => compareTime(a.start, b.start)); 
      }
    });

    try {
      databaseService.saveSchedule(
        widget.place, 
        sameEveryday ? schedule : weeklySchedule[day]!, 
        isWeekly: !sameEveryday,
        day: day
      );
      
      final allLessons = sameEveryday ? schedule : weeklySchedule.values.expand((x) => x).toList();
      NotificationService.scheduleNotifications(allLessons);
      
      HistoryService.addHistoryEntry(action: 'edited', lessonName: updated.name, place: widget.place);
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  Future<void> _deleteLesson(int index) async {
    if (isReadOnly || isSaving) return;
    
    final day = sameEveryday ? null : daysLong[_tabController.index];
    final lesson = sameEveryday ? schedule[index] : weeklySchedule[day]![index];

    setState(() {
      if (sameEveryday) {
        schedule.removeAt(index);
      } else {
        weeklySchedule[day]!.removeAt(index);
      }
    });

    try {
      databaseService.saveSchedule(
        widget.place, 
        sameEveryday ? schedule : weeklySchedule[day]!, 
        isWeekly: !sameEveryday,
        day: day
      );
      
      final allLessons = sameEveryday ? schedule : weeklySchedule.values.expand((x) => x).toList();
      NotificationService.scheduleNotifications(allLessons);
      
      HistoryService.addHistoryEntry(action: 'deleted', lessonName: lesson.name, place: widget.place);
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  Widget _buildGlassCard({required Widget child, double opacity = 0.05}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24), 
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), 
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(opacity) : Colors.white.withOpacity(0.7), 
            borderRadius: BorderRadius.circular(24), 
            border: Border.all(color: Colors.white.withOpacity(0.1))
          ), 
          child: child
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      drawer: const AppDrawer(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.place == "school" ? "Расписание" : "Пары", 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [_buildUserAvatar(context), const SizedBox(width: 16)],
      ),
      floatingActionButton: (isReadOnly) ? null : FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditLessonPage(name: '', start: '08:00', end: '08:45')));
          if (res != null && mounted) await _addLesson(res);
        },
        icon: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
        label: const Text('ДОБАВИТЬ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 10,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, 
                end: Alignment.bottomRight, 
                colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)]
              )
            )
          ),
          SafeArea(
            child: Column(
              children: [
                if (!sameEveryday) _buildCustomTabBar(primaryColor, isDark),
                Expanded(
                  child: sameEveryday 
                    ? _buildScheduleList(schedule) 
                    : TabBarView(
                        controller: _tabController, 
                        children: daysLong.map((d) => _buildScheduleList(weeklySchedule[d] ?? [], d)).toList(),
                      ),
                ),
              ],
            ),
          ),
          if (isSaving)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Colors.amber)),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(Color primaryColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: _buildGlassCard(
        opacity: 0.08,
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(daysShort.length, (index) {
              bool isSelected = _tabController.index == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _tabController.animateTo(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: isSelected 
                        ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] 
                        : [],
                    ),
                    child: Center(
                      child: Text(
                        daysShort[index],
                        style: TextStyle(
                          color: isSelected ? Colors.black : (isDark ? Colors.white54 : Colors.black54),
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
      child: CircleAvatar(radius: 18, backgroundColor: Colors.white10, backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null, child: user?.photoURL == null ? Icon(Icons.person, size: 20, color: primaryColor) : null),
    );
  }

  Widget _buildScheduleList(List<Lesson> lessons, [String? day]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (lessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 80, color: primaryColor.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('На этот день занятий нет', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        final lessonColor = Color(lesson.colorValue);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Dismissible(
            key: ValueKey('${lesson.name}-$index-${day ?? ''}'),
            direction: isReadOnly ? DismissDirection.none : DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
            ),
            confirmDismiss: (_) async => await showDialog(context: context, builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1C2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Удалить пару?', style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ОТМЕНА', style: TextStyle(color: Colors.white38))),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('УДАЛИТЬ')),
              ],
            )),
            onDismissed: (_) => _deleteLesson(index),
            child: _buildLessonCard(lesson, lessonColor, isDark, day, index),
          ),
        );
      },
    );
  }

  Widget _buildLessonCard(Lesson lesson, Color accent, bool isDark, String? day, int index) {
    return _buildGlassCard(
      opacity: 0.06,
      child: InkWell(
        onTap: (isReadOnly) ? null : () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditLessonPage(name: lesson.name, start: lesson.start, end: lesson.end, room: lesson.room, homework: lesson.homework, color: Color(lesson.colorValue))));
          if (res != null && mounted) await _editLesson(index, res);
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.start, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  Text(lesson.end, style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 20),
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.name, 
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    if (lesson.room != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 12, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              'Кабинет ${lesson.room}', 
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w500)
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (!isReadOnly)
                Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white12 : Colors.black12),
            ],
          ),
        ),
      ),
    );
  }
}
