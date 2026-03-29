// lib/screens/auth/auth_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../setup/place_selection_page.dart';
import '../onboarding/welcome_page.dart';

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

  Future<void> _auth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Заполните все поля');
      return;
    }
    if (!isLogin && _passwordController.text != _confirmPasswordController.text) {
      _showError('Пароли не совпадают');
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', true);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PlaceSelectionPage()));
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      _showError('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'Пользователь не найден';
      case 'wrong-password': return 'Неверный пароль';
      case 'email-already-in-use': return 'Email уже занят';
      case 'invalid-email': return 'Неверный формат email';
      case 'weak-password': return 'Слишком слабый пароль';
      default: return 'Ошибка аутентификации';
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Widget _buildGlassCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    VoidCallback? onToggle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.amber, size: 20),
            suffixIcon: onToggle != null 
              ? IconButton(icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.amber.withOpacity(0.5), size: 18), onPressed: onToggle) 
              : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Фон
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [const Color(0xFF0F2027), const Color(0xFF203A43)] 
                  : [const Color(0xFFF0F2F5), const Color(0xFFE0EAFC)],
              ),
            ),
          ),
          // Сферы
          Positioned(
            top: 100, right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber.withOpacity(0.15))),
            ),
          ),
          Positioned(
            bottom: 50, left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.1))),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Лого
                    Hero(
                      tag: 'logo',
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber.withOpacity(0.1),
                          border: Border.all(color: Colors.amber.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 60),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('ZvonOK', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const Text('Твой умный график звонков', style: TextStyle(fontSize: 14, color: Colors.white54)),
                    const SizedBox(height: 40),

                    // Карточка формы
                    _buildGlassCard(
                      child: Column(
                        children: [
                          Text(isLogin ? 'С возвращением!' : 'Создать аккаунт', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          _buildTextField(label: 'Email', controller: _emailController, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                          _buildTextField(label: 'Пароль', controller: _passwordController, icon: Icons.lock_outline_rounded, obscureText: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                          if (!isLogin) _buildTextField(label: 'Подтвердите пароль', controller: _confirmPasswordController, icon: Icons.lock_reset_rounded, obscureText: _obscurePassword),
                          
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _auth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                              ),
                              child: _loading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)))
                                : Text(isLogin ? 'Войти' : 'Зарегистрироваться', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(
                        isLogin ? 'Нет аккаунта? Зарегистрироваться' : 'Уже есть аккаунт? Войти',
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    TextButton.icon(
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomePage())),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('О приложении'),
                      style: TextButton.styleFrom(foregroundColor: Colors.white38),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
