// lib/models/lesson_model.dart
class Lesson {
  final String name;
  final String start;
  final String end;
  final String? room;
  final String? homework;
  final int colorValue;

  Lesson({
    required this.name,
    required this.start,
    required this.end,
    this.room,
    this.homework,
    this.colorValue = 0xFFFFC107,
  });

  String get time => '$start - $end';

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'start': start,
      'end': end,
      'room': room,
      'homework': homework,
      'color': colorValue,
      'time': time,
    };
  }

  static Lesson fromMap(Map<String, dynamic> map) {
    return Lesson(
      name: map['name'] ?? '',
      start: map['start'] ?? '08:00',
      end: map['end'] ?? '08:45',
      room: map['room'],
      homework: map['homework'],
      colorValue: map['color'] ?? 0xFFFFC107,
    );
  }
}