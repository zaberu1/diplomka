// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    
    // ПРИНУДИТЕЛЬНОЕ ОБНОВЛЕНИЕ РОЛИ ДЛЯ АДМИНА ПРИ ВХОДЕ
    if (result.user != null && email.trim() == 'admin@zvonok.ru') {
      await _db.collection('users').doc(result.user!.uid).set({
        'email': email.trim(),
        'role': 'admin',
      }, SetOptions(merge: true));
    }
    
    return result.user;
  }

  Future<User?> signUp(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    
    if (result.user != null) {
      await _db.collection('users').doc(result.user!.uid).set({
        'email': email.trim(),
        'role': email.trim() == 'admin@zvonok.ru' ? 'admin' : 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return result.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
