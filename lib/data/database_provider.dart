import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import 'session.dart';

/// Singleton database provider with thread-safe initialization.
///
/// Uses a simple mutex pattern to prevent race conditions during
/// concurrent access. All write operations are wrapped in
/// [db.transaction()] for atomicity.
class DatabaseProvider {
  /// Singleton instance.
  static DatabaseProvider? _instance;

  /// Simple mutex flag to prevent concurrent initialization.
  static bool _initializing = false;

  /// The underlying database reference.
  Database? _db;

  /// Current database version for migration tracking.
  ///
  /// Version history:
  ///   1 — Initial schema (id, timestamp, seconds, note)
  ///   2 — Added mood_rating and tag columns for Session Journal
  static const int _dbVersion = 2;

  /// Database name.
  static const String _dbName = 'zenbalance.db';

  /// Table name for meditation sessions.
  static const String tableSessions = 'sessions';

  /// Private constructor — use [instance()] to get the singleton.
  DatabaseProvider._();

  /// Creates a [DatabaseProvider] with a pre-initialized database for testing.
  ///
  /// This bypasses the singleton pattern and file-based initialization,
  /// allowing tests to use an in-memory database.
  DatabaseProvider.forTest(this._db);

  /// Returns the singleton [DatabaseProvider], initializing it if needed.
  ///
  /// Uses a spin-loop guard with [_initializing] flag to prevent
  /// race conditions when multiple isolates or async tasks call
  /// [instance()] simultaneously.
  static Future<DatabaseProvider> instance() async {
    if (_instance != null) return _instance!;

    // Guard against concurrent initialization
    if (_initializing) {
      // Wait for the current initialization to complete
      while (_initializing) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return _instance!;
    }

    _initializing = true;
    try {
      final provider = DatabaseProvider._();
      await provider._init();
      _instance = provider;
      return _instance!;
    } finally {
      _initializing = false;
    }
  }

  /// Initializes the database with schema and migrations.
  Future<void> _init() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the initial database schema.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableSessions (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        seconds INTEGER NOT NULL,
        note TEXT
      )
    ''');

    // Create index on timestamp for efficient date-range queries
    await db.execute('''
      CREATE INDEX idx_sessions_timestamp ON $tableSessions (timestamp)
    ''');
  }

  /// Handles schema migrations for future versions.
  ///
  /// This method is migration-ready: when [DatabaseProvider._dbVersion] is
  /// incremented, [onUpgrade] is called with [oldVersion] and [newVersion].
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Миграция v1 → v2: добавляем колонки для дневника сессий
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE sessions ADD COLUMN mood_rating INTEGER');
      await db.execute('ALTER TABLE sessions ADD COLUMN tag TEXT');
    }
  }

  /// Returns the raw [Database] reference.
  ///
  /// Throws [StateError] if the database is not initialized.
  Database get db {
    if (_db == null) {
      throw StateError(
        'Database not initialized. Call DatabaseProvider.instance() first.',
      );
    }
    return _db!;
  }

  /// Inserts a [Session] into the database within a transaction.
  ///
  /// All write operations are wrapped in [db.transaction()] to ensure atomicity.
  /// If any part of the transaction fails, all changes are rolled back.
  Future<void> insertSession(Session session) async {
    try {
      await db.transaction((txn) async {
        await txn.insert(
          tableSessions,
          session.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    } catch (e) {
      throw DatabaseException('Failed to insert session: $e');
    }
  }

  /// Retrieves all sessions within a date range (inclusive).
  ///
  /// [start] and [end] should be ISO 8601 date strings (e.g., '2026-05-01').
  Future<List<Session>> getSessionsInRange(String start, String end) async {
    try {
      final maps = await db.query(
        tableSessions,
        where: 'timestamp >= ? AND timestamp < ?',
        whereArgs: [start, end],
        orderBy: 'timestamp ASC',
      );
      return maps.map((m) => Session.fromMap(m)).toList();
    } catch (e) {
      throw DatabaseException('Failed to query sessions: $e');
    }
  }

  /// Returns daily aggregated data for the last [days] days.
  ///
  /// Uses a generated date series to ensure days with no sessions
  /// still appear in the result (with 0.0 minutes).
  Future<List<Map<String, dynamic>>> getDailyMinutes(int days) async {
    try {
      // Generate date series for the last N days using a recursive CTE,
      // then LEFT JOIN with aggregated session data.
      // This ensures every day appears in the result, even with zero sessions.
      final result = await db.rawQuery('''
        WITH RECURSIVE dates(date) AS (
          SELECT date('now', 'localtime', '-${days - 1} days')
          UNION ALL
          SELECT date(date, '+1 day')
          FROM dates
          WHERE date <= date('now', 'localtime')
        )
        SELECT
          d.date,
          COALESCE(ROUND(SUM(s.seconds) / 60.0, 1), 0.0) AS minutes
        FROM dates d
        LEFT JOIN $tableSessions s
          ON date(s.timestamp) = d.date
        GROUP BY d.date
        ORDER BY d.date ASC
      ''');
      return result;
    } catch (e) {
      throw DatabaseException('Failed to aggregate daily minutes: $e');
    }
  }

  /// Returns daily aggregated data for the last [days] days (generic version).
  ///
  /// Используется для Heatmap — группировка сессий по датам за произвольный период.
  Future<List<Map<String, dynamic>>> getDailyMinutesForPeriod(int days) async {
    try {
      final result = await db.rawQuery('''
        WITH RECURSIVE dates(date) AS (
          SELECT date('now', 'localtime', '-${days - 1} days')
          UNION ALL
          SELECT date(date, '+1 day')
          FROM dates
          WHERE date <= date('now', 'localtime')
        )
        SELECT
          d.date,
          COALESCE(ROUND(SUM(s.seconds) / 60.0, 1), 0.0) AS minutes
        FROM dates d
        LEFT JOIN $tableSessions s
          ON date(s.timestamp) = d.date
        GROUP BY d.date
        ORDER BY d.date ASC
      ''');
      return result;
    } catch (e) {
      throw DatabaseException('Не удалось агрегировать минуты за $days дней: $e');
    }
  }

  /// Returns total meditation minutes for all time.
  Future<double> getTotalMinutes() async {
    try {
      final result = await db.rawQuery('''
        SELECT COALESCE(ROUND(SUM(seconds) / 60.0, 1), 0.0) AS total
        FROM $tableSessions
      ''');
      return (result.first['total'] as num).toDouble();
    } catch (e) {
      throw DatabaseException('Failed to get total minutes: $e');
    }
  }

  /// Returns total duration in seconds across all sessions.
  ///
  /// Returns 0 if no sessions exist (SUM returns NULL).
  Future<int> getTotalDurationSeconds() async {
    try {
      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(seconds), 0) AS total
        FROM $tableSessions
      ''');
      return (result.first['total'] as num).toInt();
    } catch (e) {
      throw DatabaseException('Не удалось получить суммарную длительность: $e');
    }
  }

  /// Returns the session count.
  Future<int> getSessionCount() async {
    try {
      final result = await db.rawQuery('''
        SELECT COUNT(*) AS count FROM $tableSessions
      ''');
      return result.first['count'] as int;
    } catch (e) {
      throw DatabaseException('Failed to get session count: $e');
    }
  }

  /// Возвращает список уникальных дат (ISO) всех сессий.
  ///
  /// Используется для расчёта streak в [ProgressCalculator.calculateStreak].
  Future<List<String>> getDistinctSessionDates() async {
    try {
      final result = await db.rawQuery('''
        SELECT DISTINCT date(timestamp) AS session_date
        FROM $tableSessions
        ORDER BY session_date ASC
      ''');
      return result.map((r) => r['session_date'] as String).toList();
    } catch (e) {
      throw DatabaseException('Не удалось получить список дат сессий: $e');
    }
  }

  /// Возвращает все сессии, отсортированные по дате (сначала новые).
  ///
  /// [limit] — максимальное количество записей (пагинация).
  /// [offset] — смещение от начала.
  Future<List<Session>> getAllSessions({int? limit, int? offset}) async {
    try {
      final maps = await db.query(
        tableSessions,
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );
      return maps.map((m) => Session.fromMap(m)).toList();
    } catch (e) {
      throw DatabaseException('Не удалось получить список сессий: $e');
    }
  }

  /// Обновляет заметку, оценку настроения и тег существующей сессии.
  ///
  /// Обновляются только поля, переданные как non-null.
  Future<void> updateSessionFields(
    String sessionId, {
    String? note,
    int? moodRating,
    String? tag,
  }) async {
    try {
      final fields = <String, dynamic>{};
      if (note != null) fields['note'] = note;
      if (moodRating != null) fields['mood_rating'] = moodRating;
      if (tag != null) fields['tag'] = tag;

      if (fields.isEmpty) return;

      await db.update(
        tableSessions,
        fields,
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    } catch (e) {
      throw DatabaseException('Не удалось обновить сессию: $e');
    }
  }

  /// Удаляет сессию по её ID.
  ///
  /// Возвращает `true`, если запись была удалена, `false` — если не найдена.
  Future<bool> deleteSession(String sessionId) async {
    try {
      final count = await db.delete(
        tableSessions,
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      return count > 0;
    } catch (e) {
      throw DatabaseException('Не удалось удалить сессию: $e');
    }
  }

  /// Возвращает список уникальных тегов всех сессий.
  ///
  /// Используется для фильтрации записей в дневнике.
  Future<List<String>> getDistinctTags() async {
    try {
      final result = await db.rawQuery('''
        SELECT DISTINCT tag FROM $tableSessions
        WHERE tag IS NOT NULL
        ORDER BY tag ASC
      ''');
      return result.map((r) => r['tag'] as String).toList();
    } catch (e) {
      throw DatabaseException('Не удалось получить список тегов: $e');
    }
  }

  /// Возвращает сессии, отфильтрованные по тегу и/или поисковому запросу.
  ///
  /// [tag] — фильтр по тегу (null = все теги).
  /// [searchQuery] — поиск по заметке (регистронезависимый, null = без фильтра).
  /// [limit] — максимальное количество записей (пагинация).
  /// [offset] — смещение от начала.
  Future<List<Session>> getFilteredSessions({
    String? tag,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      final conditions = <String>[];
      final args = <dynamic>[];

      if (tag != null) {
        conditions.add('tag = ?');
        args.add(tag);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        conditions.add('note LIKE ?');
        args.add('%$searchQuery%');
      }

      final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;

      final maps = await db.query(
        tableSessions,
        where: where,
        whereArgs: args.isNotEmpty ? args : null,
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );
      return maps.map((m) => Session.fromMap(m)).toList();
    } catch (e) {
      throw DatabaseException('Не удалось выполнить поиск сессий: $e');
    }
  }

  /// Closes the database connection.
  ///
  /// Call this only when the application is terminating.
  Future<void> close() async {
    await _db?.close();
    _db = null;
    _instance = null;
  }
}

/// Custom exception for database errors.
class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
