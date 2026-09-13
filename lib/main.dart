import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/zen_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_service_locator.dart';
import 'services/notification_service.dart';
import 'services/onboarding_service.dart';

/// Главная точка входа.
///
/// 1. Инициализирует Firebase (через Firebase.initializeApp)
/// 2. Инициализирует сервисы (БД, Auth) через AppServiceLocator
/// 3. Инициализирует NotificationService (FCM + локальные уведомления)
/// 4. Показывает экран загрузки, пока сервисы не готовы
/// 5. Если что-то не загрузилось — приложение всё равно работает,
///    экраны показывают fallback-состояния
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем Firebase (нужен для AuthService и Firestore).
  // На Android с google-services.json можно вызывать без options.
  try {
    await Firebase.initializeApp();
    debugPrint('[MAIN] Firebase initialized successfully');
  } catch (e) {
    try {
      // Fallback: пробуем с options (для платформ без google-services.json)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[MAIN] Firebase initialized with options');
    } catch (e2) {
      debugPrint('[MAIN] Firebase initialization failed (non-fatal): $e2');
    }
  }

  // Инициализируем сервисы (БД, Auth, SyncRepository)
  // AppServiceLocator.initialize() уже содержит try/catch внутри
  await AppServiceLocator.initialize();

  // Инициализируем сервис пуш-уведомлений (FCM + локальные уведомления)
  // Должен быть после Firebase.initializeApp()
  try {
    await NotificationService.instance.init();
    debugPrint('[MAIN] NotificationService initialized successfully');
  } catch (e) {
    debugPrint(
      '[MAIN] NotificationService initialization failed (non-fatal): $e',
    );
  }

  final showOnboarding = await OnboardingService().shouldShow();
  runApp(AxisMindApp(showOnboarding: showOnboarding));
}

class AxisMindApp extends StatelessWidget {
  final bool showOnboarding;

  const AxisMindApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AxisMind',
      debugShowCheckedModeBanner: false,
      theme: ZenTheme.build(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru')],
      localeResolutionCallback: (locale, supportedLocales) {
        // Если язык системы не поддерживается — используем английский
        if (locale == null) return const Locale('en');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }
        return const Locale('en');
      },
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
