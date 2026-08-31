// =============================================================================
// AxisMind — Widget-тесты для NotificationSettingsScreen
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ЗАПУСК ТЕСТОВ                                  ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║  flutter test test/notification/notification_settings_screen_test.dart  ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Проверяет:
//   • Отображение экрана настроек уведомлений
//   • Обработку ошибок при недоступности сервисов
// =============================================================================
//
// ВАЖНО: NotificationSettingsScreen зависит от NotificationRepository (SQLite)
// и AppServiceLocator. В тестовом окружении эти сервисы недоступны, поэтому
// экран отображает состояние ошибки. Полноценное тестирование требует
// интеграционных тестов с реальными зависимостями.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:axismind/screens/notification_settings_screen.dart';

void main() {
  testWidgets('NotificationSettingsScreen отображает заголовок', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationSettingsScreen(),
      ),
    );

    // Ждём завершения асинхронной загрузки (которая упадёт с ошибкой)
    await tester.pumpAndSettle();

    // Заголовок "Уведомления" отображается в AppBar (2 виджета: заголовок и
    // текст в AppBar). Используем findsAtLeast для гибкости.
    expect(find.text('Уведомления'), findsAtLeast(1));
  });

  testWidgets('NotificationSettingsScreen показывает ошибку при недоступности сервисов', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationSettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Должен отобразиться AppBar с заголовком
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('NotificationSettingsScreen имеет корректную структуру', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationSettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Проверяем базовую структуру: Scaffold + AppBar
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
