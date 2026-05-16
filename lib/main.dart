import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'core/theme/zen_theme.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/app_service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация database factory в зависимости от платформы
  if (kIsWeb) {
    // Web — используем WebAssembly SQLite
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
             defaultTargetPlatform == TargetPlatform.linux ||
             defaultTargetPlatform == TargetPlatform.macOS) {
    // Desktop (Windows/Linux/macOS) — используем FFI SQLite
    databaseFactory = databaseFactoryFfi;
  }
  // Android/iOS — используют стандартный sqflite (нативный плагин), factory не меняем

  // Ориентация только portrait (для мобильных платформ)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Инициализируем все сервисы перед запуском приложения
  await _initServices();

  runApp(const ZenBalanceApp());
}

Future<void> _initServices() async {
  // Инициализация Firebase (может упасть на неподдерживаемых платформах)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase initialization may fail on unsupported platforms (e.g. Windows)
    // App continues to work with local-only mode
    debugPrint('Firebase initialization failed (local-only mode): $e');
  }

  // Инициализация AppServiceLocator (БД + сервисы)
  await AppServiceLocator.initialize();
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
