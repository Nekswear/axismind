// =============================================================================
// ZenBalance — Widget-тесты для PaywallScreen
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ЗАПУСК ТЕСТОВ                                  ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║  flutter test test/subscription/paywall_screen_test.dart                 ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Проверяет:
//   • Отображение заголовка и подзаголовка
//   • Список премиум-функций (5 штук)
//   • Кнопка "Попробовать 7 дней бесплатно"
//   • Кнопка "Восстановить покупки"
//   • Кнопка "Продолжить бесплатно"
//   • Юридический текст
//   • Закрытие через AppBar
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenbalance/core/theme/zen_theme.dart';
import 'package:zenbalance/screens/paywall_screen.dart';

/// Создаёт [MaterialApp] с темой ZenBalance для тестирования PaywallScreen.
Widget createPaywallApp() {
  return MaterialApp(
    theme: ZenTheme.build(),
    home: const PaywallScreen(),
  );
}

void main() {
  group('PaywallScreen — отображение', () {
    testWidgets('должен отображать заголовок и подзаголовок', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPaywallApp());
      await tester.pumpAndSettle();

      // Заголовок — единый текст с \n
      expect(find.text('Откройте полный\nпотенциал ZenBalance'), findsOneWidget);

      // Подзаголовок
      expect(find.text('Попробуйте 7 дней бесплатно'), findsOneWidget);
    });

    testWidgets('должен отображать 5 премиум-функций', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPaywallApp());
      await tester.pumpAndSettle();

      // Проверяем названия всех 5 функций
      expect(find.text('Мотивационные уведомления'), findsOneWidget);
      expect(find.text('Напоминания о целях'), findsOneWidget);
      expect(find.text('Цели медитации'), findsOneWidget);
      expect(find.text('Детальная статистика'), findsOneWidget);
      expect(find.text('Синхронизация устройств'), findsOneWidget);
    });

    testWidgets('должен отображать кнопку покупки с ценой', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPaywallApp());
      await tester.pumpAndSettle();

      // Кнопка должна содержать текст с ценой (по умолчанию $7.00/месяц)
      expect(find.textContaining('Попробовать 7 дней бесплатно'), findsOneWidget);
      expect(find.textContaining('\$7.00/месяц'), findsOneWidget);
    });

    testWidgets('должен отображать кнопку восстановления покупок', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPaywallApp());
      await tester.pumpAndSettle();

      expect(find.text('Восстановить покупки'), findsOneWidget);
    });

    testWidgets('должен отображать кнопку "Продолжить бесплатно"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPaywallApp());
      await tester.pumpAndSettle();

      expect(find.text('Продолжить бесплатно'), findsOneWidget);
    });

    testWidgets('должен отображать юридический текст', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPaywallApp());
      await tester.pumpAndSettle();

      // Проверяем часть юридического текста
      expect(
        find.textContaining('Google Play'),
        findsAtLeast(1),
      );
    });

    testWidgets('должен отображать AppBar с кнопкой закрытия', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPaywallApp());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('должен отображать иконку приложения', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPaywallApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('должен отображать Scaffold', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPaywallApp());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('PaywallScreen — навигация', () {
    /// Создаёт приложение, где PaywallScreen открыт через Navigator.push.
    /// Это позволяет тестировать Navigator.pop().
    Widget createPaywallPushedApp() {
      return MaterialApp(
        theme: ZenTheme.build(),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PaywallScreen(),
                ),
              );
            },
            child: const Text('Open Paywall'),
          ),
        ),
      );
    }

    testWidgets('кнопка "Продолжить бесплатно" закрывает экран', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPaywallPushedApp());
      await tester.pumpAndSettle();

      // Открываем PaywallScreen
      await tester.tap(find.text('Open Paywall'));
      await tester.pumpAndSettle();

      // Проверяем, что PaywallScreen отображается
      expect(find.byType(PaywallScreen), findsOneWidget);

      // Скроллим вниз, чтобы кнопка стала видимой
      await tester.scrollUntilVisible(
        find.text('Продолжить бесплатно'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Нажимаем "Продолжить бесплатно"
      await tester.tap(find.text('Продолжить бесплатно'));
      await tester.pumpAndSettle();

      // После pop экран должен быть удалён из дерева
      expect(find.byType(PaywallScreen), findsNothing);
    });

    testWidgets('кнопка закрытия (X) закрывает экран', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createPaywallPushedApp());
      await tester.pumpAndSettle();

      // Открываем PaywallScreen
      await tester.tap(find.text('Open Paywall'));
      await tester.pumpAndSettle();

      // Проверяем, что PaywallScreen отображается
      expect(find.byType(PaywallScreen), findsOneWidget);

      // Нажимаем кнопку закрытия
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsNothing);
    });
  });
}
