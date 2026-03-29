import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController(ThemeMode value) : super(value);

  Future<void> toggleTheme() async {
    final newMode = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    value = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', newMode == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeController = ThemeController(ThemeMode.dark);