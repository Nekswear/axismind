import 'package:flutter_test/flutter_test.dart';

import 'package:axismind/main.dart';

void main() {
  testWidgets('AxisMind app displays welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AxisMindApp());

    // В состоянии загрузки отображается скелетон (ранг ещё не загружен)
    // Проверяем, что кнопка "Начать практику" присутствует
    expect(find.text('START PRACTICE'), findsOneWidget);

    // Проверяем, что пресеты длительности отображаются
    expect(find.text('Choose duration'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('20 min'), findsOneWidget);

    // Проверяем вторичные кнопки
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('OPEN PATH TO CLARITY'), findsOneWidget);
  });
}
