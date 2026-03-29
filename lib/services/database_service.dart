// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lesson_model.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> saveSchedule(String place, List<Lesson> lessons, {bool isWeekly = false}) async {
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('schedules')
        .doc(isWeekly ? '${place}_weekly' : place);

    if (isWeekly) {
      // Для недельного расписания группируем по дням
      final Map<String, dynamic> daysMap = {};
      for (var lesson in lessons) {
        // Здесь нужно добавить логику распределения по дням недели
        // Пока сохраняем как есть, но в будущем нужно будет доработать
        daysMap['lessons'] = lessons.map((lesson) => lesson.toMap()).toList();
      }
      await docRef.set({'days': daysMap});
    } else {
      // Для ежедневного расписания
      await docRef.set({
        'items': lessons.map((lesson) => lesson.toMap()).toList(),
      });
    }
  }

  Future<List<Lesson>> getSchedule(String place, {bool isWeekly = false}) async {
    if (user == null) return [];

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('schedules')
          .doc(isWeekly ? '${place}_weekly' : place)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        if (isWeekly) {
          // Логика для недельного расписания
          final daysData = data['days'] as Map<String, dynamic>?;
          if (daysData != null && daysData.containsKey('lessons')) {
            final items = daysData['lessons'] as List;
            return items.map((item) => Lesson.fromMap(item)).toList();
          }
          return [];
        } else {
          final items = data['items'] as List;
          return items.map((item) => Lesson.fromMap(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting schedule: $e');
      return [];
    }
  }

  Future<void> deleteSchedule(String place, {bool isWeekly = false}) async {
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('schedules')
        .doc(isWeekly ? '${place}_weekly' : place)
        .delete();
  }

  // Генерация расписания по умолчанию
  List<Lesson> generateDefaultSchedule(String place) {
    List<Lesson> generated = [];
    TimeOfDay current = place == 'school'
        ? const TimeOfDay(hour: 8, minute: 0)
        : const TimeOfDay(hour: 9, minute: 0);

    for (int i = 1; i <= 7; i++) {
      final end = TimeOfDay(
          hour: (current.hour + ((current.minute + 45) ~/ 60)) % 24,
          minute: (current.minute + 45) % 60);

      generated.add(Lesson(
        name: place == 'school' ? '$i урок' : '$i пара',
        start: '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}',
        end: '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
      ));

      current = TimeOfDay(
          hour: (end.hour + ((end.minute + 10) ~/ 60)) % 24,
          minute: (end.minute + 10) % 60);
    }
    return generated;
  }
}