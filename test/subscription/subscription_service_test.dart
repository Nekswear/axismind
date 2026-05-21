// =============================================================================
// ZenBalance — Unit-тесты для SubscriptionService
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ЗАПУСК ТЕСТОВ                                  ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║  flutter test test/subscription/subscription_service_test.dart           ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Проверяет:
//   • _parseDate — парсинг дат от RevenueCat
//   • currentStatus / isPremium — синхронный доступ к статусу
//   • statusStream — поток статуса
//   • init() — загрузка кэшированного статуса
//   • init() — graceful fallback при ошибке RevenueCat
//   • purchaseSubscription — graceful fallback при ошибке
//   • restorePurchases — graceful fallback при ошибке
//   • getSubscriptionPrice — fallback цена при ошибке
//   • dispose — закрытие стрима
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenbalance/data/database_provider.dart';
import 'package:zenbalance/data/subscription_repository.dart';
import 'package:zenbalance/data/subscription_status.dart';
import 'package:zenbalance/services/subscription_service.dart';

// =============================================================================
// 1. ТЕСТОВОЕ ОКРУЖЕНИЕ
// =============================================================================

/// Создаёт in-memory SQLite базу с таблицей subscription.
Future<Database> createTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactory.openDatabase(
    ':memory:',
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE subscription (
            id TEXT PRIMARY KEY DEFAULT 'default',
            is_active INTEGER NOT NULL DEFAULT 0,
            is_trial INTEGER NOT NULL DEFAULT 0,
            expiration_date TEXT,
            product_id TEXT,
            purchased_at TEXT,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    ),
  );
  return db;
}

/// Создаёт [SubscriptionRepository] с тестовой in-memory БД.
Future<SubscriptionRepository> createTestRepository(Database db) async {
  final provider = DatabaseProvider.forTest(db);
  return SubscriptionRepository(provider);
}

// =============================================================================
// 2. ТЕСТЫ
// =============================================================================

void main() {
  // ---------------------------------------------------------------------------
  // 2.1 _parseDate — парсинг дат от RevenueCat
  // ---------------------------------------------------------------------------
  group('_parseDate — парсинг дат от RevenueCat', () {
    test('должен парсить валидную ISO 8601 строку', () {
      final result = SubscriptionService.parseDate('2025-06-01T12:00:00.000Z');
      expect(result, isNotNull);
      expect(result!.year, 2025);
      expect(result.month, 6);
      expect(result.day, 1);
      expect(result.hour, 12);
    });

    test('должен возвращать null для null входа', () {
      final result = SubscriptionService.parseDate(null);
      expect(result, isNull);
    });

    test('должен возвращать null для пустой строки', () {
      final result = SubscriptionService.parseDate('');
      expect(result, isNull);
    });

    test('должен возвращать null для невалидной строки', () {
      final result = SubscriptionService.parseDate('not-a-date');
      expect(result, isNull);
    });

    test('должен парсить дату без времени', () {
      final result = SubscriptionService.parseDate('2025-06-01');
      expect(result, isNotNull);
      expect(result!.year, 2025);
      expect(result.month, 6);
      expect(result.day, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // 2.2 currentStatus / isPremium — синхронный доступ
  // ---------------------------------------------------------------------------
  group('currentStatus / isPremium — синхронный доступ', () {
    test('изначально статус неактивный', () {
      final service = SubscriptionService.instance;
      expect(service.isPremium, false);
      expect(service.currentStatus.isActive, false);
    });

    test('isPremium возвращает false для неактивного статуса', () {
      final service = SubscriptionService.instance;
      // Статус по умолчанию — неактивный
      expect(service.isPremium, false);
    });
  });

  // ---------------------------------------------------------------------------
  // 2.3 statusStream — поток статуса
  // ---------------------------------------------------------------------------
  group('statusStream — поток статуса', () {
    test('стрим должен быть broadcast (можно слушать несколько раз)', () {
      final service = SubscriptionService.instance;
      // broadcast stream позволяет множественные подписки
      expect(service.statusStream.isBroadcast, true);
    });

    test('стрим отправляет начальный статус после init', () async {
      final db = await createTestDatabase();
      final repo = await createTestRepository(db);

      final service = SubscriptionService.instance;

      // Подписываемся до init
      final statuses = <SubscriptionStatus>[];
      final subscription = service.statusStream.listen((status) {
        statuses.add(status);
      });

      // init загрузит кэш (пустой → неактивный)
      await service.init(repo);

      // Небольшая пауза для обработки стрима
      await Future.delayed(const Duration(milliseconds: 50));

      expect(statuses.length, greaterThanOrEqualTo(1));
      expect(statuses.first.isActive, false);

      await subscription.cancel();
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // 2.4 init() — загрузка кэшированного статуса
  // ---------------------------------------------------------------------------
  group('init() — загрузка кэшированного статуса', () {
    test('должен загружать активный статус из кэша', () async {
      final db = await createTestDatabase();
      final repo = await createTestRepository(db);

      // Сохраняем активный статус в БД
      await repo.saveStatus(
        SubscriptionStatus(
          isActive: true,
          isTrial: true,
          productId: 'premium_monthly_trial',
          expirationDate: DateTime(2025, 7, 1),
          updatedAt: DateTime(2025, 6, 1),
        ),
      );

      final service = SubscriptionService.instance;
      await service.init(repo);

      expect(service.isPremium, true);
      expect(service.currentStatus.isActive, true);
      expect(service.currentStatus.isTrial, true);
      expect(service.currentStatus.productId, 'premium_monthly_trial');

      await db.close();
    });

    test('должен загружать неактивный статус из пустой БД', () async {
      final db = await createTestDatabase();
      final repo = await createTestRepository(db);

      final service = SubscriptionService.instance;
      await service.init(repo);

      expect(service.isPremium, false);
      expect(service.currentStatus.isActive, false);

      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // 2.5 init() — graceful fallback при ошибке RevenueCat
  // ---------------------------------------------------------------------------
  group('init() — graceful fallback при ошибке RevenueCat', () {
    test('не должен выбрасывать исключение при ошибке RevenueCat', () async {
      final db = await createTestDatabase();
      final repo = await createTestRepository(db);

      // RevenueCat не инициализирован — Purchases.configure() выбросит ошибку.
      // Сервис должен перехватить её и продолжить с кэшированным статусом.
      final service = SubscriptionService.instance;

      // Не должно быть исключения
      await service.init(repo);

      // Статус должен быть загружен из кэша (пустая БД → неактивный)
      expect(service.isPremium, false);

      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // 2.6 purchaseSubscription — graceful fallback при ошибке
  // ---------------------------------------------------------------------------
  group('purchaseSubscription — graceful fallback', () {
    test('должен возвращать false при ошибке RevenueCat', () async {
      final db = await createTestDatabase();
      final repo = await createTestRepository(db);

      final service = SubscriptionService.instance;
      await service.init(repo);

      // RevenueCat не настроен — purchaseSubscription вернёт false
      final result = await service.purchaseSubscription();
      expect(result, false);

      // Статус не должен измениться
      expect(service.isPremium, false);

      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // 2.7 restorePurchases — graceful fallback при ошибке
  // ---------------------------------------------------------------------------
  group('restorePurchases — graceful fallback', () {
    test('должен возвращать false при ошибке RevenueCat', () async {
      final db = await createTestDatabase();
      final repo = await createTestRepository(db);

      final service = SubscriptionService.instance;
      await service.init(repo);

      // RevenueCat не настроен — restorePurchases вернёт false
      final result = await service.restorePurchases();
      expect(result, false);

      // Статус не должен измениться
      expect(service.isPremium, false);

      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // 2.8 getSubscriptionPrice — fallback цена при ошибке
  // ---------------------------------------------------------------------------
  group('getSubscriptionPrice — fallback цена', () {
    test('должен возвращать цену по умолчанию при ошибке RevenueCat', () async {
      final db = await createTestDatabase();
      final repo = await createTestRepository(db);

      final service = SubscriptionService.instance;
      await service.init(repo);

      // RevenueCat не настроен — вернётся fallback цена
      final price = await service.getSubscriptionPrice();
      expect(price, '\$7.00/месяц');

      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // 2.9 dispose — закрытие стрима
  // ---------------------------------------------------------------------------
  group('dispose — закрытие стрима', () {
    test('dispose не должен выбрасывать исключение', () {
      final service = SubscriptionService.instance;
      // Не должно быть исключения
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
