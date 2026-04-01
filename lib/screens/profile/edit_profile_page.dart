// lib/screens/profile/edit_profile_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  final User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  File? _selectedImage;
  String? _currentPhotoURL;
  String? _role; // Добавляем роль

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
  }

  Future<void> _loadAllUserData() async {
    if (user == null) return;
    
    _nameController.text = user!.displayName ?? '';
    _emailController.text = user!.email ?? '';
    _currentPhotoURL = user!.photoURL;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _role = data['role'] ?? 'student';
        _phoneController.text = data['phone'] ?? '';
        _bioController.text = data['bio'] ?? '';
      }
    } catch (e) {
      debugPrint('Ошибка загрузки: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1C2C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              _buildPickerTile(Icons.photo_library_rounded, 'Выбрать из галереи', ImageSource.gallery),
              _buildPickerTile(Icons.camera_alt_rounded, 'Сделать фото', ImageSource.camera),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerTile(IconData icon, String title, ImageSource source) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () async {
        Navigator.pop(context);
        final XFile? image = await _picker.pickImage(source: source, maxWidth: 500, maxHeight: 500, imageQuality: 80);
        if (image != null) setState(() => _selectedImage = File(image.path));
      },
    );
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileName = 'profile_${user!.uid}.jpg';
      final ref = FirebaseStorage.instance.ref().child('profiles/$fileName');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) { return null; }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String? newPhotoURL = _currentPhotoURL;
        if (_selectedImage != null) {
          newPhotoURL = await _uploadImage(_selectedImage!);
          if (newPhotoURL != null) await user!.updatePhotoURL(newPhotoURL);
        }

        if (_nameController.text.trim() != user!.displayName) {
          await user!.updateDisplayName(_nameController.text.trim());
        }

        final dataToUpdate = {
          'displayName': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'photoURL': newPhotoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Сохраняем bio (должность) только если пользователь - учитель
        if (_role == 'teacher') {
          dataToUpdate['bio'] = _bioController.text.trim();
        }

        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(dataToUpdate, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Данные сохранены!')));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
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

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildGlassCard(
        opacity: 0.03,
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.amber)));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Редактирование'), backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [const Color(0xFF0F2027), const Color(0xFF203A43)] : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)]))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildAvatarHeader(),
                    const SizedBox(height: 32),
                    _buildTextField(controller: _nameController, label: 'Ваше имя', icon: Icons.person_outline),
                    _buildTextField(controller: _phoneController, label: 'Телефон', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                    
                    // ПОКАЗЫВАЕМ ПОЛЕ ТОЛЬКО УЧИТЕЛЮ
                    if (_role == 'teacher')
                      _buildTextField(controller: _bioController, label: 'Должность / Кафедра', icon: Icons.work_outline, maxLines: 2),

                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _updateProfile, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('Сохранить', style: TextStyle(fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarHeader() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: CircleAvatar(
          radius: 55,
          backgroundColor: Colors.white12,
          backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) as ImageProvider : (_currentPhotoURL != null ? NetworkImage(_currentPhotoURL!) : null),
          child: (_selectedImage == null && _currentPhotoURL == null) ? const Icon(Icons.person, size: 55, color: Colors.amber) : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose(); _emailController.dispose(); _phoneController.dispose(); _bioController.dispose();
    super.dispose();
  }
}
