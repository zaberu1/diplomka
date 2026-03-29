// lib/screens/schedule/edit_lesson_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/lesson_model.dart';
import '../../utils/constants.dart';

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
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _save() {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите название!'), behavior: SnackBarBehavior.floating));
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

  Widget _buildGlassCard({required Widget child, double opacity = 0.05, double blur = 15}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
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

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildGlassCard(
        opacity: 0.03,
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.amber, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Детали пары', style: TextStyle(fontWeight: FontWeight.bold)),
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
                colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)],
              ),
            ),
          ),
          // Сферы
          Positioned(
            top: 50, right: -30,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 80, spreadRadius: 20)]),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildTextField(controller: nameController, label: 'Название пары', icon: Icons.book_outlined),
                  
                  _buildGlassCard(
                    opacity: 0.03,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Время проведения', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickTime(startController),
                                icon: const Icon(Icons.access_time, size: 18),
                                label: Text(startController.text),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.amber, side: const BorderSide(color: Colors.white10)),
                              ),
                            ),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('—')),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickTime(endController),
                                icon: const Icon(Icons.timelapse, size: 18),
                                label: Text(endController.text),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.amber, side: const BorderSide(color: Colors.white10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  _buildTextField(controller: roomController, label: 'Аудитория / Кабинет', icon: Icons.location_on_outlined),
                  _buildTextField(controller: homeworkController, label: 'Заметки / ДЗ', icon: Icons.edit_note_rounded, maxLines: 2),
                  
                  _buildGlassCard(
                    opacity: 0.03,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Цвет в расписании', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: AppConstants.lessonColors.map((color) {
                            final isSelected = selectedColor.value == color.value;
                            return GestureDetector(
                              onTap: () => setState(() => selectedColor = color),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
                                  boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : [],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: const Text('Сохранить', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    startController.dispose();
    endController.dispose();
    roomController.dispose();
    homeworkController.dispose();
    super.dispose();
  }
}
