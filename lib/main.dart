import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app/theme.dart';
import 'data/database_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация FFI database factory для Windows/Desktop
  databaseFactory = databaseFactoryFfi;

  // Ориентация только portrait (для мобильных платформ)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize the database before running the app
  _initApp();
}

Future<void> _initApp() async {
  try {
    await DatabaseProvider.instance();
  } catch (e) {
    // Database initialization failure is logged but doesn't block the app
    debugPrint('Database initialization failed: $e');
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
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
