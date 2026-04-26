// lib/services/shared_prefs_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPrefsService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // General Methods
  static Future<bool> setString(String key, String value) => _prefs!.setString(key, value);
  static String? getString(String key) => _prefs!.getString(key);

  static Future<bool> setBool(String key, bool value) => _prefs!.setBool(key, value);
  static bool? getBool(String key) => _prefs!.getBool(key);

  static Future<bool> setInt(String key, int value) => _prefs!.setInt(key, value);
  static int? getInt(String key) => _prefs!.getInt(key);

  // Specific Settings
  static Future<void> setTheme(String theme) => setString('theme_mode', theme);
  static String getTheme() => getString('theme_mode') ?? 'dark';

  static Future<void> setPlace(String place) => setString('selected_place', place);
  static String getPlace() => getString('selected_place') ?? 'school';

  static Future<void> setScheduleMode(bool sameEveryday) => setBool('same_schedule', sameEveryday);
  static bool getScheduleMode() => getBool('same_schedule') ?? true;

  static Future<void> setRemindersEnabled(bool enabled) => setBool('reminders_enabled', enabled);
  static bool getRemindersEnabled() => getBool('reminders_enabled') ?? true;

  static Future<void> setNotifyStart(bool enabled) => setBool('notify_start', enabled);
  static bool getNotifyStart() => getBool('notify_start') ?? true;

  static Future<void> setNotifyEnd(bool enabled) => setBool('notify_end', enabled);
  static bool getNotifyEnd() => getBool('notify_end') ?? true;

  static Future<void> setReminderMinutesStart(int minutes) => setInt('reminder_minutes_start', minutes);
  static int getReminderMinutesStart() => getInt('reminder_minutes_start') ?? 5;

  static Future<void> setReminderMinutesEnd(int minutes) => setInt('reminder_minutes_end', minutes);
  static int getReminderMinutesEnd() => getInt('reminder_minutes_end') ?? 5;

  static Future<void> setQuickNote(String note) => setString('quick_note', note);
  static String getQuickNote() => getString('quick_note') ?? '';

  static bool getUse24HourFormat() => getBool('use_24hour_format') ?? true;

  // Cache Methods
  static Future<void> setCachedSchedule(List<Map<String, dynamic>> schedule) async {
    await setString('cached_schedule', jsonEncode(schedule));
  }

  static List<Map<String, dynamic>> getCachedSchedule() {
    final data = getString('cached_schedule');
    if (data == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearAll() => _prefs!.clear();
}
