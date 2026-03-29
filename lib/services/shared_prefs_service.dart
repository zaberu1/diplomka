// lib/services/shared_prefs_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static Future<SharedPreferences> get _instance async =>
      _prefsInstance ??= await SharedPreferences.getInstance();
  static SharedPreferences? _prefsInstance;

  static Future<SharedPreferences> init() async {
    _prefsInstance = await _instance;
    return _prefsInstance!;
  }

  // Theme
  static Future<void> setTheme(String theme) async {
    await _prefsInstance?.setString('theme_mode', theme);
  }

  static String getTheme() {
    return _prefsInstance?.getString('theme_mode') ?? 'dark';
  }

  // Place selection
  static Future<void> setPlace(String place) async {
    await _prefsInstance?.setString('selected_place', place);
  }

  static String getPlace() {
    return _prefsInstance?.getString('selected_place') ?? 'school';
  }

  // Schedule mode (same everyday or weekly)
  static Future<void> setScheduleMode(bool sameEveryday) async {
    await _prefsInstance?.setBool('same_schedule', sameEveryday);
  }

  static bool getScheduleMode() {
    return _prefsInstance?.getBool('same_schedule') ?? true;
  }

  // Reminders settings
  static Future<void> setRemindersEnabled(bool enabled) async {
    await _prefsInstance?.setBool('reminders_enabled', enabled);
  }

  static bool getRemindersEnabled() {
    return _prefsInstance?.getBool('reminders_enabled') ?? true;
  }

  static Future<void> setReminderMinutes(int minutes) async {
    await _prefsInstance?.setInt('reminder_minutes', minutes);
  }

  static int getReminderMinutes() {
    return _prefsInstance?.getInt('reminder_minutes') ?? 5;
  }

  // History entries
  static Future<void> setHistoryEntries(List<Map<String, dynamic>> entries) async {
    final encoded = entries.map((e) => e.toString()).toList();
    await _prefsInstance?.setStringList('history_entries', encoded);
  }

  static List<Map<String, dynamic>> getHistoryEntries() {
    final raw = _prefsInstance?.getStringList('history_entries') ?? [];
    try {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  // Clear all data (for logout)
  static Future<void> clearAll() async {
    await _prefsInstance?.clear();
  }

  // Remove specific data
  static Future<void> remove(String key) async {
    await _prefsInstance?.remove(key);
  }
}