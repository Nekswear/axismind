// =============================================================================
// ZenBalance — Unit-тесты для SubscriptionRepository
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ЗАПУСК ТЕСТОВ                                  ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║  flutter test test/subscription/subscription_repository_test.dart        ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Проверяет:
//   • getStatus() возвращает неактивный статус, если записи нет
//   • saveStatus() + getStatus() roundtrip
//   • clearStatus() удаляет запись
//   • UPSERT: повторный saveStatus() перезаписывает
//   • Полный цикл с активной подпиской (isActive=true, isTrial=true)
//   • Обработка ошибок БД (закрытая БД)
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenbalance/data/database_provider.dart';
import 'package:zenbalance/data/subscription_repository.dart';
import 'package:zenbalance/data/subscription_status.dart';

// =============================================================================
// 1. ТЕСТОВОЕ ОКРУЖЕНИЕ (In-Memory SQLite)
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

/// Создаёт [DatabaseProvider] с тестовой in-memory БД.
DatabaseProvider createTestProvider(Database db) {
  return DatabaseProvider.forTest(db);
}

/// Создаёт [SubscriptionRepository] с тестовым провайдером.
SubscriptionRepository createTestRepository(DatabaseProvider provider) {
  return SubscriptionRepository(provider);
}

// =============================================================================
// 2. ТЕСТЫ
// =============================================================================

void main() {
  // ---------------------------------------------------------------------------
  // 2.1 getStatus — запись не найдена
  // ---------------------------------------------------------------------------
  group('getStatus() — запись не найдена', () {
    late Database db;
    late SubscriptionRepository repository;

    setUp(() async {
      db = await createTestDatabase();
      repository = createTestRepository(createTestProvider(db));
    });

    tearDown(() async {
      await db.close();
    });

    test('должен возвращать статус с isActive=false, если записи нет', () async {
      final status = await repository.getStatus();

      expect(status.isActive, false);
      expect(status.isTrial, false);
      expect(status.id, 'default');
      expect(status.expirationDate, isNull);
      expect(status.productId, isNull);
      expect(status.purchasedAt, isNull);
      expect(status.updatedAt, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 2.2 saveStatus + getStatus roundtrip
  // ---------------------------------------------------------------------------
  group('saveStatus() + getStatus() roundtrip', () {
    late Database db;
    late SubscriptionRepository repository;

    setUp(() async {
      db = await createTestDatabase();
      repository = createTestRepository(createTestProvider(db));
    });

    tearDown(() async {
      await db.close();
    });

    test('должен сохранять и возвращать неактивный статус', () async {
      final original = SubscriptionStatus(updatedAt: DateTime(2025, 6, 1));

      await repository.saveStatus(original);
      final loaded = await repository.getStatus();

      expect(loaded.id, original.id);
      expect(loaded.isActive, original.isActive);
      expect(loaded.isTrial, original.isTrial);
      expect(loaded.expirationDate, original.expirationDate);
      expect(loaded.productId, original.productId);
      expect(loaded.purchasedAt, original.purchasedAt);
      expect(loaded.updatedAt, original.updatedAt);
    });

    test('должен сохранять и возвращать активный статус с подпиской', () async {
      final original = SubscriptionStatus(
        isActive: true,
        isTrial: true,
        expirationDate: DateTime(2025, 7, 1),
        productId: 'premium_monthly_trial',
        purchasedAt: DateTime(2025, 6, 1),
        updatedAt: DateTime(2025, 6, 1, 12, 0, 0),
      );

      await repository.saveStatus(original);
      final loaded = await repository.getStatus();

      expect(loaded.isActive, true);
      expect(loaded.isTrial, true);
      expect(loaded.expirationDate, DateTime(2025, 7, 1));
      expect(loaded.productId, 'premium_monthly_trial');
      expect(loaded.purchasedAt, DateTime(2025, 6, 1));
      expect(loaded.updatedAt, DateTime(2025, 6, 1, 12, 0, 0));
    });

    test('должен сохранять и возвращать активный статус без пробного периода',
        () async {
      final original = SubscriptionStatus(
        isActive: true,
        isTrial: false,
        expirationDate: DateTime(2025, 8, 1),
        productId: 'premium_monthly',
        purchasedAt: DateTime(2025, 5, 1),
        updatedAt: DateTime(2025, 5, 1),
      );

      await repository.saveStatus(original);
      final loaded = await repository.getStatus();

      expect(loaded.isActive, true);
      expect(loaded.isTrial, false);
      expect(loaded.productId, 'premium_monthly');
    });

    test('должен сохранять статус с null датами', () async {
      final original = SubscriptionStatus(
        isActive: true,
        isTrial: false,
        expirationDate: null,
        productId: 'premium_monthly',
        purchasedAt: null,
        updatedAt: DateTime(2025, 6, 1),
      );

      await repository.saveStatus(original);
      final loaded = await repository.getStatus();

      expect(loaded.isActive, true);
      expect(loaded.expirationDate, isNull);
      expect(loaded.purchasedAt, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 2.3 clearStatus
  // ---------------------------------------------------------------------------
  group('clearStatus()', () {
    late Database db;
    late SubscriptionRepository repository;

    setUp(() async {
      db = await createTestDatabase();
      repository = createTestRepository(createTestProvider(db));
    });

    tearDown(() async {
      await db.close();
    });

    test('должен удалять запись и возвращать неактивный статус', () async {
      // Сохраняем активный статус
      await repository.saveStatus(
        SubscriptionStatus(
          isActive: true,
          updatedAt: DateTime(2025, 6, 1),
        ),
      );

      // Очищаем
      await repository.clearStatus();

      // После очистки должен вернуться неактивный статус
      final status = await repository.getStatus();
      expect(status.isActive, false);
      expect(status.isTrial, false);
    });

    test('должен работать, даже если записи нет (не должно быть ошибки)',
        () async {
      // Очищаем без предварительного сохранения
      await repository.clearStatus();

      // После очистки должен вернуться неактивный статус
      final status = await repository.getStatus();
      expect(status.isActive, false);
    });
  });

  // ---------------------------------------------------------------------------
  // 2.4 UPSERT — повторный saveStatus перезаписывает
  // ---------------------------------------------------------------------------
  group('UPSERT — повторный saveStatus()', () {
    late Database db;
    late SubscriptionRepository repository;

    setUp(() async {
      db = await createTestDatabase();
      repository = createTestRepository(createTestProvider(db));
    });

    tearDown(() async {
      await db.close();
    });

    test('должен перезаписывать существующую запись (UPSERT)', () async {
      // Сохраняем первый статус
      await repository.saveStatus(
        SubscriptionStatus(
          isActive: true,
          isTrial: true,
          productId: 'trial_v1',
          updatedAt: DateTime(2025, 6, 1),
        ),
      );

      // Сохраняем второй статус (тот же id 'default')
      await repository.saveStatus(
        SubscriptionStatus(
          isActive: true,
          isTrial: false,
          productId: 'paid_v2',
          expirationDate: DateTime(2025, 7, 1),
          updatedAt: DateTime(2025, 6, 15),
        ),
      );

      // Должна быть только одна запись с обновлёнными данными
      final status = await repository.getStatus();
      expect(status.isActive, true);
      expect(status.isTrial, false);
      expect(status.productId, 'paid_v2');
      expect(status.expirationDate, DateTime(2025, 7, 1));
      expect(status.updatedAt, DateTime(2025, 6, 15));
    });
  });

  // ---------------------------------------------------------------------------
  // 2.5 Обработка ошибок БД
  // ---------------------------------------------------------------------------
  group('Обработка ошибок БД', () {
    late Database db;
    late SubscriptionRepository repository;

    setUp(() async {
      db = await createTestDatabase();
      repository = createTestRepository(createTestProvider(db));
    });

    tearDown(() async {
      await db.close();
    });

    test('getStatus не должен выбрасывать исключение при закрытой БД', () async {
      // Закрываем БД
      await db.close();

      // Должен вернуть неактивный статус без исключения
      final status = await repository.getStatus();
      expect(status.isActive, false);
    });

    test('saveStatus не должен выбрасывать исключение при закрытой БД',
        () async {
      await db.close();

      // Должен выполниться без исключения
      await repository.saveStatus(
        SubscriptionStatus(updatedAt: DateTime(2025, 6, 1)),
      );
    });

    test('clearStatus не должен выбрасывать исключение при закрытой БД',
        () async {
      await db.close();

      // Должен выполниться без исключения
      await repository.clearStatus();
    });
  });

  // ---------------------------------------------------------------------------
  // 2.6 Полный жизненный цикл
  // ---------------------------------------------------------------------------
  group('Полный жизненный цикл подписки', () {
    late Database db;
    late SubscriptionRepository repository;

    setUp(() async {
      db = await createTestDatabase();
      repository = createTestRepository(createTestProvider(db));
    });

    tearDown(() async {
      await db.close();
    });

    test('должен корректно проходить цикл: пусто → активна → обновлена → очищена',
        () async {
      // Шаг 1: Пустая БД — неактивный статус
      var status = await repository.getStatus();
      expect(status.isActive, false);

      // Шаг 2: Покупка подписки (пробный период)
      await repository.saveStatus(
        SubscriptionStatus(
          isActive: true,
          isTrial: true,
          expirationDate: DateTime(2025, 6, 8),
          productId: 'premium_monthly_trial',
          purchasedAt: DateTime(2025, 6, 1),
          updatedAt: DateTime(2025, 6, 1),
        ),
      );
      status = await repository.getStatus();
      expect(status.isActive, true);
      expect(status.isTrial, true);

      // Шаг 3: Пробный период закончился, подписка активна (оплачена)
      await repository.saveStatus(
        SubscriptionStatus(
          isActive: true,
          isTrial: false,
          expirationDate: DateTime(2025, 7, 1),
          productId: 'premium_monthly',
          purchasedAt: DateTime(2025, 6, 1),
          updatedAt: DateTime(2025, 6, 8),
        ),
      );
      status = await repository.getStatus();
      expect(status.isActive, true);
      expect(status.isTrial, false);
      expect(status.productId, 'premium_monthly');

      // Шаг 4: Подписка истекла
      await repository.saveStatus(
        SubscriptionStatus(
          isActive: false,
          isTrial: false,
          expirationDate: DateTime(2025, 7, 1),
          productId: 'premium_monthly',
          purchasedAt: DateTime(2025, 6, 1),
          updatedAt: DateTime(2025, 7, 2),
        ),
      );
      status = await repository.getStatus();
      expect(status.isActive, false);

      // Шаг 5: Очистка
      await repository.clearStatus();
      status = await repository.getStatus();
      expect(status.isActive, false);
      expect(status.productId, isNull);
    });
  });
}
