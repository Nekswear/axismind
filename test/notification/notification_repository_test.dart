// =============================================================================
// ZenBalance — Unit-тесты для NotificationRepository
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ЗАПУСК ТЕСТОВ                                  ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║  flutter test test/notification/notification_repository_test.dart        ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Проверяет:
//   • getSettings — возвращает default при пустой БД
//   • saveSettings — сохраняет и читает настройки
//   • saveFcmToken / getFcmToken
//   • canShowNotification
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenbalance/data/database_provider.dart';
import 'package:zenbalance/data/notification_repository.dart';
import 'package:zenbalance/data/notification_settings.dart';

/// Создаёт in-memory DatabaseProvider для тестов.
Future<DatabaseProvider> createTestDbProvider() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactory.openDatabase(
    ':memory:',
    options: OpenDatabaseOptions(
      version: 7,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notification_settings (
            id TEXT PRIMARY KEY DEFAULT 'default',
            enabled INTEGER NOT NULL DEFAULT 1,
            reminder_time TEXT NOT NULL DEFAULT '08:00',
            motivational_enabled INTEGER NOT NULL DEFAULT 0,
            motivational_time TEXT NOT NULL DEFAULT '12:00',
            goal_reminder_enabled INTEGER NOT NULL DEFAULT 0,
            goal_reminder_time TEXT NOT NULL DEFAULT '19:00',
            quiet_hours_start TEXT,
            quiet_hours_end TEXT,
            fcm_token TEXT,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    ),
  );

  return DatabaseProvider.forTest(db);
}

void main() {
  late DatabaseProvider dbProvider;
  late NotificationRepository repo;

  setUp(() async {
    dbProvider = await createTestDbProvider();
    repo = NotificationRepository(dbProvider);
  });

  tearDown(() async {
    await dbProvider.close();
  });

  group('📥 getSettings', () {
    test('возвращает настройки по умолчанию, если БД пуста', () async {
      final settings = await repo.getSettings();

      expect(settings.id, equals('default'));
      expect(settings.enabled, isTrue);
      expect(settings.reminderTime, equals('08:00'));
      expect(settings.motivationalEnabled, isFalse);
      expect(settings.motivationalTime, equals('12:00'));
      expect(settings.goalReminderEnabled, isFalse);
      expect(settings.goalReminderTime, equals('19:00'));
    });
  });

  group('💾 saveSettings + getSettings', () {
    test('сохраняет и читает настройки', () async {
      final original = NotificationSettings(
        enabled: false,
        reminderTime: '10:00',
        motivationalEnabled: true,
        motivationalTime: '14:30',
        goalReminderEnabled: true,
        goalReminderTime: '21:00',
        quietHoursStart: '23:00',
        quietHoursEnd: '06:00',
        fcmToken: 'test_token',
        updatedAt: DateTime(2026, 5, 20, 12, 0, 0),
      );

      await repo.saveSettings(original);
      final loaded = await repo.getSettings();

      expect(loaded.enabled, isFalse);
      expect(loaded.reminderTime, equals('10:00'));
      expect(loaded.motivationalEnabled, isTrue);
      expect(loaded.motivationalTime, equals('14:30'));
      expect(loaded.goalReminderEnabled, isTrue);
      expect(loaded.goalReminderTime, equals('21:00'));
      expect(loaded.quietHoursStart, equals('23:00'));
      expect(loaded.quietHoursEnd, equals('06:00'));
      expect(loaded.fcmToken, equals('test_token'));
    });

    test('перезаписывает существующие настройки', () async {
      final first = NotificationSettings(
        enabled: true,
        reminderTime: '08:00',
        updatedAt: DateTime(2026, 5, 20, 10, 0),
      );
      await repo.saveSettings(first);

      final second = NotificationSettings(
        enabled: false,
        reminderTime: '20:00',
        motivationalEnabled: true,
        motivationalTime: '16:00',
        goalReminderEnabled: true,
        goalReminderTime: '22:00',
        updatedAt: DateTime(2026, 5, 20, 11, 0),
      );
      await repo.saveSettings(second);

      final loaded = await repo.getSettings();
      expect(loaded.enabled, isFalse);
      expect(loaded.reminderTime, equals('20:00'));
      expect(loaded.motivationalTime, equals('16:00'));
      expect(loaded.goalReminderTime, equals('22:00'));
    });
  });

  group('🔑 FCM token', () {
    test('saveFcmToken и getFcmToken', () async {
      // Токена ещё нет
      expect(await repo.getFcmToken(), isNull);

      // Сохраняем
      await repo.saveFcmToken('my_fcm_token_123');
      final token = await repo.getFcmToken();
      expect(token, equals('my_fcm_token_123'));

      // Перезаписываем
      await repo.saveFcmToken('new_token_456');
      final updated = await repo.getFcmToken();
      expect(updated, equals('new_token_456'));
    });
  });

  group('🔇 canShowNotification', () {
    test('возвращает false, если уведомления отключены', () {
      final settings = NotificationSettings(
        enabled: false,
        updatedAt: DateTime(2026, 5, 20),
      );
      expect(repo.canShowNotification(settings), isFalse);
    });

    test('возвращает false, если сейчас тихие часы', () {
      // Предположим, что сейчас 3:00 ночи
      final settings = NotificationSettings(
        enabled: true,
        quietHoursStart: '22:00',
        quietHoursEnd: '07:00',
        updatedAt: DateTime(2026, 5, 20),
      );
      // isInQuietHours использует DateTime.now(), поэтому canShowNotification
      // может вернуть true/false в зависимости от реального времени.
      // Проверяем только логику: если isInQuietHours == true → false
      final now = DateTime.now();
      if (settings.isInQuietHours(now)) {
        expect(repo.canShowNotification(settings), isFalse);
      } else {
        expect(repo.canShowNotification(settings), isTrue);
      }
    });

    test('возвращает true, если уведомления включены и не тихие часы', () {
      final settings = NotificationSettings(
        enabled: true,
        updatedAt: DateTime(2026, 5, 20),
      );
      // Без тихих часов всегда true
      expect(repo.canShowNotification(settings), isTrue);
    });
  });
}
