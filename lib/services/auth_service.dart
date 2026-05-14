import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter/foundation.dart';

/// Сервис аутентификации через Google аккаунт.
///
/// Использует [FirebaseAuth] + [GoogleSignIn] для входа/выхода.
/// Предоставляет поток состояния аутентификации для реактивного UI.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Поток состояния аутентификации.
  /// Подписка на этот поток позволяет UI реагировать на вход/выход.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Текущий пользователь (null если не авторизован).
  User? get currentUser => _auth.currentUser;

  /// Пользователь авторизован?
  bool get isAuthenticated => _auth.currentUser != null;

  /// Войти через Google.
  ///
  /// 1. Открывает системный диалог выбора Google-аккаунта.
  /// 2. Получает idToken + accessToken от Google.
  /// 3. Обменивает их на Firebase credential.
  /// 4. Возвращает [User] или null (если пользователь отменил вход).
  ///
  /// Может выбросить [FirebaseAuthException] при ошибке аутентификации.
  Future<User?> signInWithGoogle() async {
    try {
      // Шаг 1: выбираем аккаунт Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Пользователь отменил вход
        return null;
      }

      // Шаг 2: получаем токены аутентификации
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Шаг 3: создаём Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Шаг 4: входим в Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error: ${e.code} — ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Выйти из аккаунта.
  ///
  /// Отзывает Google токен и выходит из Firebase.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Отображаемое имя пользователя.
  String? get displayName => _auth.currentUser?.displayName;

  /// URL аватара пользователя.
  String? get photoUrl => _auth.currentUser?.photoURL;

  /// Email пользователя.
  String? get email => _auth.currentUser?.email;

  /// UID пользователя в Firebase.
  String? get userId => _auth.currentUser?.uid;
}
