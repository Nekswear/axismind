import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_service_interface.dart';

/// Сервис аутентификации через Google аккаунт.
///
/// Использует [FirebaseAuth] + [GoogleSignIn] для входа/выхода.
/// Предоставляет поток состояния аутентификации для реактивного UI.
///
/// **Важно для Android**: clientId для GoogleSignIn НЕ передаётся,
/// потому что Android читает ключи из google-services.json автоматически.
///
/// **Конструктор никогда не бросает исключения** — если Firebase не
/// инициализирован, сервис просто работает в offline-режиме (все методы
/// возвращают null/пустое состояние).
class AuthService implements AuthServiceInterface {
  final FirebaseAuth? _auth;
  final GoogleSignIn? _googleSignIn;

  /// Создаёт AuthService.
  ///
  /// Конструктор **никогда не падает** — если Firebase не инициализирован,
  /// _auth и _googleSignIn будут null, и все методы вернут null/пустое состояние.
  AuthService()
    : _auth = _tryInitFirebaseAuth(),
      _googleSignIn = _tryInitGoogleSignIn();

  /// Пытается получить FirebaseAuth.instance.
  /// Возвращает null, если Firebase не инициализирован.
  static FirebaseAuth? _tryInitFirebaseAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('AuthService: FirebaseAuth недоступен: $e');
      return null;
    }
  }

  /// Пытается создать GoogleSignIn.
  /// На Android clientId НЕ передаётся — берётся из google-services.json.
  /// На iOS/Web clientId опционален.
  static GoogleSignIn? _tryInitGoogleSignIn() {
    try {
      return GoogleSignIn(scopes: ['email', 'profile']);
    } catch (e) {
      debugPrint('AuthService: GoogleSignIn недоступен: $e');
      return null;
    }
  }

  /// Поток состояния аутентификации.
  /// Если Firebase недоступен — возвращает пустой стрим.
  Stream<User?> get authStateChanges {
    if (_auth == null) return const Stream.empty();
    return _auth!.authStateChanges();
  }

  /// Текущий пользователь (null если не авторизован или Firebase недоступен).
  User? get currentUser => _auth?.currentUser;

  /// Пользователь авторизован?
  bool get isAuthenticated => _auth?.currentUser != null;

  /// Войти через Google.
  ///
  /// 1. Открывает системный диалог выбора Google-аккаунта.
  /// 2. Получает idToken + accessToken от Google.
  /// 3. Обменивает их на Firebase credential.
  /// 4. Возвращает [User] или null (если пользователь отменил вход).
  ///
  /// Если GoogleSignIn или FirebaseAuth недоступны — выбрасывает [AuthException].
  Future<User?> signInWithGoogle() async {
    if (_googleSignIn == null || _auth == null) {
      throw AuthException(
        'Google Sign-In недоступен. Проверьте подключение к интернету '
        'и убедитесь, что сервисы Google Play установлены.',
      );
    }

    try {
      // Шаг 1: выбираем аккаунт Google
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
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
      final UserCredential userCredential = await _auth!.signInWithCredential(
        credential,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error: ${e.code} — ${e.message}');
      rethrow;
    } on PlatformException catch (e) {
      debugPrint('Google Sign-In PlatformException: ${e.code} — ${e.message}');
      throw AuthException(
        'Не удалось войти через Google. Убедитесь, что на устройстве '
        'установлен сервис Google Play и добавлен аккаунт Google. '
        'Ошибка: ${e.message}',
      );
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
      await _googleSignIn?.signOut();
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Отображаемое имя пользователя.
  String? get displayName => _auth?.currentUser?.displayName;

  /// URL аватара пользователя.
  String? get photoUrl => _auth?.currentUser?.photoURL;

  /// Email пользователя.
  String? get email => _auth?.currentUser?.email;

  /// UID пользователя в Firebase.
  String? get userId => _auth?.currentUser?.uid;
}

/// Custom exception for authentication errors with user-friendly messages.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
