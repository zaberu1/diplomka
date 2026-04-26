// lib/app/theme_controller.dart
import 'package:flutter/material.dart';
import '../services/shared_prefs_service.dart';

class ThemeState {
  final ThemeMode mode;
  final Color accentColor;

  const ThemeState({required this.mode, required this.accentColor});
}

class ThemeController extends ValueNotifier<ThemeState> {
  ThemeController() : super(const ThemeState(mode: ThemeMode.dark, accentColor: Colors.amber));

  Future<void> loadSettings() async {
    final themeStr = SharedPrefsService.getTheme();
    final colorValue = SharedPrefsService.getInt('accent_color') ?? Colors.amber.value;
    
    value = ThemeState(
      mode: themeStr == 'light' ? ThemeMode.light : ThemeMode.dark,
      accentColor: Color(colorValue),
    );
  }

  Future<void> toggleTheme() async {
    final newMode = value.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    value = ThemeState(mode: newMode, accentColor: value.accentColor);
    await SharedPrefsService.setTheme(newMode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setAccentColor(Color color) async {
    value = ThemeState(mode: value.mode, accentColor: color);
    await SharedPrefsService.setInt('accent_color', color.value);
  }
}

final themeController = ThemeController();
