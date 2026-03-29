// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'ZvonOK';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color primaryColor = Colors.amber;
  static const Color darkBackground = Color(0xFF0A0E21);
  static const Color lightBackground = Color(0xFFF3F4F6);
  static const Color cardDark = Color(0xFF1D1E33);
  static const Color cardLight = Colors.white;

  // Time settings
  static const int lessonDuration = 45; // minutes
  static const int breakDuration = 10; // minutes
  static const int defaultReminderMinutes = 5;

  // Default schedule times
  static const TimeOfDay schoolStartTime = TimeOfDay(hour: 8, minute: 0);
  static const TimeOfDay collegeStartTime = TimeOfDay(hour: 9, minute: 0);

  // Weekdays
  static const List<String> weekdays = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье'
  ];

  static const List<String> shortWeekdays = [
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс'
  ];

  // Lesson colors
  static const List<Color> lessonColors = [
    Color(0xFF4285F4), // Blue
    Color(0xFF34A853), // Green
    Color(0xFFAA46BB), // Purple
    Color(0xFFFB8C00), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF7E7E7E), // Grey
    Color(0xFFFFC107), // Amber
    Color(0xFF00BCD4), // Cyan
  ];

  // Place types
  static const Map<String, String> placeNames = {
    'school': 'Школа',
    'college': 'Колледж',
  };

  static const Map<String, IconData> placeIcons = {
    'school': Icons.school_outlined,
    'college': Icons.school_rounded,
  };

  // Animation durations
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration pageTransitionDuration = Duration(milliseconds: 500);
  static const Duration buttonAnimationDuration = Duration(milliseconds: 200);

  // Firestore collections
  static const String usersCollection = 'users';
  static const String schedulesCollection = 'schedules';

  // SharedPreferences keys
  static const String themeKey = 'theme_mode';
  static const String placeKey = 'selected_place';
  static const String scheduleModeKey = 'same_schedule';
  static const String remindersEnabledKey = 'reminders_enabled';
  static const String reminderMinutesKey = 'reminder_minutes';
  static const String historyKey = 'history_entries';

  // Text constants
  static const String appDescription = 'Расписание звонков';
  static const String currentLessonText = 'Сейчас:';
  static const String nextLessonText = 'Следующая:';
  static const String noLessonText = 'Пары нет';
  static const String lessonsEndedText = 'Занятия закончились';
  static const String loadingText = 'Загрузка...';
}