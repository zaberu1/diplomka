// lib/screens/auth/auth_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../setup/place_selection_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLogin = true;
  bool _loading = false;

  Future<void> _auth() async {
    setState(() => _loading = true);
    try {
      User? user;
      if (isLogin) {
        user = await _authService.signIn(_emailController.text, _passwordController.text);
      } else {
        user = await _authService.signUp(_emailController.text, _passwordController.text);
      }

      if (user != null && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PlaceSelectionPage()));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка аутентификации')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController ctrl, bool obscure) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 320,
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          filled: true,
          fillColor: isDark ? const Color(0xFF1D1E33) : Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0E21) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.school, color: Colors.amber, size: 90),
              SizedBox(height: 20),
              Text(
                isLogin ? 'Вход в ZvonOK' : 'Регистрация в ZvonOK',
                style: TextStyle(fontSize: 24, color: textColor),
              ),
              SizedBox(height: 30),
              _buildTextField('Email', _emailController, false),
              SizedBox(height: 15),
              _buildTextField('Пароль', _passwordController, true),
              SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15)
                ),
                onPressed: _loading ? null : _auth,
                child: _loading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)),
                )
                    : Text(isLogin ? 'Войти' : 'Зарегистрироваться'),
              ),
              TextButton(
                onPressed: _loading ? null : () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin ? 'Нет аккаунта? Зарегистрируйтесь' : 'Уже есть аккаунт? Войти',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}