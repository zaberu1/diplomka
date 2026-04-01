// lib/app/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final ThemeMode mode;
  final Color accentColor;

  ThemeState({required this.mode, required this.accentColor});
}

class ThemeController extends ValueNotifier<ThemeState> {
  ThemeController() : super(ThemeState(mode: ThemeMode.dark, accentColor: Colors.amber));

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isLight = prefs.getString('theme_mode') == 'light';
    final colorValue = prefs.getInt('accent_color') ?? Colors.amber.value;
    
    value = ThemeState(
      mode: isLight ? ThemeMode.light : ThemeMode.dark,
      accentColor: Color(colorValue),
    );
  }

  Future<void> toggleTheme() async {
    final newMode = value.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    value = ThemeState(mode: newMode, accentColor: value.accentColor);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', newMode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setAccentColor(Color color) async {
    value = ThemeState(mode: value.mode, accentColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_color', color.value);
  }
}

final themeController = ThemeController();
