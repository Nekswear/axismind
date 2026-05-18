import 'package:flutter/foundation.dart';

import '../data/database_provider.dart';
import '../data/goals_repository.dart';
import '../data/sync_repository.dart';
import 'auth_service.dart';

/// Единый сервис-локатор для ZenBalance.
///
/// Предоставляет синглтоны всех сервисов приложения.
/// Инициализируется один раз в [AppServiceLocator.initialize].
/// После инициализации сервисы доступны через геттеры.
class AppServiceLocator {
  AppServiceLocator._();

  static AppServiceLocator? _instance;

  /// Единственный экземпляр сервис-локатора.
  static AppServiceLocator get instance {
    if (_instance == null) {
      throw StateError(
        'AppServiceLocator not initialized. Call AppServiceLocator.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Инициализирует все сервисы приложения.
  ///
  /// Должен быть вызван один раз перед [runApp].
  /// Возвращает `true`, если инициализация прошла успешно,
  /// `false` — если хотя бы один сервис не удалось инициализировать.
  static Future<bool> initialize() async {
    if (_instance != null) return true;

    final locator = AppServiceLocator._();
    bool allOk = true;

    // Инициализация БД
    try {
      locator._db = await DatabaseProvider.instance();
    } catch (e) {
      debugPrint('Database initialization failed: $e');
      allOk = false;
    }

    // Инициализация AuthService (Firebase)
    try {
      locator._authService = AuthService();
    } catch (e) {
      debugPrint('AuthService initialization failed: $e');
      allOk = false;
    }

    // Инициализация SyncRepository (только если БД и Auth доступны)
    if (locator._db != null && locator._authService != null) {
      locator._syncRepo = SyncRepository(
        localDb: locator._db!,
        auth: locator._authService!,
      );
    }

    // Инициализация GoalsRepository (только если БД доступна)
    if (locator._db != null) {
      locator._goalsRepo = GoalsRepository(locator._db!);
    }

    _instance = locator;
    return allOk;
  }

  DatabaseProvider? _db;
  AuthService? _authService;
  SyncRepository? _syncRepo;
  GoalsRepository? _goalsRepo;

  /// DatabaseProvider (может быть null, если БД не инициализирована).
  DatabaseProvider? get db => _db;

  /// AuthService (может быть null, если Firebase не инициализирован).
  AuthService? get authService => _authService;

  /// SyncRepository (может быть null, если БД не инициализирована).
  SyncRepository? get syncRepo => _syncRepo;

  /// GoalsRepository (может быть null, если БД не инициализирована).
  GoalsRepository? get goalsRepo => _goalsRepo;

  /// Wakelock поддерживается только на мобильных платформах.
  static bool get isWakelockSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}
