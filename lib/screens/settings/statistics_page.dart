// lib/screens/settings/statistics_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
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
          if (mounted) {
            setState(() {
              lessons = (data['items'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading stats: $e');
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  Map<String, dynamic> _computeStats() {
    if (lessons.isEmpty) {
      return {'total': 0, 'unique': 0, 'avg': '0.0', 'mostCommon': '—', 'totalDuration': 0, 'avgDuration': '0.0'};
    }
    final total = lessons.length;
    final unique = {...lessons.map((e) => e['name'] as String)}.length;
    final subjectCount = <String, int>{};
    for (final l in lessons) {
      final name = l['name'] as String;
      subjectCount[name] = (subjectCount[name] ?? 0) + 1;
    }
    final mostCommon = subjectCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    int totalDuration = 0;
    for (final l in lessons) {
      final start = _toMin(l['start']);
      final end = _toMin(l['end']);
      totalDuration += (end - start);
    }
    return {
      'total': total,
      'unique': unique,
      'avg': (total / 5).toStringAsFixed(1),
      'mostCommon': mostCommon,
      'totalDuration': totalDuration,
      'avgDuration': (totalDuration / total).toStringAsFixed(0)
    };
  }

  int _toMin(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  Widget _buildGlassStat(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = _computeStats();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Аналитика', style: TextStyle(fontWeight: FontWeight.bold)),
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
          Positioned(
            top: 100, right: -30,
            child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 80, spreadRadius: 20)])),
          ),
          
          isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Твои успехи', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text('Обзор твоей учебной нагрузки', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                      const SizedBox(height: 32),
                      
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                        children: [
                          _buildGlassStat('Всего пар', stats['total'].toString(), Icons.book_rounded, Colors.blueAccent),
                          _buildGlassStat('Предметов', stats['unique'].toString(), Icons.category_rounded, Colors.orangeAccent),
                          _buildGlassStat('В день', stats['avg'], Icons.calendar_view_day_rounded, Colors.greenAccent),
                          _buildGlassStat('Средняя пара', "${stats['avgDuration']} мин", Icons.timer_rounded, Colors.purpleAccent),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.amber.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('ЧАЩЕ ВСЕГО', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                                      Text(stats['mostCommon'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          'Статистика рассчитывается на основе\nтвоего текущего расписания',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : Colors.black26),
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
}
