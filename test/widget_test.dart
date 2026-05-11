import 'package:flutter_test/flutter_test.dart';

import 'package:zenbalance/main.dart';

void main() {
  testWidgets('ZenBalance app displays welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ZenBalanceApp());

    // В состоянии загрузки отображается скелетон (ранг ещё не загружен)
    // Проверяем, что кнопка "Начать практику" присутствует
    expect(find.text('Начать практику'), findsOneWidget);

    // Проверяем, что пресеты длительности отображаются
    expect(find.text('Выбери длительность:'), findsOneWidget);
    expect(find.text('5 мин'), findsOneWidget);
    expect(find.text('10 мин'), findsOneWidget);
    expect(find.text('15 мин'), findsOneWidget);
    expect(find.text('20 мин'), findsOneWidget);

    // Проверяем вторичные кнопки
    expect(find.text('Статистика'), findsOneWidget);
    expect(find.text('ОТКРЫТЬ ПУТЬ К ЯСНОСТИ'), findsOneWidget);
  });
}
