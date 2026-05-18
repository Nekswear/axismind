// =============================================================================
// ZenBalance — Юнит-тест повышения уровня (Level-Up Event)
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ИНСТРУКЦИЯ ПО ЗАПУСКУ                          ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║                                                                        ║
// ║  Запуск теста:                                                         ║
// ║    flutter test test/domain/level_up_test.dart                         ║
// ║                                                                        ║
// ║  Что проверяется:                                                      ║
// ║    • Повышение уровня с 0 до 1 при достижении 11 минут                ║
// ║    • Повышение уровня с 1 до 2 при достижении 40 минут                ║
// ║    • Отсутствие повышения, если уровень не изменился                   ║
// ║    • Корректный ранг для каждого уровня                                ║
// ║                                                                        ║
// ╚══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenbalance/data/session.dart';
import 'package:zenbalance/data/database_provider.dart';
import 'package:zenbalance/data/analytics_repository.dart';
import 'package:zenbalance/data/sync_repository.dart';
import 'package:zenbalance/domain/progress_calculator.dart';
import 'package:zenbalance/services/auth_service.dart';

// =============================================================================
// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
// =============================================================================

/// Создаёт in-memory SQLite БД с той же схемой, что и в production.
Future<Database> createInMemoryDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactory.openDatabase(
    ':memory:',
    options: OpenDatabaseOptions(
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions (
            id TEXT PRIMARY KEY NOT NULL,
            timestamp TEXT NOT NULL,
            seconds INTEGER NOT NULL,
            note TEXT,
            mood_rating INTEGER,
            tag TEXT
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_sessions_timestamp ON sessions (timestamp)
        ''');
      },
    ),
  );
  return db;
}

/// Создаёт [AnalyticsRepository] с in-memory БД.
///
/// Каждый вызов создаёт изолированное тестовое окружение:
/// чистая БД + свежий репозиторий.
Future<AnalyticsRepository> createTestRepository(Database db) async {
  final dbProvider = DatabaseProvider.forTest(db);
  final syncRepo = SyncRepository(localDb: dbProvider, auth: AuthService());
  return AnalyticsRepository(syncRepo);
}

/// Вставляет указанное количество минут в БД одной сессией.
Future<void> seedMinutes(Database db, int minutes) async {
  if (minutes <= 0) return;
  final session = Session(seconds: minutes * 60);
  await db.insert('sessions', session.toMap());
}

// =============================================================================
// ТЕСТЫ
// =============================================================================

void main() {
  // ---------------------------------------------------------------------------
  // 1. Повышение уровня (Level-Up)
  // ---------------------------------------------------------------------------
  group('🎯 Повышение уровня (Level-Up)', () {
    late Database db;
    late AnalyticsRepository repository;

    setUp(() async {
      db = await createInMemoryDatabase();
      repository = await createTestRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      '9 минут + 2 минуты = уровень 0→1 (Искатель спокойствия)',
      () async {
        // Arrange: в БД уже есть 9 минут (540 секунд)
        await seedMinutes(db, 9);

        // Act: завершаем сессию на 2 минуты (120 секунд)
        final result = await repository.processSessionEnd(120);

        // Assert: уровень должен повыситься с 0 до 1
        expect(result.hasLevelUp, isTrue,
            reason: 'Должно вернуться событие повышения уровня');
        expect(result.levelUp!.level, equals(1),
            reason: 'Новый уровень должен быть 1');
        expect(result.levelUp!.rank, equals('Искатель спокойствия'),
            reason: 'Ранг для уровня 1 — "Искатель спокойствия"');
      },
    );

    test(
      '39 минут + 1 минута = уровень 1→2 (Искатель спокойствия)',
      () async {
        // Arrange: в БД уже есть 39 минут
        // Формула: level = floor(sqrt((minutes * 10) / 100))
        // 39 мин: floor(sqrt(390/100)) = floor(sqrt(3.9)) = floor(1.97) = 1
        // 40 мин: floor(sqrt(400/100)) = floor(sqrt(4)) = floor(2) = 2
        await seedMinutes(db, 39);

        // Act: завершаем сессию на 1 минуту
        final result = await repository.processSessionEnd(60);

        // Assert: уровень должен повыситься с 1 до 2
        expect(result.hasLevelUp, isTrue,
            reason: 'Должно вернуться событие повышения уровня');
        expect(result.levelUp!.level, equals(2),
            reason: 'Новый уровень должен быть 2');
        expect(result.levelUp!.rank, equals('Искатель спокойствия'),
            reason: 'Ранг для уровня 2 — "Искатель спокойствия"');
      },
    );

    test(
      '99 минут + 1 минута = уровень 3→4 (Хранитель тишины)',
      () async {
        // Arrange: 99 минут → уровень 3
        // 100 минут → уровень 4 (floor(sqrt(1000/100)) = floor(sqrt(10)) = 3? Нет)
        // Проверим: floor(sqrt(99*10/100)) = floor(sqrt(9.9)) = floor(3.14) = 3
        // floor(sqrt(100*10/100)) = floor(sqrt(10)) = floor(3.16) = 3
        // Хм, нужно больше. 90 минут: floor(sqrt(900/100)) = floor(3) = 3
        // 100 минут: floor(sqrt(1000/100)) = floor(3.16) = 3
        // 160 минут: floor(sqrt(1600/100)) = floor(4) = 4
        // Значит 159 + 1 = 160 → уровень 3→4
        await seedMinutes(db, 159);

        // Act: завершаем сессию на 1 минуту
        final result = await repository.processSessionEnd(60);

        // Assert: уровень 3→4, ранг "Хранитель тишины"
        expect(result.hasLevelUp, isTrue,
            reason: 'Должно вернуться событие повышения уровня');
        expect(result.levelUp!.level, equals(4),
            reason: 'Новый уровень должен быть 4');
        expect(result.levelUp!.rank, equals('Хранитель тишины'),
            reason: 'Ранг для уровня 4 — "Хранитель тишины"');
      },
    );

    test(
      '359 минут + 1 минута = уровень 5→6 (Мастер баланса)',
      () async {
        // Arrange: 359 минут → уровень 5
        // floor(sqrt(3590/100)) = floor(sqrt(35.9)) = floor(5.99) = 5
        // 360 минут: floor(sqrt(3600/100)) = floor(6) = 6
        await seedMinutes(db, 359);

        // Act: завершаем сессию на 1 минуту
        final result = await repository.processSessionEnd(60);

        // Assert: уровень 5→6, ранг "Мастер баланса"
        expect(result.hasLevelUp, isTrue,
            reason: 'Должно вернуться событие повышения уровня');
        expect(result.levelUp!.level, equals(6),
            reason: 'Новый уровень должен быть 6');
        expect(result.levelUp!.rank, equals('Мастер баланса'),
            reason: 'Ранг для уровня 6 — "Мастер баланса"');
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 2. Отсутствие повышения (No Level-Up)
  // ---------------------------------------------------------------------------
  group('⏸ Отсутствие повышения', () {
    late Database db;
    late AnalyticsRepository repository;

    setUp(() async {
      db = await createInMemoryDatabase();
      repository = await createTestRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('0 минут + 1 минута = уровень остаётся 0', () async {
      // Arrange: БД пуста (0 минут)
      // Act: завершаем сессию на 1 минуту
      final result = await repository.processSessionEnd(60);

      // Assert: уровень не изменился (0 → 0)
      expect(result.hasLevelUp, isFalse,
          reason: 'Уровень не должен повыситься с 0 при 1 минуте');
    });

    test('1 минута + 1 минута = уровень остаётся 0', () async {
      // Arrange: 1 минута → уровень 0
      await seedMinutes(db, 1);

      // Act: +1 минута = 2 минуты → уровень всё ещё 0
      // floor(sqrt(2*10/100)) = floor(sqrt(0.2)) = floor(0.447) = 0
      final result = await repository.processSessionEnd(60);

      // Assert: уровень не изменился (0 → 0)
      expect(result.hasLevelUp, isFalse,
          reason: 'Уровень не должен повыситься: 2 минуты = уровень 0');
    });

    test('10 минут + 5 минут = уровень остаётся 1', () async {
      // Arrange: 10 минут → уровень 1
      await seedMinutes(db, 10);

      // Act: +5 минут = 15 минут → уровень всё ещё 1
      // floor(sqrt(150/100)) = floor(1.22) = 1
      final result = await repository.processSessionEnd(300);

      // Assert: уровень не изменился (1 → 1)
      expect(result.hasLevelUp, isFalse,
          reason: 'Уровень не должен повыситься: 15 минут = уровень 1');
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Проверка расчёта уровня (чистая доменная логика)
  // ---------------------------------------------------------------------------
  group('🧮 Проверка формулы уровня', () {
    test('0 минут → уровень 0', () {
      expect(ProgressCalculator.calculateLevel(0), equals(0));
    });

    test('9 минут → уровень 0', () {
      expect(ProgressCalculator.calculateLevel(9), equals(0));
    });

    test('10 минут → уровень 1', () {
      expect(ProgressCalculator.calculateLevel(10), equals(1));
    });

    test('39 минут → уровень 1', () {
      expect(ProgressCalculator.calculateLevel(39), equals(1));
    });

    test('40 минут → уровень 2', () {
      expect(ProgressCalculator.calculateLevel(40), equals(2));
    });

    test('89 минут → уровень 2', () {
      expect(ProgressCalculator.calculateLevel(89), equals(2));
    });

    test('90 минут → уровень 3', () {
      expect(ProgressCalculator.calculateLevel(90), equals(3));
    });

    test('159 минут → уровень 3', () {
      expect(ProgressCalculator.calculateLevel(159), equals(3));
    });

    test('160 минут → уровень 4', () {
      expect(ProgressCalculator.calculateLevel(160), equals(4));
    });

    test('249 минут → уровень 4', () {
      expect(ProgressCalculator.calculateLevel(249), equals(4));
    });

    test('250 минут → уровень 5', () {
      expect(ProgressCalculator.calculateLevel(250), equals(5));
    });

    test('359 минут → уровень 5', () {
      expect(ProgressCalculator.calculateLevel(359), equals(5));
    });

    test('360 минут → уровень 6', () {
      expect(ProgressCalculator.calculateLevel(360), equals(6));
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Проверка рангов
  // ---------------------------------------------------------------------------
  group('🏷 Проверка рангов', () {
    test('Уровень 0 → "Новичок осознанности"', () {
      expect(ProgressCalculator.getRank(0), equals('Новичок осознанности'));
    });

    test('Уровень 1 → "Искатель спокойствия"', () {
      expect(ProgressCalculator.getRank(1), equals('Искатель спокойствия'));
    });

    test('Уровень 2 → "Искатель спокойствия"', () {
      expect(ProgressCalculator.getRank(2), equals('Искатель спокойствия'));
    });

    test('Уровень 3 → "Хранитель тишины"', () {
      expect(ProgressCalculator.getRank(3), equals('Хранитель тишины'));
    });

    test('Уровень 5 → "Хранитель тишины"', () {
      expect(ProgressCalculator.getRank(5), equals('Хранитель тишины'));
    });

    test('Уровень 6 → "Мастер баланса"', () {
      expect(ProgressCalculator.getRank(6), equals('Мастер баланса'));
    });

    test('Уровень 10 → "Мастер баланса"', () {
      expect(ProgressCalculator.getRank(10), equals('Мастер баланса'));
    });
  });
}
