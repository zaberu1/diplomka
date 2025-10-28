// lib/screens/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme_controller.dart';
import '../../widgets/app_drawer.dart';
import '../setup/place_selection_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool remindersEnabled = true;
  int reminderMinutes = 5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    remindersEnabled = prefs.getBool('reminders_enabled') ?? true;
    reminderMinutes = prefs.getInt('reminder_minutes') ?? 5;
    setState(() {});
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', remindersEnabled);
    await prefs.setInt('reminder_minutes', reminderMinutes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Настройки сохранены')));
    }
  }

  Future<void> _changePlace(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_place');
    if (mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const PlaceSelectionPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 2,
        centerTitle: true,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text('Тёмная тема'),
              value: themeController.value == ThemeMode.dark,
              onChanged: (v) async {
                await themeController.toggleTheme();
                setState(() {});
              },
              activeColor: Colors.amber,
              inactiveThumbColor: Colors.grey,
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.amber),
              title: Text(
                'Сменить место',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              subtitle: Text(
                'Выберите другое учреждение',
                style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54),
              ),
              onTap: () => _changePlace(context),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.amber),
              title: Text(
                'Напоминания',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              subtitle: Text(
                remindersEnabled
                    ? 'Включены за $reminderMinutes минут'
                    : 'Отключены',
                style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54),
              ),
              onTap: () {
                setState(() => remindersEnabled = !remindersEnabled);
              },
            ),
            if (remindersEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      'За (мин): ',
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                    ),
                    Expanded(
                      child: Slider(
                        value: reminderMinutes.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: '$reminderMinutes',
                        onChanged: (v) =>
                            setState(() => reminderMinutes = v.round()),
                        activeColor: Colors.amberAccent,
                        inactiveColor:
                        isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.amber),
              title: Text(
                'О приложении',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              subtitle: Text(
                'Версия 1.0.0',
                style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Сохранить настройки'),
            ),
          ],
        ),
      ),
    );
  }
}