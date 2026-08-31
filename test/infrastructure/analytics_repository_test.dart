// =============================================================================
// AxisMind — Unit-тесты для DatabaseProvider (статистика и аналитика)
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ЗАПУСК ТЕСТОВ                                  ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║  flutter test test/infrastructure/analytics_repository_test.dart        ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Что проверяется:
//   • getTotalMinutes() возвращает сумму минут
//   • getSessionCount() возвращает количество сессий
//   • getDailyMinutes() агрегирует по дням
//   • getDistinctSessionDates() возвращает уникальные даты
//   • getDistinctTags() возвращает уникальные теги
//   • getFilteredSessions() фильтрует по тегу и заметке
//   • getSessionsInRange() фильтрует по диапазону дат
//   • updateSessionFields() обновляет поля
//   • deleteSession() удаляет сессию

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:axismind/data/database_provider.dart';
import 'package:axismind/data/session.dart';

// =============================================================================
// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
// =============================================================================

/// Создаёт in-memory DatabaseProvider для тестов.
Future<DatabaseProvider> createTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

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
  group('📊 DatabaseProvider — статистика и аналитика', () {
    late DatabaseProvider dbProvider;

    setUp(() async {
      dbProvider = await createTestDb();
    });

    tearDown(() async {
      await dbProvider.close();
    });

    // ---------------------------------------------------------------------------
    // 1. getTotalDurationSeconds
    // ---------------------------------------------------------------------------

    test('getTotalDurationSeconds() возвращает 0, если нет сессий', () async {
      final total = await dbProvider.getTotalDurationSeconds();
      expect(total, equals(0));
    });

    test('getTotalDurationSeconds() суммирует секунды всех сессий', () async {
      await dbProvider.insertSession(createSession(seconds: 600));
      await dbProvider.insertSession(createSession(seconds: 900));

      final total = await dbProvider.getTotalDurationSeconds();
      expect(total, equals(1500));
    });

    // ---------------------------------------------------------------------------
    // 2. getSessionCount
    // ---------------------------------------------------------------------------

    test('getSessionCount() возвращает 0, если нет сессий', () async {
      final count = await dbProvider.getSessionCount();
      expect(count, equals(0));
    });

    test('getSessionCount() возвращает количество сессий', () async {
      await dbProvider.insertSession(createSession(seconds: 300));
      await dbProvider.insertSession(createSession(seconds: 600));
      await dbProvider.insertSession(createSession(seconds: 900));

      final count = await dbProvider.getSessionCount();
      expect(count, equals(3));
    });

    // ---------------------------------------------------------------------------
    // 3. getTotalMinutes
    // ---------------------------------------------------------------------------

    test('getTotalMinutes() возвращает 0, если нет сессий', () async {
      final total = await dbProvider.getTotalMinutes();
      expect(total, equals(0.0));
    });

    test('getTotalMinutes() суммирует минуты всех сессий', () async {
      await dbProvider.insertSession(createSession(seconds: 600));  // 10 мин
      await dbProvider.insertSession(createSession(seconds: 900));  // 15 мин

      final total = await dbProvider.getTotalMinutes();
      expect(total, equals(25.0));
    });

    // ---------------------------------------------------------------------------
    // 4. getDailyMinutes
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
    // 5. getDistinctSessionDates
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
    // 6. getDistinctTags
    // ---------------------------------------------------------------------------

    test('getDistinctTags() возвращает уникальные теги', () async {
      await dbProvider.insertSession(createSession(seconds: 300, tag: 'Утро'));
      await dbProvider.insertSession(createSession(seconds: 600, tag: 'Вечер'));
      await dbProvider.insertSession(createSession(seconds: 900, tag: 'Утро'));

      final tags = await dbProvider.getDistinctTags();
      expect(tags.length, equals(2));
      expect(tags, contains('Утро'));
      expect(tags, contains('Вечер'));
    });

    // ---------------------------------------------------------------------------
    // 7. getFilteredSessions
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

      final sessions = await dbProvider.getFilteredSessions(
        searchQuery: 'Утренняя',
      );
      expect(sessions.length, equals(1));
      expect(sessions.first.note, contains('Утренняя'));
    });

    // ---------------------------------------------------------------------------
    // 8. getSessionsInRange
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

      final sessions = await dbProvider.getSessionsInRange(
        '2026-06-01',
        '2026-06-07',
      );
      expect(sessions.length, equals(2));
    });

    // ---------------------------------------------------------------------------
    // 9. updateSessionFields
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

    // ---------------------------------------------------------------------------
    // 10. deleteSession
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
  });
}
