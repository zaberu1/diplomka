// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lesson_model.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;

  Stream<DocumentSnapshot> getUserStream() {
    if (user == null) return const Stream.empty();
    return _firestore.collection('users').doc(user!.uid).snapshots();
  }

  Future<DocumentSnapshot> getUserData() async {
    if (user == null) throw Exception('User not logged in');
    return await _firestore.collection('users').doc(user!.uid).get();
  }

  // ОБНОВЛЯЕМ ВРЕМЯ ПОСЛЕДНЕГО ВИЗИТА
  Future<void> updateLastSeen() async {
    if (user == null) return;
    await _firestore.collection('users').doc(user!.uid).set({
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (user == null) return;
    await _firestore.collection('users').doc(user!.uid).set(data, SetOptions(merge: true));
  }

  Future<void> cancelJoinRequest() async {
    if (user == null) return;
    
    final reqs = await _firestore.collection('requests')
        .where('studentId', isEqualTo: user!.uid)
        .get();
        
    final batch = _firestore.batch();
    for (var doc in reqs.docs) {
      batch.delete(doc.reference);
    }
    
    batch.update(_firestore.collection('users').doc(user!.uid), {
      'pendingRequest': false,
      'appMode': 'manual',
    });
    
    await batch.commit();
  }

  Future<void> saveSchedule(String place, List<Lesson> lessons, {bool isWeekly = false, String? day}) async {
    if (user == null) return;
    final docId = isWeekly ? '${place}_weekly' : place;
    final docRef = _firestore.collection('users').doc(user!.uid).collection('schedules').doc(docId);

    final lessonMaps = lessons.map((l) => l.toMap()).toList();

    if (isWeekly && day != null) {
      await docRef.set({
        'days': {
          day: lessonMaps,
        }
      }, SetOptions(merge: true));
    } else {
      await docRef.set({
        'items': lessonMaps,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Stream<List<Lesson>> getScheduleStream(String place, {bool isWeekly = false}) {
    if (user == null) return Stream.value([]);
    final docId = isWeekly ? '${place}_weekly' : place;
    
    return _firestore.collection('users').doc(user!.uid).collection('schedules').doc(docId).snapshots().map((doc) {
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;

      if (isWeekly) {
        final daysData = data['days'] as Map<String, dynamic>? ?? {};
        final today = _getDayName(DateTime.now());
        final items = daysData[today] as List?;
        return (items ?? []).map((e) => Lesson.fromMap(Map<String, dynamic>.from(e))).toList();
      } else {
        final items = data['items'] as List?;
        return (items ?? []).map((e) => Lesson.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    });
  }

  Future<List<Lesson>> getSchedule(String place, {bool isWeekly = false}) async {
    if (user == null) return [];
    try {
      final docId = isWeekly ? '${place}_weekly' : place;
      final doc = await _firestore.collection('users').doc(user!.uid).collection('schedules').doc(docId).get();
      
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;

      if (isWeekly) {
        final daysData = data['days'] as Map<String, dynamic>? ?? {};
        final today = _getDayName(DateTime.now());
        final items = daysData[today] as List?;
        return (items ?? []).map((e) => Lesson.fromMap(Map<String, dynamic>.from(e))).toList();
      } else {
        final items = data['items'] as List?;
        return (items ?? []).map((e) => Lesson.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, List<Lesson>>> getFullWeeklySchedule(String place) async {
    if (user == null) return {};
    try {
      final doc = await _firestore.collection('users').doc(user!.uid).collection('schedules').doc('${place}_weekly').get();
      if (!doc.exists) return {};
      final data = doc.data() as Map<String, dynamic>;
      final daysData = data['days'] as Map<String, dynamic>? ?? {};
      
      return daysData.map((key, value) => MapEntry(
        key, 
        (value as List).map((e) => Lesson.fromMap(Map<String, dynamic>.from(e))).toList()
      ));
    } catch (e) {
      return {};
    }
  }

  String _getDayName(DateTime date) {
    const days = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    return days[date.weekday - 1];
  }

  Stream<List<Map<String, dynamic>>> getGroupScheduleStream(String groupId) {
    return _firestore.collection('groups').doc(groupId).snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final groupData = snapshot.data()!;
      final rawSchedule = groupData['schedule'] as Map<String, dynamic>? ?? {};
      
      int dayIndex = DateTime.now().weekday - 1;
      if (dayIndex > 5) return []; 
      
      final todayLessons = (rawSchedule[dayIndex.toString()] ?? []) as List;
      
      return todayLessons.map((e) => {
        'name': e['name'] ?? 'Урок',
        'start': e['start'] ?? '08:00',
        'end': e['end'] ?? '08:45',
        'room': e['room'],
        'colorValue': e['colorValue'] ?? 0xFF00BCD4,
      }).toList();
    });
  }

  Stream<Map<String, List<Lesson>>> getGroupWeeklyScheduleStream(String groupId) {
    final List<String> daysLong = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота'];
    
    return _firestore.collection('groups').doc(groupId).snapshots().map((snapshot) {
      if (!snapshot.exists) return {};
      final groupData = snapshot.data()!;
      final rawSchedule = groupData['schedule'] as Map<String, dynamic>? ?? {};
      
      Map<String, List<Lesson>> weekly = {};
      for (int i = 0; i < 6; i++) {
        final dayKey = i.toString();
        final lessonsList = (rawSchedule[dayKey] ?? []) as List;
        weekly[daysLong[i]] = lessonsList.map((e) => Lesson.fromMap(Map<String, dynamic>.from(e))).toList();
      }
      return weekly;
    });
  }

  Future<List<Map<String, dynamic>>> getGroupSchedule(String groupId) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return [];
      final groupData = groupDoc.data()!;
      final rawSchedule = groupData['schedule'] as Map<String, dynamic>? ?? {};
      
      int dayIndex = DateTime.now().weekday - 1;
      if (dayIndex > 5) return [];
      
      final todayLessons = (rawSchedule[dayIndex.toString()] ?? []) as List;
      
      return todayLessons.map((e) => {
        'name': e['name'] ?? 'Урок',
        'start': e['start'] ?? '08:00',
        'end': e['end'] ?? '08:45',
        'room': e['room'],
        'colorValue': e['colorValue'] ?? 0xFF00BCD4,
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

final databaseService = DatabaseService();
