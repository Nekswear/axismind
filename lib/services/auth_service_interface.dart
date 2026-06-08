import 'package:firebase_auth/firebase_auth.dart';

/// Абстрактный интерфейс сервиса аутентификации.
///
/// Позволяет тестировать код, зависящий от аутентификации,
/// без необходимости инициализировать Firebase.
abstract class AuthServiceInterface {
  /// Поток состояния аутентификации.
  Stream<User?> get authStateChanges;

  /// Текущий пользователь (null если не авторизован).
  User? get currentUser;

  /// Пользователь авторизован?
  bool get isAuthenticated;

  /// Войти через Google.
  Future<User?> signInWithGoogle();

  /// Выйти из аккаунта.
  Future<void> signOut();

  /// Отображаемое имя пользователя.
  String? get displayName;

  /// URL аватара пользователя.
  String? get photoUrl;

  /// Email пользователя.
  String? get email;

  /// UID пользователя в Firebase.
  String? get userId;
}
