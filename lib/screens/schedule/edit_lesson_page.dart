// lib/screens/schedule/edit_lesson_page.dart
import 'package:flutter/material.dart';
import '../../models/lesson_model.dart';
import '../../utils/constants.dart';
import 'dart:ui';

class EditLessonPage extends StatefulWidget {
  final String name;
  final String start;
  final String end;
  final String? room;
  final String? homework;
  final Color? color;

  const EditLessonPage({
    super.key,
    required this.name,
    required this.start,
    required this.end,
    this.room,
    this.homework,
    this.color,
  });

  @override
  State<EditLessonPage> createState() => _EditLessonPageState();
}

class _EditLessonPageState extends State<EditLessonPage> {
  late TextEditingController nameController;
  late TextEditingController startController;
  late TextEditingController endController;
  late TextEditingController roomController;
  late TextEditingController homeworkController;
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    startController = TextEditingController(text: widget.start);
    endController = TextEditingController(text: widget.end);
    roomController = TextEditingController(text: widget.room ?? '');
    homeworkController = TextEditingController(text: widget.homework ?? '');
    selectedColor = widget.color ?? AppConstants.lessonColors.first;
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final parts = controller.text.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: isDark ? const Color(0xFF1A1C2C) : Colors.white,
              dialHandColor: Colors.amber,
              hourMinuteTextColor: isDark ? Colors.white : Colors.black,
              helpTextStyle: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _save() {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название пары!')),
      );
      return;
    }

    Navigator.pop(context, Lesson(
      name: nameController.text.trim(),
      start: startController.text.trim(),
      end: endController.text.trim(),
      room: roomController.text.trim().isNotEmpty ? roomController.text.trim() : null,
      homework: homeworkController.text.trim().isNotEmpty ? homeworkController.text.trim() : null,
      colorValue: selectedColor.value,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Редактировать пару'),
        backgroundColor: isDark ? const Color(0xFF1A1C2C) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 2,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Название пары',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: 'Например: Математика',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Время',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickTime(startController),
                            icon: const Icon(Icons.access_time_outlined),
                            label: Text('Начало: ${startController.text}'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickTime(endController),
                            icon: const Icon(Icons.timelapse),
                            label: Text('Конец: ${endController.text}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text('Аудитория',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: roomController,
                      decoration: const InputDecoration(
                        hintText: 'Например: Каб. 302',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Домашнее задание',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: homeworkController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Например: решить №24, 25',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Цвет пары',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: AppConstants.lessonColors.map((color) {
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade400,
                                width: isSelected ? 3 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: color.withOpacity(0.6),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ]
                                  : [],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Отмена'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amberAccent,
                            ),
                            child: const Text(
                              'Сохранить',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}