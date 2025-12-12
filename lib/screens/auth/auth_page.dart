// lib/screens/auth/auth_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../setup/place_selection_page.dart';
import '../onboarding/welcome_page.dart'; // Добавил импорт WelcomePage

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _auth() async {
    // Валидация
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Заполните все поля');
      return;
    }

    if (!isLogin && _passwordController.text != _confirmPasswordController.text) {
      _showError('Пароли не совпадают');
      return;
    }

    if (!isLogin && _passwordController.text.length < 6) {
      _showError('Пароль должен содержать минимум 6 символов');
      return;
    }

    setState(() => _loading = true);

    try {
      User? user;
      if (isLogin) {
        user = await _authService.signIn(_emailController.text, _passwordController.text);
      } else {
        user = await _authService.signUp(_emailController.text, _passwordController.text);
      }

      if (user != null && mounted) {
        // Сохраняем информацию о входе
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', true);

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PlaceSelectionPage())
        );
      } else if (mounted) {
        _showError('Ошибка аутентификации');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Ошибка аутентификации';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Пользователь с таким email не найден';
          break;
        case 'wrong-password':
          errorMessage = 'Неверный пароль';
          break;
        case 'email-already-in-use':
          errorMessage = 'Пользователь с таким email уже существует';
          break;
        case 'invalid-email':
          errorMessage = 'Неверный формат email';
          break;
        case 'weak-password':
          errorMessage = 'Пароль слишком слабый';
          break;
      }
      _showError(errorMessage);
    } catch (e) {
      _showError('Произошла ошибка: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
      _confirmPasswordController.clear();
    });
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    IconData? prefixIcon,
    TextInputType? keyboardType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.amber) : null,
          suffixIcon: obscureText && label.contains('Пароль')
              ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.amber,
            ),
            onPressed: onToggleObscure,
          )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF1D1E33) : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E21) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Кнопка назад в левом верхнем углу
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomePage()),
                    );
                  },
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 28,
                  ),
                  tooltip: 'Вернуться назад',
                ),
              ),

              // Логотип
              Icon(
                Icons.notifications_active_rounded,
                color: Colors.amber,
                size: 90,
              ),
              const SizedBox(height: 10),

              // Заголовок
              Text(
                isLogin ? 'Вход в ZvonOK' : 'Регистрация в ZvonOK',
                style: TextStyle(
                  fontSize: 24,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Поля формы
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                obscureText: false,
                onToggleObscure: () {},
                prefixIcon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Пароль',
                controller: _passwordController,
                obscureText: _obscurePassword,
                onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                prefixIcon: Icons.lock_rounded,
              ),
              const SizedBox(height: 16),

              // Подтверждение пароля (только для регистрации)
              if (!isLogin)
                Column(
                  children: [
                    _buildTextField(
                      label: 'Подтверждение пароля',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      prefixIcon: Icons.lock_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Кнопка входа/регистрации
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _auth,
                  child: _loading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ),
                  )
                      : Text(
                    isLogin ? 'Войти' : 'Зарегистрироваться',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Переключение между входом и регистрацией
              TextButton(
                onPressed: _loading ? null : _toggleAuthMode,
                child: Text(
                  isLogin
                      ? 'Нет аккаунта? Зарегистрируйтесь'
                      : 'Уже есть аккаунт? Войти',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Кнопка "Назад" внизу
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomePage()),
                    );
                  },
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text('Вернуться к информации о приложении'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.black54,
                    side: BorderSide(
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}