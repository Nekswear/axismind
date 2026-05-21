// =============================================================================
// ZenBalance — Widget-тесты для SubscriptionGuard
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ЗАПУСК ТЕСТОВ                                  ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║  flutter test test/subscription/subscription_guard_test.dart             ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Проверяет:
//   • Показывает экран загрузки при старте (пока _checking = true)
//   • Показывает PaywallScreen после таймаута, если подписка неактивна
//   • Содержит SubscriptionGuard в дереве
//   • Содержит Scaffold на экране загрузки
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenbalance/core/theme/zen_theme.dart';
import 'package:zenbalance/screens/paywall_screen.dart';
import 'package:zenbalance/widgets/subscription_guard.dart';

/// Тестовый child-виджет для SubscriptionGuard.
class TestChildWidget extends StatelessWidget {
  const TestChildWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Test Child Content'),
      ),
    );
  }
}

/// Создаёт [MaterialApp] с [SubscriptionGuard] и тестовым child.
Widget createGuardApp({required Widget child}) {
  return MaterialApp(
    theme: ZenTheme.build(),
    home: SubscriptionGuard(child: child),
  );
}

void main() {
  group('SubscriptionGuard — отображение', () {
    testWidgets('должен показывать экран загрузки при старте', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createGuardApp(child: const TestChildWidget()),
      );

      // Сразу после pump — _checking = true, должен быть экран загрузки
      expect(find.text('ZenBalance'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Child не должен отображаться
      expect(find.text('Test Child Content'), findsNothing);

      // Продвигаем таймер на 500мс, чтобы он сработал и не остался висеть
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('должен показывать PaywallScreen после таймаута', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createGuardApp(child: const TestChildWidget()),
      );

      // Ждём таймаут 500мс
      await tester.pump(const Duration(milliseconds: 600));

      // После таймаута должен быть PaywallScreen
      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.text('Test Child Content'), findsNothing);
    });

    testWidgets('должен содержать SubscriptionGuard в дереве', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createGuardApp(child: const TestChildWidget()),
      );

      expect(find.byType(SubscriptionGuard), findsOneWidget);

      // Продвигаем таймер
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('должен содержать Scaffold на экране загрузки', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createGuardApp(child: const TestChildWidget()),
      );

      // На экране загрузки есть Scaffold
      expect(find.byType(Scaffold), findsOneWidget);

      // Продвигаем таймер
      await tester.pump(const Duration(milliseconds: 600));
    });
  });
}
