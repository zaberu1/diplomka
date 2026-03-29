// lib/services/history_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const String _historyKey = 'history_entries';
  static const int _maxHistoryEntries = 100;

  static Future<void> addHistoryEntry({
    required String action, // 'added', 'edited', 'deleted'
    required String lessonName,
    required String place,
    Map<String, dynamic>? changes, // Конкретные изменения полей
    Map<String, dynamic>? oldData, // Старые данные (для сравнения)
    Map<String, dynamic>? newData, // Новые данные (для сравнения)
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey) ?? '[]';

    try {
      final List<dynamic> decoded = json.decode(raw);
      final List<Map<String, dynamic>> history = decoded
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final newEntry = {
        'action': action,
        'lessonName': lessonName,
        'place': place,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'changes': changes ?? {},
        'oldData': oldData ?? {},
        'newData': newData ?? {},
      };

      history.insert(0, newEntry);

      // Ограничиваем количество записей
      if (history.length > _maxHistoryEntries) {
        history.removeRange(_maxHistoryEntries, history.length);
      }

      await prefs.setString(_historyKey, json.encode(history));
    } catch (e) {
      // В случае ошибки создаем новую историю
      final newHistory = [
        {
          'action': action,
          'lessonName': lessonName,
          'place': place,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'changes': changes ?? {},
          'oldData': oldData ?? {},
          'newData': newData ?? {},
        }
      ];
      await prefs.setString(_historyKey, json.encode(newHistory));
    }
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey) ?? '[]';

    try {
      final List<dynamic> decoded = json.decode(raw);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}