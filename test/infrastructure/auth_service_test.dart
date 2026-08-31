// =============================================================================
// AxisMind — Unit-тесты для AuthServiceInterface через MockAuthService
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ЗАПУСК ТЕСТОВ                                  ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║  flutter test test/infrastructure/auth_service_test.dart                ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Что проверяется:
//   • MockAuthService реализует AuthServiceInterface
//   • signOut() не выбрасывает исключений
//   • Геттеры (isAuthenticated, currentUser, displayName и т.д.) работают
//
// ВНИМАНИЕ: Тесты используют MockAuthService вместо реального AuthService,
// чтобы не зависеть от Firebase в unit-тестах.
// Интеграционные тесты с реальным AuthService запускаются отдельно.

import 'package:flutter_test/flutter_test.dart';
import '../mocks/mock_auth_service.dart';

void main() {
  group('🔐 AuthServiceInterface — MockAuthService', () {
    test('MockAuthService создаётся без ошибок', () {
      final authService = MockAuthService();
      expect(authService, isNotNull);
    });

    test('isAuthenticated возвращает false для нового экземпляра', () {
      final authService = MockAuthService();
      expect(authService.isAuthenticated, isFalse);
    });

    test('currentUser возвращает null для нового экземпляра', () {
      final authService = MockAuthService();
      expect(authService.currentUser, isNull);
    });

    test('displayName возвращает null для нового экземпляра', () {
      final authService = MockAuthService();
      expect(authService.displayName, isNull);
    });

    test('photoUrl возвращает null для нового экземпляра', () {
      final authService = MockAuthService();
      expect(authService.photoUrl, isNull);
    });

    test('email возвращает null для нового экземпляра', () {
      final authService = MockAuthService();
      expect(authService.email, isNull);
    });

    test('userId возвращает null для нового экземпляра', () {
      final authService = MockAuthService();
      expect(authService.userId, isNull);
    });

    test('signOut() не выбрасывает исключений', () async {
      final authService = MockAuthService();
      await expectLater(authService.signOut(), completes);
    });

    test('authStateChanges возвращает Stream', () {
      final authService = MockAuthService();
      final stream = authService.authStateChanges;
      expect(stream, isA<Stream>());
    });
  });
}
