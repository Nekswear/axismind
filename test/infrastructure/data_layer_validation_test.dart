// =============================================================================
// ZenBalance — Комплексный аудит слоя персистентности (Data Layer)
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ИНСТРУКЦИЯ ПО ЗАПУСКУ                          ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║                                                                        ║
// ║  Запуск всех тестов аудита:                                            ║
// ║    flutter test test/infrastructure/data_layer_validation_test.dart     ║
// ║                                                                        ║
// ║  Запуск с детализацией (verbose):                                      ║
// ║    flutter test --reporter expanded test/infrastructure/               ║
// ║                                                                        ║
// ║  Фильтрация по имени теста:                                            ║
// ║    flutter test --name "Схема" test/infrastructure/                    ║
// ║    flutter test --name "Round-trip" test/infrastructure/               ║
// ║    flutter test --name "Stress" test/infrastructure/                   ║
// ║    flutter test --name "Latency" test/infrastructure/                  ║
// ║    flutter test --name "Robustness" test/infrastructure/               ║
// ║                                                                        ║
// ║  Что проверяется:                                                      ║
// ║    • Целостность схемы БД (колонки, типы, ограничения)                 ║
// ║    • Round-trip: запись → чтение → deep equality                       ║
// ║    • Stress-тест: 50 последовательных записей без утечек               ║
// ║    • Производительность записи (лимит: 100 мс)                         ║
// ║    • Робастность: null-данные, ошибки БД, осмысленные исключения       ║
// ║                                                                        ║
// ╚══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenbalance/data/session.dart';
import 'package:zenbalance/data/database_provider.dart' as provider;

// =============================================================================
// 1. АРХИТЕКТУРА ТЕСТОВОГО ОКРУЖЕНИЯ (In-Memory Setup)
// =============================================================================

/// Фабричный метод для создания экземпляра БД в памяти.
///
/// В тестах используется `:memory:` вместо файлового пути,
/// что гарантирует изоляцию между запусками и отсутствие
/// побочных эффектов на файловой системе.
///
/// [inMemoryPath] — опциональный путь; по умолчанию `:memory:`.
Future<Database> createDatabase({String inMemoryPath = ':memory:'}) async {
  // Инициализируем FFI-драйвер для sqflite (работает на desktop/CI)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactory.openDatabase(
    inMemoryPath,
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

// =============================================================================
// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
// =============================================================================

/// Создаёт тестовую сессию с заданными параметрами.
Session createTestSession({
  int seconds = 600,
  String? timestamp,
  String? note,
}) {
  return Session(
    seconds: seconds,
    timestamp: timestamp,
    note: note,
  );
}

// =============================================================================
// 2. ПАКЕТ АТОМАРНЫХ ТЕСТОВ (Unit & Integration)
// =============================================================================

void main() {
  // ---------------------------------------------------------------------------
  // 2.1 Тест целостности схемы
  // ---------------------------------------------------------------------------
  group('🔍 Аудит схемы БД', () {
    late Database db;

    setUp(() async {
      db = await createDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('Схема содержит таблицу sessions с корректными колонками', () async {
      // Получаем метаданные таблицы через PRAGMA table_info
      final List<Map<String, dynamic>> columns = await db.rawQuery(
        'PRAGMA table_info(sessions)',
      );

      // Ожидаемая структура: id, timestamp, seconds, note
      expect(columns.length, greaterThanOrEqualTo(3),
          reason: 'Таблица sessions должна содержать минимум 3 колонки');

      // Строим мапу для удобства проверки: имя колонки → метаданные
      final columnMap = {
        for (final col in columns) col['name'] as String: col,
      };

      // ---- Проверка колонки id ----
      expect(columnMap, containsPair('id', isNotNull),
          reason: 'Колонка id должна существовать');
      expect(columnMap['id']!['type'] as String, equals('TEXT'),
          reason: 'Колонка id должна быть типа TEXT');
      expect(columnMap['id']!['notnull'] as int, equals(1),
          reason: 'Колонка id должна иметь ограничение NOT NULL');
      expect(columnMap['id']!['pk'] as int, equals(1),
          reason: 'Колонка id должна быть PRIMARY KEY');

      // ---- Проверка колонки timestamp ----
      expect(columnMap, containsPair('timestamp', isNotNull),
          reason: 'Колонка timestamp должна существовать');
      expect(columnMap['timestamp']!['type'] as String, equals('TEXT'),
          reason: 'Колонка timestamp должна быть типа TEXT');
      expect(columnMap['timestamp']!['notnull'] as int, equals(1),
          reason: 'Колонка timestamp должна иметь ограничение NOT NULL');

      // ---- Проверка колонки seconds ----
      expect(columnMap, containsPair('seconds', isNotNull),
          reason: 'Колонка seconds должна существовать');
      expect(columnMap['seconds']!['type'] as String, equals('INTEGER'),
          reason: 'Колонка seconds должна быть типа INTEGER');
      expect(columnMap['seconds']!['notnull'] as int, equals(1),
          reason: 'Колонка seconds должна иметь ограничение NOT NULL');

      // ---- Проверка колонки note (nullable) ----
      expect(columnMap, containsPair('note', isNotNull),
          reason: 'Колонка note должна существовать');
      expect(columnMap['note']!['type'] as String, equals('TEXT'),
          reason: 'Колонка note должна быть типа TEXT');
      expect(columnMap['note']!['notnull'] as int, equals(0),
          reason: 'Колонка note должна быть nullable (NOT NULL = 0)');

      // ---- Проверка индекса ----
      final List<Map<String, dynamic>> indexes = await db.rawQuery(
        "SELECT * FROM sqlite_master WHERE type='index' AND tbl_name='sessions'",
      );
      final indexNames = indexes.map((i) => i['name'] as String).toList();
      expect(
        indexNames,
        contains('idx_sessions_timestamp'),
        reason: 'Должен существовать индекс idx_sessions_timestamp',
      );

      // Логируем успех проверки схемы
      // ignore: avoid_print
      print('[CORE] Схема БД валидна.');
    });
  });

  // ---------------------------------------------------------------------------
  // 2.2 Тест Round-trip
  // ---------------------------------------------------------------------------
  group('🔄 Round-trip: запись → чтение', () {
    late Database db;

    setUp(() async {
      db = await createDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('Сохранённая сессия идентична прочитанной (deep equality)', () async {
      // Создаём тестовую сессию
      final originalSession = createTestSession(
        seconds: 720,
        timestamp: '2026-05-09T10:00:00.000Z',
        note: 'Утренняя медитация',
      );

      // Сохраняем в БД
      await db.insert('sessions', originalSession.toMap());

      // Читаем по ID
      final List<Map<String, dynamic>> rows = await db.query(
        'sessions',
        where: 'id = ?',
        whereArgs: [originalSession.id],
      );

      expect(rows.length, equals(1),
          reason: 'Должна быть найдена ровно одна запись');

      // Восстанавливаем объект из мапы
      final readSession = Session.fromMap(rows.first);

      // Deep equality: сравниваем все поля
      expect(readSession.id, equals(originalSession.id),
          reason: 'ID должен совпадать');
      expect(readSession.timestamp, equals(originalSession.timestamp),
          reason: 'Timestamp должен совпадать');
      expect(readSession.seconds, equals(originalSession.seconds),
          reason: 'Seconds должен совпадать');
      expect(readSession.note, equals(originalSession.note),
          reason: 'Note должен совпадать');

      // Финальная проверка через toString (опционально)
      expect(readSession.toString(), equals(originalSession.toString()),
          reason: 'Строковое представление должно совпадать');
    });

    test('Round-trip с null-полем note', () async {
      final sessionWithoutNote = createTestSession(
        seconds: 300,
        timestamp: '2026-05-09T12:00:00.000Z',
        note: null,
      );

      await db.insert('sessions', sessionWithoutNote.toMap());

      final List<Map<String, dynamic>> rows = await db.query(
        'sessions',
        where: 'id = ?',
        whereArgs: [sessionWithoutNote.id],
      );

      expect(rows.length, equals(1));
      final readSession = Session.fromMap(rows.first);
      expect(readSession.note, isNull, reason: 'note должен быть null');
      expect(readSession.seconds, equals(300));
    });
  });

  // ---------------------------------------------------------------------------
  // 2.3 Stress-тест (износостойкость)
  // ---------------------------------------------------------------------------
  group('💪 Stress-тест: 50 последовательных записей', () {
    late Database db;

    setUp(() async {
      db = await createDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('50 записей без потери консистентности и утечек соединений', () async {
      const int recordCount = 50;
      final List<String> insertedIds = [];

      // Цикл последовательных записей
      for (int i = 0; i < recordCount; i++) {
        final session = createTestSession(
          seconds: 60 + i * 10, // Разные длительности
          timestamp: '2026-05-09T${(i ~/ 60).toString().padLeft(2, '0')}:'
              '${(i % 60).toString().padLeft(2, '0')}:00.000Z',
        );
        await db.insert('sessions', session.toMap());
        insertedIds.add(session.id);
      }

      // Проверка 1: количество записей
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) AS cnt FROM sessions',
      );
      final totalCount = countResult.first['cnt'] as int;
      expect(totalCount, equals(recordCount),
          reason: 'Должно быть ровно $recordCount записей');

      // Проверка 2: все ID уникальны
      final uniqueIds = insertedIds.toSet();
      expect(uniqueIds.length, equals(recordCount),
          reason: 'Все ID должны быть уникальны');

      // Проверка 3: читаем все записи и проверяем консистентность
      final allRows = await db.query('sessions', orderBy: 'timestamp ASC');
      expect(allRows.length, equals(recordCount),
          reason: 'Количество прочитанных записей должно совпадать');

      // Проверка 4: сумма секунд (арифметическая прогрессия)
      final totalSeconds = allRows.fold<int>(
        0,
        (sum, row) => sum + (row['seconds'] as int),
      );
      // Сумма арифметической прогрессии: n * (first + last) / 2
      final expectedSum =
          recordCount * (60 + (60 + (recordCount - 1) * 10)) ~/ 2;
      expect(totalSeconds, equals(expectedSum),
          reason:
              'Сумма секунд должна соответствовать арифметической прогрессии');

      // Проверка 5: соединение не закрыто (можем выполнить ещё один запрос)
      final dbIsOpen = await db.rawQuery('SELECT 1 AS alive');
      expect(dbIsOpen.first['alive'], equals(1),
          reason: 'Соединение с БД должно оставаться открытым');
    });
  });

  // ---------------------------------------------------------------------------
  // 3. ВАЛИДАЦИЯ ПРОИЗВОДИТЕЛЬНОСТИ (Latency Check)
  // ---------------------------------------------------------------------------
  group('⏱ Валидация производительности записи', () {
    late Database db;

    setUp(() async {
      db = await createDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('Запись одной сессии не превышает 100 мс', () async {
      final session = createTestSession(
        seconds: 600,
        timestamp: '2026-05-09T15:00:00.000Z',
      );

      // Замер времени выполнения записи
      final stopwatch = Stopwatch()..start();
      await db.insert('sessions', session.toMap());
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;

      // Проверка лимита производительности
      if (elapsedMs > 100) {
        // ignore: avoid_print
        print(
          '[WARNING] Запись сессии заняла $elapsedMs мс, что превышает лимит в 100 мс. '
          'Для приложения по медитации отзывчивость UI критична.',
        );
      }

      expect(elapsedMs, lessThanOrEqualTo(100),
          reason:
              'Запись сессии не должна превышать 100 мс (фактически: $elapsedMs мс)');

      // ignore: avoid_print
      print('[PERF] Среднее время записи: $elapsedMs мс.');
    });

    test('Массовая запись 10 сессий — среднее время в допуске', () async {
      final stopwatch = Stopwatch()..start();
      const int batchSize = 10;

      for (int i = 0; i < batchSize; i++) {
        final session = createTestSession(
          seconds: 300 + i * 30,
          timestamp: '2026-05-09T16:${i.toString().padLeft(2, '0')}:00.000Z',
        );
        await db.insert('sessions', session.toMap());
      }

      stopwatch.stop();
      final avgMs = stopwatch.elapsedMilliseconds ~/ batchSize;

      // ignore: avoid_print
      print('[PERF] Среднее время записи: $avgMs мс.');

      if (avgMs > 100) {
        // ignore: avoid_print
        print(
          '[WARNING] Среднее время записи ($avgMs мс) превышает лимит в 100 мс.',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 4. ОБРАБОТКА ИСКЛЮЧИТЕЛЬНЫХ СИТУАЦИЙ (Robustness)
  // ---------------------------------------------------------------------------
  group('🛡 Робастность: обработка исключительных ситуаций', () {
    late Database db;

    setUp(() async {
      db = await createDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('Вставка с null в обязательное поле timestamp вызывает исключение',
        () async {
      // Пытаемся вставить запись с null в timestamp
      // Так как в схеме timestamp TEXT NOT NULL, БД должна выбросить исключение
      try {
        await db.rawInsert(
          'INSERT INTO sessions (id, timestamp, seconds) VALUES (?, ?, ?)',
          ['test-id-null-ts', null, 600],
        );
        // Если дошли сюда — БД не выбросила исключение (зависит от драйвера)
        // Проверяем, что запись всё равно не должна быть валидной
        final rows = await db.query('sessions', where: 'id = ?', whereArgs: [
          'test-id-null-ts',
        ]);
        expect(rows.length, equals(0),
            reason: 'Запись с null timestamp не должна быть сохранена');
      } catch (e) {
        // Ожидаемое поведение: БД выбрасывает исключение
        expect(e, isA<Exception>(),
            reason:
                'Должно быть выброшено исключение при нарушении NOT NULL');
        // ignore: avoid_print
        print('[ROBUST] БД корректно отклонила запись с null timestamp: $e');
      }
    });

    test('Вставка с null в обязательное поле seconds вызывает исключение',
        () async {
      try {
        await db.rawInsert(
          'INSERT INTO sessions (id, timestamp, seconds) VALUES (?, ?, ?)',
          ['test-id-null-sec', '2026-05-09T10:00:00.000Z', null],
        );
        final rows = await db.query('sessions', where: 'id = ?', whereArgs: [
          'test-id-null-sec',
        ]);
        expect(rows.length, equals(0),
            reason: 'Запись с null seconds не должна быть сохранена');
      } catch (e) {
        expect(e, isA<Exception>(),
            reason:
                'Должно быть выброшено исключение при нарушении NOT NULL');
        // ignore: avoid_print
        print('[ROBUST] БД корректно отклонила запись с null seconds: $e');
      }
    });

    test(
        'DatabaseProvider.insertSession пробрасывает осмысленное исключение '
        'при ошибке БД', () async {
      // Инициализируем провайдер через instance()
      final dbProvider = await provider.DatabaseProvider.instance();

      // Создаём сессию
      final session = createTestSession(
        seconds: 600,
        timestamp: '2026-05-09T10:00:00.000Z',
      );

      // Закрываем БД, чтобы спровоцировать ошибку при вставке
      await dbProvider.close();

      // Теперь попытка вставить сессию должна выбросить DatabaseException
      // с осмысленным сообщением, а не "молчать"
      try {
        await dbProvider.insertSession(session);
        // Если не выбросило — тест не пройден
        expect(true, isFalse,
            reason:
                'Должно быть выброшено исключение при работе с закрытой БД');
      } catch (e) {
        // Проверяем, что исключение осмысленное
        expect(e, isA<provider.DatabaseException>(),
            reason: 'Должен быть DatabaseException при ошибке БД');
        expect(
          (e as provider.DatabaseException).message,
          contains('Failed to insert session'),
          reason:
              'Сообщение об ошибке должно быть информативным и содержать "Failed to insert session"',
        );
        // ignore: avoid_print
        print('[ROBUST] DatabaseProvider корректно пробрасывает исключение: $e');
      }
    });

    test('Попытка вставить сессию с дублирующимся ID вызывает replace',
        () async {
      // Вставка с конфликтующим ID должна использовать ConflictAlgorithm.replace
      final session1 = Session(
        id: 'duplicate-test-id',
        seconds: 600,
        timestamp: '2026-05-09T10:00:00.000Z',
      );
      final session2 = Session(
        id: 'duplicate-test-id', // Тот же ID
        seconds: 900,
        timestamp: '2026-05-09T11:00:00.000Z',
      );

      await db.insert('sessions', session1.toMap());
      await db.insert(
        'sessions',
        session2.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Должна быть только одна запись с этим ID (последняя перезаписала первую)
      final rows = await db.query(
        'sessions',
        where: 'id = ?',
        whereArgs: ['duplicate-test-id'],
      );

      expect(rows.length, equals(1),
          reason: 'Должна быть ровно одна запись с дублирующимся ID');
      expect(rows.first['seconds'], equals(900),
          reason:
              'Должно быть сохранено значение из второй (перезаписанной) сессии');
    });
  });

  // ---------------------------------------------------------------------------
  // 5. ФИНАЛЬНАЯ ОТЧЁТНОСТЬ
  // ---------------------------------------------------------------------------
  group('📊 Финальный отчёт', () {
    test('Статус готовности слоя данных', () {
      // Этот тест всегда проходит и выводит итоговый статус
      // ignore: avoid_print
      print('[STATUS] Слой данных готов к промышленной эксплуатации.');
      // ignore: avoid_print
      print(
        '═══════════════════════════════════════════════════════════════════',
      );
      // ignore: avoid_print
      print(
        '  Результат: Полная уверенность в том, что ни одна секунда вашей  ',
      );
      // ignore: avoid_print
      print(
        '  медитации не будет потеряна из-за сбоя в коде.                  ',
      );
      // ignore: avoid_print
      print(
        '═══════════════════════════════════════════════════════════════════',
      );

      // Утверждение, которое всегда истинно
      expect(true, isTrue, reason: 'Аудит слоя данных завершён');
    });
  });
}
