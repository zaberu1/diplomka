// lib/screens/settings/notification_settings_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/shared_prefs_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _remindersEnabled = true;
  bool _notifyStart = true;
  bool _notifyEnd = true;
  int _minutesStart = 5;
  int _minutesEnd = 5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _remindersEnabled = SharedPrefsService.getRemindersEnabled();
      _notifyStart = SharedPrefsService.getNotifyStart();
      _notifyEnd = SharedPrefsService.getNotifyEnd();
      _minutesStart = SharedPrefsService.getReminderMinutesStart();
      _minutesEnd = SharedPrefsService.getReminderMinutesEnd();
    });
  }

  void _saveSettings() {
    SharedPrefsService.setRemindersEnabled(_remindersEnabled);
    SharedPrefsService.setNotifyStart(_notifyStart);
    SharedPrefsService.setNotifyEnd(_notifyEnd);
    SharedPrefsService.setReminderMinutesStart(_minutesStart);
    SharedPrefsService.setReminderMinutesEnd(_minutesEnd);
  }

  Widget _buildGlassCard({required Widget child, double opacity = 0.05}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(opacity) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Уведомления', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [const Color(0xFF0F2027), const Color(0xFF203A43)] 
                  : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ОСНОВНЫЕ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white54)),
                  const SizedBox(height: 12),
                  _buildGlassCard(
                    child: ListTile(
                      leading: Icon(Icons.notifications_active_rounded, color: isDark ? Colors.white70 : Colors.black87),
                      title: const Text('Разрешить уведомления', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Switch(
                        value: _remindersEnabled,
                        onChanged: (v) {
                          setState(() => _remindersEnabled = v);
                          _saveSettings();
                        },
                        activeColor: primaryColor,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  if (_remindersEnabled) ...[
                    const SizedBox(height: 32),
                    const Text('ПЕРЕД НАЧАЛОМ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white54)),
                    const SizedBox(height: 12),
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: Icon(Icons.login_rounded, color: isDark ? Colors.white70 : Colors.black87),
                            title: const Text('Включить'),
                            trailing: Switch(
                              value: _notifyStart,
                              onChanged: (v) {
                                setState(() => _notifyStart = v);
                                _saveSettings();
                              },
                              activeColor: primaryColor,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_notifyStart) ...[
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('За сколько минут:', style: TextStyle(fontSize: 14)),
                                Text('$_minutesStart мин.', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                              ],
                            ),
                            Slider(
                              value: _minutesStart.toDouble(),
                              min: 1, max: 15, divisions: 14,
                              activeColor: primaryColor,
                              onChanged: (v) {
                                setState(() => _minutesStart = v.toInt());
                                _saveSettings();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Text('ПЕРЕД КОНЦОМ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white54)),
                    const SizedBox(height: 12),
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: Icon(Icons.logout_rounded, color: isDark ? Colors.white70 : Colors.black87),
                            title: const Text('Включить'),
                            trailing: Switch(
                              value: _notifyEnd,
                              onChanged: (v) {
                                setState(() => _notifyEnd = v);
                                _saveSettings();
                              },
                              activeColor: primaryColor,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_notifyEnd) ...[
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('За сколько минут:', style: TextStyle(fontSize: 14)),
                                Text('$_minutesEnd мин.', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                              ],
                            ),
                            Slider(
                              value: _minutesEnd.toDouble(),
                              min: 1, max: 15, divisions: 14,
                              activeColor: primaryColor,
                              onChanged: (v) {
                                setState(() => _minutesEnd = v.toInt());
                                _saveSettings();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Уведомления помогут вам не опоздать на занятия и вовремя подготовиться к перерыву.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
