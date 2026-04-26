// lib/services/notification_service.dart
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/lesson_model.dart';
import 'shared_prefs_service.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const _channel = MethodChannel('com.example.zvonok/timezone');
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  static Future<void> init() async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;
    
    // Инициализируем в фоне
    Future.microtask(() async {
      try {
        tz_data.initializeTimeZones();
        final String? timeZoneName = await _channel
            .invokeMethod<String>('getLocalTimezone')
            .timeout(const Duration(seconds: 1));
            
        if (timeZoneName != null) {
          tz.setLocalLocation(tz.getLocation(timeZoneName));
        } else {
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
      } catch (e) {
        debugPrint('Timezone init error: $e');
      }

      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );

      try {
        await _notificationsPlugin.initialize(initializationSettings);
        _isInitialized = true;
        debugPrint('Notifications system ready');
      } catch (e) {
        debugPrint('Notifications init error: $e');
      } finally {
        _isInitializing = false;
      }
    });
  }

  static void scheduleNotifications(List<Lesson> lessons) {
    // ВАЖНО: Убираем await и Future, делаем метод синхронным для вызывающего кода
    // Чтобы интерфейс не ждал планирования уведомлений
    _scheduleInternal(lessons);
  }

  static Future<void> _scheduleInternal(List<Lesson> lessons) async {
    if (!_isInitialized) await init();
    if (!_isInitialized) return;

    try {
      // Это тяжелая операция на Android, запускаем без блокировки UI
      await _notificationsPlugin.cancelAll();

      if (!SharedPrefsService.getRemindersEnabled()) return;

      final notifyStart = SharedPrefsService.getNotifyStart();
      final notifyEnd = SharedPrefsService.getNotifyEnd();
      final minsStart = SharedPrefsService.getReminderMinutesStart();
      final minsEnd = SharedPrefsService.getReminderMinutesEnd();

      for (int i = 0; i < lessons.length; i++) {
        final lesson = lessons[i];
        if (lesson.start.isEmpty || lesson.end.isEmpty) continue;

        if (notifyStart) {
          _planOne(i * 100 + 1, '🔔 Начало: ${lesson.name}', lesson.start, minsStart, lesson.room);
        }
        if (notifyEnd) {
          _planOne(i * 100 + 2, '🏁 Конец: ${lesson.name}', lesson.end, minsEnd, null);
        }
      }
    } catch (e) {
      debugPrint('Internal schedule error: $e');
    }
  }

  static void _planOne(int id, String title, String timeStr, int minsBefore, String? room) async {
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute)
          .subtract(Duration(minutes: minsBefore));

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final body = room != null ? 'В $timeStr, Каб. $room' : 'В $timeStr';

      _notificationsPlugin.zonedSchedule(
        id, title, body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'zvonok_reminders', 'Уроки',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      ).catchError((e) => debugPrint('ZonedSchedule error: $e'));
    } catch (_) {}
  }
}
