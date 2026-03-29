// lib/screens/settings/search_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';
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
        debugPrint('Error loading lessons: $e');
      }
    }
    setState(() => isLoading = false);
  }

  List<Map<String, dynamic>> get searchResults {
    if (query.isEmpty) return [];

    return lessons.where((lesson) {
      final name = (lesson['name'] ?? '').toString().toLowerCase();
      final room = (lesson['room'] ?? '').toString().toLowerCase();
      final homework = (lesson['homework'] ?? '').toString().toLowerCase();
      final searchTerm = query.toLowerCase();

      return name.contains(searchTerm) ||
          room.contains(searchTerm) ||
          homework.contains(searchTerm);
    }).toList();
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorValue = lesson['color'] != null
        ? Color(int.tryParse(lesson['color'].toString()) ?? 0xFFFFC107)
        : const Color(0xFFFFC107);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isDark ? const Color(0xFF1D1E33) : Colors.white,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorValue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.school, color: colorValue),
        ),
        title: Text(
          lesson['name']?.toString() ?? 'Без названия',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${lesson['start']} - ${lesson['end']}',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            if (lesson['room'] != null && lesson['room'].toString().isNotEmpty)
              Text(
                'Аудитория: ${lesson['room']}',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black45,
                  fontSize: 12,
                ),
              ),
            if (lesson['homework'] != null && lesson['homework'].toString().isNotEmpty)
              Text(
                'ДЗ: ${lesson['homework']}',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black45,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        onTap: () {
          // Можно добавить навигацию к редактированию урока
          _showLessonDetails(lesson, context);
        },
      ),
    );
  }

  void _showLessonDetails(Map<String, dynamic> lesson, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lesson['name']?.toString() ?? 'Без названия'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Время: ${lesson['start']} - ${lesson['end']}'),
            if (lesson['room'] != null) Text('Аудитория: ${lesson['room']}'),
            if (lesson['homework'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text('Домашнее задание:'),
                  Text(lesson['homework'].toString()),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = searchResults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 2,
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Поиск по предмету, аудитории или ДЗ...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1D1E33) : Colors.grey.shade100,
              ),
            ),
          ),
          if (isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            )
          else if (query.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 80,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Введите запрос для поиска',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ищите по названию предмета,\nаудитории или домашнему заданию',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (results.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ничего не найдено',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Попробуйте изменить запрос',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Найдено: ${results.length}',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (context, index) =>
                              _buildLessonCard(results[index], context),
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