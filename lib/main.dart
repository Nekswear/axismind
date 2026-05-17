import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/theme/zen_theme.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/app_service_locator.dart';

/// Главная точка входа.
///
/// 1. Инициализирует Firebase (через Firebase.initializeApp)
/// 2. Инициализирует сервисы (БД, Auth) через AppServiceLocator
/// 3. Показывает экран загрузки, пока сервисы не готовы
/// 4. Если что-то не загрузилось — приложение всё равно работает,
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
      home: const HomeScreen(),
    );
  }
}
