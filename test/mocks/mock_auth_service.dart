// =============================================================================
// AxisMind — Mock-заглушка для AuthServiceInterface
// =============================================================================
//
// Используется в unit-тестах для изоляции от Firebase.
// Все методы возвращают безопасные значения по умолчанию.
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  ИСПОЛЬЗОВАНИЕ:                                                        ║
// ║    import 'package:axismind/mocks/mock_auth_service.dart';            ║
// ║    final auth = MockAuthService();                                      ║
// ║    final syncRepo = SyncRepository(localDb: db, auth: auth);            ║
// ╚══════════════════════════════════════════════════════════════════════════╝

import 'package:firebase_auth/firebase_auth.dart';
import 'package:axismind/services/auth_service_interface.dart';

/// Простая заглушка сервиса аутентификации для тестов.
///
/// Вместо настоящего Firebase возвращает null (пользователь не авторизован).
/// Это позволяет тестировать локальную работу без Firebase.
class MockAuthService implements AuthServiceInterface {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  bool get isAuthenticated => false;

  @override
  String? get displayName => null;

  @override
  String? get email => null;

  @override
  String? get photoUrl => null;

  @override
  String? get userId => null;

  @override
  Future<User?> signInWithGoogle() async => null;

  @override
  Future<void> signOut() async {}
}