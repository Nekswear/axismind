import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'core/theme/zen_theme.dart';
import 'data/database_provider.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация database factory в зависимости от платформы
  if (kIsWeb) {
    // Web — используем WebAssembly SQLite
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    // Desktop (Windows/Linux/macOS) — используем FFI SQLite
    databaseFactory = databaseFactoryFfi;
  }

  // Ориентация только portrait (для мобильных платформ)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize the database and Firebase before running the app
  _initApp();
}

Future<void> _initApp() async {
  try {
    await DatabaseProvider.instance();
  } catch (e) {
    // Database initialization failure is logged but doesn't block the app
    debugPrint('Database initialization failed: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase initialization may fail on unsupported platforms (e.g. Windows)
    // App continues to work with local-only mode
    debugPrint('Firebase initialization failed (local-only mode): $e');
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
      home: const HomeScreen(),
    );
  }
}
