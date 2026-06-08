// =============================================================================
// ZenBalance — Unit-тесты для DatabaseProvider (сохранение сессий)
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ЗАПУСК ТЕСТОВ                                  ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║  flutter test test/infrastructure/database_session_test.dart            ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Что проверяется:
//   • insertSession() сохраняет сессию в БД
//   • getAllSessions() возвращает сохранённые сессии
//   • getTotalMinutes() правильно суммирует
//   • getSessionCount() возвращает правильное количество
//   • getSessionsInRange() фильтрует по дате
//   • getDailyMinutes() агрегирует по дням
//   • insertSessionIfNewer() не перезаписывает более новую сессию
//   • updateSessionFields() обновляет поля
//   • deleteSession() удаляет сессию

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenbalance/data/session.dart';
import 'package:zenbalance/data/database_provider.dart';

// =============================================================================
// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
// =============================================================================

/// Создаёт in-memory DatabaseProvider для тестов.
Future<DatabaseProvider> createTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Создаём in-memory БД напрямую
  final db = await databaseFactory.openDatabase(
    ':memory:',
    options: OpenDatabaseOptions(
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions (
            id TEXT PRIMARY KEY,
            timestamp TEXT NOT NULL,
            seconds INTEGER NOT NULL,
            note TEXT,
            mood_rating INTEGER,
            tag TEXT,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_sessions_timestamp ON sessions (timestamp)
        ''');
        await db.execute('''
          CREATE TABLE goals (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            target_value REAL NOT NULL,
            bonus_xp INTEGER NOT NULL DEFAULT 50,
            rewarded INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
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

  return DatabaseProvider.forTest(db);
}

/// Создаёт тестовую сессию с заданными параметрами.
Session createSession({
  int seconds = 600,
  String? timestamp,
  String? note,
  int? moodRating,
  String? tag,
}) {
  return Session(
    seconds: seconds,
    timestamp: timestamp,
    note: note,
    moodRating: moodRating,
    tag: tag,
  );
}

// =============================================================================
// ТЕСТЫ
// =============================================================================

void main() {
  group('💾 DatabaseProvider — сохранение сессий', () {
    late DatabaseProvider dbProvider;

    setUp(() async {
      dbProvider = await createTestDb();
    });

    tearDown(() async {
      await dbProvider.close();
    });

    // ---------------------------------------------------------------------------
    // 1. Базовая запись и чтение
    // ---------------------------------------------------------------------------

    test('insertSession() сохраняет сессию, getAllSessions() возвращает её',
        () async {
      final session = createSession(seconds: 600);
      await dbProvider.insertSession(session);

      final sessions = await dbProvider.getAllSessions();
      expect(sessions.length, equals(1));
      expect(sessions.first.id, equals(session.id));
      expect(sessions.first.seconds, equals(600));
    });

    test('insertSession() сохраняет несколько сессий', () async {
      await dbProvider.insertSession(createSession(seconds: 300));
      await dbProvider.insertSession(createSession(seconds: 600));
      await dbProvider.insertSession(createSession(seconds: 900));

      final sessions = await dbProvider.getAllSessions();
      expect(sessions.length, equals(3));
    });

    test('getAllSessions() возвращает сессии в порядке убывания даты',
        () async {
      final s1 = createSession(
        seconds: 300,
        timestamp: '2026-06-01T10:00:00.000Z',
      );
      final s2 = createSession(
        seconds: 600,
        timestamp: '2026-06-02T10:00:00.000Z',
      );
      final s3 = createSession(
        seconds: 900,
        timestamp: '2026-06-03T10:00:00.000Z',
      );

      await dbProvider.insertSession(s1);
      await dbProvider.insertSession(s2);
      await dbProvider.insertSession(s3);

      final sessions = await dbProvider.getAllSessions();
      expect(sessions.length, equals(3));
      // Должны быть отсортированы по timestamp DESC
      expect(sessions[0].id, equals(s3.id));
      expect(sessions[2].id, equals(s1.id));
    });

    test('getAllSessions() поддерживает пагинацию (limit/offset)', () async {
      for (int i = 0; i < 10; i++) {
        await dbProvider.insertSession(
          createSession(
            seconds: 100 + i * 10,
            timestamp: '2026-06-${(i + 1).toString().padLeft(2, '0')}T10:00:00.000Z',
          ),
        );
      }

      // Первая страница: 3 записи
      final page1 = await dbProvider.getAllSessions(limit: 3, offset: 0);
      expect(page1.length, equals(3));

      // Вторая страница: ещё 3 записи
      final page2 = await dbProvider.getAllSessions(limit: 3, offset: 3);
      expect(page2.length, equals(3));

      // Третья страница: оставшиеся записи (10 - 6 = 4)
      final page3 = await dbProvider.getAllSessions(limit: 3, offset: 6);
      expect(page3.length, greaterThanOrEqualTo(3));
      expect(page3.length, lessThanOrEqualTo(4));
    });

    // ---------------------------------------------------------------------------
    // 2. Агрегации
    // ---------------------------------------------------------------------------

    test('getTotalDurationSeconds() суммирует секунды всех сессий', () async {
      await dbProvider.insertSession(createSession(seconds: 300));
      await dbProvider.insertSession(createSession(seconds: 600));
      await dbProvider.insertSession(createSession(seconds: 900));

      final total = await dbProvider.getTotalDurationSeconds();
      expect(total, equals(1800));
    });

    test('getTotalDurationSeconds() возвращает 0, если нет сессий', () async {
      final total = await dbProvider.getTotalDurationSeconds();
      expect(total, equals(0));
    });

    test('getSessionCount() возвращает правильное количество', () async {
      await dbProvider.insertSession(createSession(seconds: 300));
      await dbProvider.insertSession(createSession(seconds: 600));

      final count = await dbProvider.getSessionCount();
      expect(count, equals(2));
    });

    test('getSessionCount() возвращает 0, если нет сессий', () async {
      final count = await dbProvider.getSessionCount();
      expect(count, equals(0));
    });

    test('getTotalMinutes() возвращает сумму минут', () async {
      await dbProvider.insertSession(createSession(seconds: 300));  // 5 мин
      await dbProvider.insertSession(createSession(seconds: 600));  // 10 мин
      await dbProvider.insertSession(createSession(seconds: 900));  // 15 мин

      final total = await dbProvider.getTotalMinutes();
      expect(total, equals(30.0));
    });

    // ---------------------------------------------------------------------------
    // 3. Фильтрация по дате
    // ---------------------------------------------------------------------------

    test('getSessionsInRange() фильтрует сессии по диапазону дат', () async {
      await dbProvider.insertSession(createSession(
        seconds: 300,
        timestamp: '2026-06-01T10:00:00.000Z',
      ));
      await dbProvider.insertSession(createSession(
        seconds: 600,
        timestamp: '2026-06-05T10:00:00.000Z',
      ));
      await dbProvider.insertSession(createSession(
        seconds: 900,
        timestamp: '2026-06-10T10:00:00.000Z',
      ));

      // Диапазон: 2026-06-01 до 2026-06-07
      final sessions = await dbProvider.getSessionsInRange(
        '2026-06-01',
        '2026-06-07',
      );
      expect(sessions.length, equals(2));
    });

    test('getSessionsInRange() возвращает пустой список, если нет сессий',
        () async {
      final sessions = await dbProvider.getSessionsInRange(
        '2026-01-01',
        '2026-01-31',
      );
      expect(sessions, isEmpty);
    });

    // ---------------------------------------------------------------------------
    // 4. DailyMinutes
    // ---------------------------------------------------------------------------

    test('getDailyMinutes() возвращает данные за указанное количество дней',
        () async {
      // Вставляем сессию с сегодняшней датой (используем UTC)
      final now = DateTime.now().toUtc();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await dbProvider.insertSession(createSession(
        seconds: 600,
        timestamp: '${today}T10:00:00.000Z',
      ));
      await dbProvider.insertSession(createSession(
        seconds: 300,
        timestamp: '${today}T14:00:00.000Z',
      ));

      // Запрашиваем за 3 дня
      final rows = await dbProvider.getDailyMinutes(3);
      // Должно быть не менее 3 дней (позавчера, вчера, сегодня)
      expect(rows.length, greaterThanOrEqualTo(3));

      // Ищем сегодняшнюю дату в результатах
      final todayRow = rows.firstWhere(
        (r) => r['date'] == today,
        orElse: () => <String, dynamic>{'date': '', 'minutes': 0.0},
      );
      expect(todayRow['date'], equals(today));
      expect((todayRow['minutes'] as num).toDouble(), equals(15.0));
    });

    // ---------------------------------------------------------------------------
    // 5. insertSessionIfNewer
    // ---------------------------------------------------------------------------

    test('insertSessionIfNewer() вставляет новую сессию', () async {
      final session = createSession(seconds: 600);
      await dbProvider.insertSessionIfNewer(session);

      final sessions = await dbProvider.getAllSessions();
      expect(sessions.length, equals(1));
    });

    test('insertSessionIfNewer() не перезаписывает более новую локальную версию',
        () async {
      // Старая облачная версия
      final oldCloud = Session(
        id: 'test-id',
        seconds: 300,
        timestamp: '2026-06-01T10:00:00.000Z',
        updatedAt: '2026-06-01T10:00:00.000Z',
      );
      await dbProvider.insertSession(oldCloud);

      // Новая локальная версия (с тем же ID, но новее)
      final newLocal = Session(
        id: 'test-id',
        seconds: 600,
        timestamp: '2026-06-02T10:00:00.000Z',
        updatedAt: '2026-06-02T10:00:00.000Z',
      );
      await dbProvider.insertSession(newLocal);

      // Старая облачная версия пытается перезаписать
      await dbProvider.insertSessionIfNewer(oldCloud);

      // Должна остаться новая локальная версия
      final sessions = await dbProvider.getAllSessions();
      expect(sessions.length, equals(1));
      expect(sessions.first.seconds, equals(600));
    });

    test('insertSessionIfNewer() перезаписывает устаревшую локальную версию',
        () async {
      // Старая локальная версия
      final oldLocal = Session(
        id: 'test-id',
        seconds: 300,
        timestamp: '2026-06-01T10:00:00.000Z',
        updatedAt: '2026-06-01T10:00:00.000Z',
      );
      await dbProvider.insertSession(oldLocal);

      // Новая облачная версия
      final newCloud = Session(
        id: 'test-id',
        seconds: 900,
        timestamp: '2026-06-03T10:00:00.000Z',
        updatedAt: '2026-06-03T10:00:00.000Z',
      );
      await dbProvider.insertSessionIfNewer(newCloud);

      // Должна быть новая облачная версия
      final sessions = await dbProvider.getAllSessions();
      expect(sessions.length, equals(1));
      expect(sessions.first.seconds, equals(900));
    });

    // ---------------------------------------------------------------------------
    // 6. updateSessionFields
    // ---------------------------------------------------------------------------

    test('updateSessionFields() обновляет заметку, оценку и тег', () async {
      final session = createSession(seconds: 600);
      await dbProvider.insertSession(session);

      await dbProvider.updateSessionFields(
        session.id,
        note: 'Отличная медитация',
        moodRating: 5,
        tag: 'Утро',
      );

      final sessions = await dbProvider.getAllSessions();
      expect(sessions.first.note, equals('Отличная медитация'));
      expect(sessions.first.moodRating, equals(5));
      expect(sessions.first.tag, equals('Утро'));
    });

    test('updateSessionFields() не изменяет поля, если они null', () async {
      final session = createSession(
        seconds: 600,
        note: 'Исходная заметка',
      );
      await dbProvider.insertSession(session);

      // Обновляем только moodRating
      await dbProvider.updateSessionFields(
        session.id,
        moodRating: 4,
      );

      final sessions = await dbProvider.getAllSessions();
      expect(sessions.first.note, equals('Исходная заметка'));
      expect(sessions.first.moodRating, equals(4));
      expect(sessions.first.tag, isNull);
    });

    // ---------------------------------------------------------------------------
    // 7. deleteSession
    // ---------------------------------------------------------------------------

    test('deleteSession() удаляет сессию', () async {
      final session = createSession(seconds: 600);
      await dbProvider.insertSession(session);

      final deleted = await dbProvider.deleteSession(session.id);
      expect(deleted, isTrue);

      final sessions = await dbProvider.getAllSessions();
      expect(sessions, isEmpty);
    });

    test('deleteSession() возвращает false, если сессия не найдена', () async {
      final deleted = await dbProvider.deleteSession('non-existent-id');
      expect(deleted, isFalse);
    });

    // ---------------------------------------------------------------------------
    // 8. DistinctSessionDates
    // ---------------------------------------------------------------------------

    test('getDistinctSessionDates() возвращает уникальные даты', () async {
      await dbProvider.insertSession(createSession(
        seconds: 300,
        timestamp: '2026-06-01T10:00:00.000Z',
      ));
      await dbProvider.insertSession(createSession(
        seconds: 600,
        timestamp: '2026-06-01T14:00:00.000Z',
      ));
      await dbProvider.insertSession(createSession(
        seconds: 900,
        timestamp: '2026-06-02T10:00:00.000Z',
      ));

      final dates = await dbProvider.getDistinctSessionDates();
      expect(dates.length, equals(2));
      expect(dates, contains('2026-06-01'));
      expect(dates, contains('2026-06-02'));
    });

    // ---------------------------------------------------------------------------
    // 9. DistinctTags
    // ---------------------------------------------------------------------------

    test('getDistinctTags() возвращает уникальные теги', () async {
      await dbProvider.insertSession(createSession(
        seconds: 300,
        tag: 'Утро',
      ));
      await dbProvider.insertSession(createSession(
        seconds: 600,
        tag: 'Вечер',
      ));
      await dbProvider.insertSession(createSession(
        seconds: 900,
        tag: 'Утро',
      ));

      final tags = await dbProvider.getDistinctTags();
      expect(tags.length, equals(2));
      expect(tags, contains('Утро'));
      expect(tags, contains('Вечер'));
    });

    // ---------------------------------------------------------------------------
    // 10. getFilteredSessions
    // ---------------------------------------------------------------------------

    test('getFilteredSessions() фильтрует по тегу', () async {
      await dbProvider.insertSession(createSession(
        seconds: 300,
        tag: 'Утро',
        note: 'Хорошо',
      ));
      await dbProvider.insertSession(createSession(
        seconds: 600,
        tag: 'Вечер',
        note: 'Отлично',
      ));

      final sessions = await dbProvider.getFilteredSessions(tag: 'Утро');
      expect(sessions.length, equals(1));
      expect(sessions.first.tag, equals('Утро'));
    });

    test('getFilteredSessions() ищет по заметке', () async {
      await dbProvider.insertSession(createSession(
        seconds: 300,
        note: 'Утренняя медитация',
      ));
      await dbProvider.insertSession(createSession(
        seconds: 600,
        note: 'Вечерняя практика',
      ));

      // Ищем с правильным регистром (SQLite LIKE для кириллицы регистрозависим)
      final sessions = await dbProvider.getFilteredSessions(
        searchQuery: 'Утренняя',
      );
      expect(sessions.length, equals(1));
      expect(sessions.first.note, contains('Утренняя'));
    });
  });
}
