import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'firebase_options.dart';
import 'services/shared_prefs_service.dart';
import 'services/notification_service.dart';

void main() async {
  // 1. Инициализация связки с нативным кодом
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 2. Параллельная инициализация SharedPrefs и Firebase
    await SharedPrefsService.init();

    try {
      // Пытаемся инициализировать Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // Если ошибка говорит о том, что приложение уже существует, просто игнорируем её
      if (!e.toString().contains('duplicate-app')) {
        rethrow;
      }
      debugPrint('Firebase already initialized, skipping...');
    }
    
    debugPrint('Core services initialized');

    // 3. Уведомления - инициализируем асинхронно
    NotificationService.init().catchError((e) {
      debugPrint('Non-blocking NotificationService error: $e');
    });

    // 4. Запуск основного приложения
    runApp(const ZvonOKApp());
    
  } catch (e) {
    debugPrint('CRITICAL APP START ERROR: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                Text(
                  'Ошибка запуска приложения: $e\n\nПопробуйте полностью перезапустить приложение.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
