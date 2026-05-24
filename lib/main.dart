import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/zen_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/app_service_locator.dart';
import 'services/notification_service.dart';

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

  // Инициализируем Firebase (нужен для AuthService и Firestore)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[MAIN] Firebase initialized successfully');
  } catch (e) {
    debugPrint('[MAIN] Firebase initialization failed (non-fatal): $e');
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
    debugPrint('[MAIN] NotificationService initialization failed (non-fatal): $e');
  }

  runApp(const ZenBalanceApp());
}

class ZenBalanceApp extends StatelessWidget {
  const ZenBalanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZenBalance',
      debugShowCheckedModeBanner: false,
      theme: ZenTheme.build(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
      ],
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
      home: const HomeScreen(),
    );
  }
}
