// lib/screens/teacher/group_schedule_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/lesson_model.dart';
import '../schedule/edit_lesson_page.dart';

class GroupSchedulePage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupSchedulePage({super.key, required this.groupId, required this.groupName});

  @override
  State<GroupSchedulePage> createState() => _GroupSchedulePageState();
}

class _GroupSchedulePageState extends State<GroupSchedulePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late int selectedDayIndex;

  @override
  void initState() {
    super.initState();
    selectedDayIndex = DateTime.now().weekday - 1;
    if (selectedDayIndex > 5 || selectedDayIndex < 0) selectedDayIndex = 0;
  }

  final List<String> days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];

  // Вспомогательный метод для безопасного получения расписания
  Map<String, dynamic> _getSafeSchedule(Map<String, dynamic>? data) {
    final raw = data?['schedule'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return {}; // Если это список [] или null, возвращаем пустой объект {}
  }

  Future<void> _addLesson() async {
    final result = await Navigator.push<Lesson>(
      context,
      MaterialPageRoute(
        builder: (_) => const EditLessonPage(name: '', start: '08:00', end: '09:30'),
      ),
    );

    if (result != null) {
      final docRef = _db.collection('groups').doc(widget.groupId);
      final doc = await docRef.get();
      Map<String, dynamic> schedule = _getSafeSchedule(doc.data() as Map<String, dynamic>?);
      
      String dayKey = selectedDayIndex.toString();
      List<dynamic> dayLessons = List.from(schedule[dayKey] ?? []);
      dayLessons.add(result.toMap());
      
      dayLessons.sort((a, b) => a['start'].compareTo(b['start']));
      schedule[dayKey] = dayLessons;
      
      await docRef.update({'schedule': schedule});
    }
  }

  Future<void> _editLesson(int index, Lesson lesson) async {
    final result = await Navigator.push<Lesson>(
      context,
      MaterialPageRoute(
        builder: (_) => EditLessonPage(
          name: lesson.name,
          start: lesson.start,
          end: lesson.end,
          room: lesson.room,
          homework: lesson.homework,
          color: Color(lesson.colorValue),
        ),
      ),
    );

    if (result != null) {
      final docRef = _db.collection('groups').doc(widget.groupId);
      final doc = await docRef.get();
      Map<String, dynamic> schedule = _getSafeSchedule(doc.data() as Map<String, dynamic>?);
      
      String dayKey = selectedDayIndex.toString();
      List<dynamic> dayLessons = List.from(schedule[dayKey] ?? []);
      dayLessons[index] = result.toMap();
      
      dayLessons.sort((a, b) => a['start'].compareTo(b['start']));
      schedule[dayKey] = dayLessons;
      
      await docRef.update({'schedule': schedule});
    }
  }

  Future<void> _deleteLesson(int index) async {
    final docRef = _db.collection('groups').doc(widget.groupId);
    final doc = await docRef.get();
    Map<String, dynamic> schedule = _getSafeSchedule(doc.data() as Map<String, dynamic>?);
    
    String dayKey = selectedDayIndex.toString();
    List<dynamic> dayLessons = List.from(schedule[dayKey] ?? []);
    dayLessons.removeAt(index);
    
    schedule[dayKey] = dayLessons;
    await docRef.update({'schedule': schedule});
  }

  Widget _buildGlassCard({required Widget child, double opacity = 0.05}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
        title: Text(widget.groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(days.length, (index) {
                      bool isSelected = selectedDayIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => selectedDayIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.amber : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            days[index],
                            style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: _db.collection('groups').doc(widget.groupId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final schedule = _getSafeSchedule(data);
                      final dayLessons = (schedule[selectedDayIndex.toString()] ?? []) as List;

                      if (dayLessons.isEmpty) {
                        return const Center(child: Text('Пар нет', style: TextStyle(color: Colors.white24, fontSize: 18)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: dayLessons.length,
                        itemBuilder: (context, index) {
                          final lesson = Lesson.fromMap(dayLessons[index]);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildGlassCard(
                              child: ListTile(
                                leading: Container(
                                  width: 4, height: 40,
                                  decoration: BoxDecoration(color: Color(lesson.colorValue), borderRadius: BorderRadius.circular(2)),
                                ),
                                title: Text(lesson.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${lesson.start} - ${lesson.end}${lesson.room != null ? " • Каб. ${lesson.room}" : ""}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.amber), onPressed: () => _editLesson(index, lesson)),
                                    IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: () => _deleteLesson(index)),
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
                
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton.icon(
                    onPressed: _addLesson,
                    icon: const Icon(Icons.add, color: Colors.black),
                    label: const Text('Добавить пару', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
