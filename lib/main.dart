import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Если приложений еще нет, инициализируем DEFAULT
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      // Если уже есть, просто используем существующее
      Firebase.app(); 
    }
  } catch (e) {
    debugPrint('Ошибка инициализации Firebase: $e');
  }
  
  runApp(const ZvonOKApp());
}
