 import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:axismind/core/theme/zen_theme.dart';
import 'package:axismind/l10n/app_localizations.dart';
import 'package:axismind/main.dart';
import 'package:axismind/screens/onboarding_screen.dart';

import 'package:axismind/screens/widgets/neuro_preset_info.dart';

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
  testWidgets('OnboardingScreen displays English text in English locale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ru')],
        theme: ZenTheme.build(),
        home: const OnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Mindfulness and Peace'), findsOneWidget);
    expect(
      find.text(
        'Welcome to AxisMind. Discover your inner balance through regular meditation and focus practices.',
      ),
      findsOneWidget,
    );

    // Tap Next
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Breathing Practices'), findsOneWidget);

    // Tap Next again
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Sync and Progress'), findsOneWidget);
    expect(find.text('Start Practice'), findsOneWidget);
  });

  testWidgets('OnboardingScreen displays Russian text in Russian locale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ru')],
        theme: ZenTheme.build(),
        home: const OnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Пропустить'), findsOneWidget);
    expect(find.text('Далее'), findsOneWidget);
    expect(find.text('Осознанность и покой'), findsOneWidget);

    // Tap Next
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    expect(find.text('Дыхательные практики'), findsOneWidget);

    // Tap Next again
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    expect(find.text('Синхронизация и прогресс'), findsOneWidget);
    expect(find.text('Начать практику'), findsOneWidget);
  });


  testWidgets('NeuroPresetInfo displays English descriptions in English locale', (
    WidgetTester tester,
  ) async {
    Widget buildPresetWidget(int minutes) {
      return MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ru')],
        theme: ZenTheme.build(),
        home: Scaffold(
          body: NeuroPresetInfo(minutes: minutes),
        ),
      );
    }

    await tester.pumpWidget(buildPresetWidget(5));
    await tester.pumpAndSettle();
    expect(find.textContaining('Stopping «mental noise»'), findsOneWidget);
    expect(find.textContaining('Rapid return of attentional control'), findsOneWidget);

    await tester.pumpWidget(buildPresetWidget(10));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reduction of physical tension'), findsOneWidget);
    expect(find.textContaining('Deep ordering of mental activity'), findsOneWidget);

    await tester.pumpWidget(buildPresetWidget(15));
    await tester.pumpAndSettle();
    expect(find.textContaining('Deep stabilization of perception'), findsOneWidget);

    await tester.pumpWidget(buildPresetWidget(20));
    await tester.pumpAndSettle();
    expect(find.textContaining('Classic Zen training'), findsOneWidget);
  });

  testWidgets('NeuroPresetInfo displays Russian descriptions in Russian locale', (
    WidgetTester tester,
  ) async {
    Widget buildPresetWidget(int minutes) {
      return MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ru')],
        theme: ZenTheme.build(),
        home: Scaffold(
          body: NeuroPresetInfo(minutes: minutes),
        ),
      );
    }

    await tester.pumpWidget(buildPresetWidget(5));
    await tester.pumpAndSettle();
    expect(find.textContaining('Остановка «мысленного шума»'), findsOneWidget);
    expect(find.textContaining('Быстрый возврат контроля над вниманием'), findsOneWidget);

    await tester.pumpWidget(buildPresetWidget(10));
    await tester.pumpAndSettle();
    expect(find.textContaining('Снижение физического напряжения'), findsOneWidget);

    await tester.pumpWidget(buildPresetWidget(15));
    await tester.pumpAndSettle();
    expect(find.textContaining('Глубокая стабилизация восприятия'), findsOneWidget);

    await tester.pumpWidget(buildPresetWidget(20));
    await tester.pumpAndSettle();
    expect(find.textContaining('Классическая Дзен-тренировка'), findsOneWidget);
  });
}
