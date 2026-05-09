import 'package:flutter_test/flutter_test.dart';

import 'package:zenbalance/main.dart';

void main() {
  testWidgets('ZenBalance app displays welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ZenBalanceApp());

    // Проверяем, что заголовок отображается
    expect(find.text('ZenBalance'), findsOneWidget);

    // Приветствие теперь динамическое — показывается "Загрузка..." или финальный ранг
    // Проверяем, что хотя бы один из вариантов отображается
    final greetingFinder = find.text('Приветствую, Новичок осознанности');
    final loadingFinder = find.text('Загрузка...');
    expect(
      greetingFinder.evaluate().isNotEmpty ||
          loadingFinder.evaluate().isNotEmpty,
      isTrue,
      reason:
          'Ожидается либо "Загрузка...", либо "Приветствую, {ранг}" после загрузки',
    );

    // Проверяем кнопку
    expect(find.text('Начать практику'), findsOneWidget);
  });
}
