// lib/utils/helpers.dart
import 'package:flutter/material.dart';

// Форматирование времени в 24-часовом формате
String formatTime24(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

// Парсинг времени из строки
TimeOfDay parseTime(String t) {
  final parts = t.split(':');
  final h = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  return TimeOfDay(hour: h, minute: m);
}

// Конвертация времени в минуты
int timeToMinutes(String time) {
  final parts = time.split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return h * 60 + m;
}

// Конвертация TimeOfDay в минуты
int timeOfDayToMinutes(TimeOfDay time) {
  return time.hour * 60 + time.minute;
}

// Получение текущего дня недели
String getCurrentWeekday() {
  final now = DateTime.now();
  const days = ['Воскресенье', 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота'];
  return days[now.weekday % 7];
}

// Получение короткого названия дня недели
String getShortWeekday(DateTime date) {
  const days = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
  return days[date.weekday % 7];
}

// Нормализация времени (добавление ведущих нулей)
String normalizeTime(String t) {
  final parts = t.split(':');
  final h = parts[0].padLeft(2, '0');
  final m = parts[1].padLeft(2, '0');
  return '$h:$m';
}

// Расчет прогресса урока в процентах
int calculateLessonProgress(String startTime, String endTime) {
  final now = TimeOfDay.now();
  final start = parseTime(startTime);
  final end = parseTime(endTime);

  final startMin = timeOfDayToMinutes(start);
  final endMin = timeOfDayToMinutes(end);
  final nowMin = timeOfDayToMinutes(now);

  if (nowMin <= startMin) return 0;
  if (nowMin >= endMin) return 100;

  return ((nowMin - startMin) / (endMin - startMin) * 100).round();
}

// Расчет оставшегося времени урока
Map<String, int> calculateLessonTimeDetails(String startTime, String endTime) {
  final now = TimeOfDay.now();
  final start = parseTime(startTime);
  final end = parseTime(endTime);

  final startMin = timeOfDayToMinutes(start);
  final endMin = timeOfDayToMinutes(end);
  final nowMin = timeOfDayToMinutes(now);

  final passed = (nowMin - startMin).clamp(0, endMin - startMin);
  final remaining = (endMin - nowMin).clamp(0, endMin - startMin);

  return {'passed': passed, 'remaining': remaining};
}

// Сравнение времени для сортировки
int compareTime(String a, String b) {
  final totalA = timeToMinutes(a);
  final totalB = timeToMinutes(b);
  return totalA.compareTo(totalB);
}

// Проверка, находится ли текущее время в промежутке урока
bool isCurrentTimeInLesson(String startTime, String endTime) {
  final now = TimeOfDay.now();
  final start = parseTime(startTime);
  final end = parseTime(endTime);

  final nowMin = timeOfDayToMinutes(now);
  final startMin = timeOfDayToMinutes(start);
  final endMin = timeOfDayToMinutes(end);

  return nowMin >= startMin && nowMin < endMin;
}

// Получение индикатора текущего урока
String getCurrentLessonIndicator(List<Map<String, dynamic>> schedule) {
  if (schedule.isEmpty) return 'Расписание не настроено';

  for (final lesson in schedule) {
    if (isCurrentTimeInLesson(lesson['start'], lesson['end'])) {
      return lesson['name'];
    }
  }

  return 'Пары нет';
}

// Форматирование длительности в читаемый вид
String formatDuration(int totalMinutes) {
  if (totalMinutes < 60) {
    return '$totalMinutes мин';
  } else {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return minutes > 0 ? '$hours ч $minutes мин' : '$hours ч';
  }
}

// Создание градиента на основе темы
List<Color> getGradientColors(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark
      ? [const Color(0xFF2A2D3E), const Color(0xFF1A1C2C)]
      : [Colors.amber.shade100, Colors.orange.shade100];
}