// lib/screens/settings/statistics_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  List<Map<String, dynamic>> lessons = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final place = prefs.getString('selected_place') ?? 'school';
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('schedules')
            .doc(place)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            lessons = (data['items'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      } catch (e) {
        print('Error loading lessons: $e');
      }
    }
    setState(() => isLoading = false);
  }

  Map<String, dynamic> _computeStats() {
    if (lessons.isEmpty) {
      return {
        'total': 0,
        'unique': 0,
        'avg': '0.0',
        'mostCommon': '—',
        'totalDuration': 0,
        'avgDuration': '0.0'
      };
    }

    final total = lessons.length;
    final subjects = {...lessons.map((e) => e['name'] as String)};
    final unique = subjects.length;
    final avgPerDay = total / 5; // Предполагаем 5 учебных дней

    // Подсчет самого частого предмета
    final subjectCount = <String, int>{};
    for (final lesson in lessons) {
      final name = lesson['name'] as String;
      subjectCount[name] = (subjectCount[name] ?? 0) + 1;
    }
    final mostCommon = subjectCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    // Расчет длительности
    int totalDuration = 0;
    for (final lesson in lessons) {
      final start = _parseTime(lesson['start']);
      final end = _parseTime(lesson['end']);
      totalDuration += (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
    }
    final avgDuration = totalDuration / total;

    return {
      'total': total,
      'unique': unique,
      'avg': avgPerDay.toStringAsFixed(1),
      'mostCommon': mostCommon,
      'totalDuration': totalDuration,
      'avgDuration': avgDuration.toStringAsFixed(1)
    };
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? '$hours ч $minutes мин' : '$hours ч';
    } else {
      return '$minutes мин';
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _computeStats();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 2,
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Общая статистика',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Всего пар',
              '${stats['total']}',
              Icons.list_alt,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Уникальных предметов',
              '${stats['unique']}',
              Icons.category,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'В среднем в день',
              '${stats['avg']}',
              Icons.today,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Самый частый предмет',
              '${stats['mostCommon']}',
              Icons.star,
              Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Общая длительность',
              _formatDuration(stats['totalDuration']),
              Icons.access_time,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Средняя длительность',
              '${stats['avgDuration']} мин',
              Icons.timer,
              Colors.red,
            ),
            const SizedBox(height: 20),
            if (lessons.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 80,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Нет данных для статистики',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}