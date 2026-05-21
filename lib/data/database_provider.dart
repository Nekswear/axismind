import 'package:flutter/foundation.dart';
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

  /// Stores initialization error to prevent silent retry loops.
  static Object? _initError;

  /// The underlying database reference.
  Database? _db;

  /// Current database version for migration tracking.
  ///
  /// Version history:
  ///   1 — Initial schema (id, timestamp, seconds, note)
  ///   2 — Added mood_rating and tag columns for Session Journal
  ///   3 — mood_rating and tag now included in CREATE TABLE (for Web)
  ///   4 — Added updated_at column for conflict resolution during sync
  ///   5 — Added goals table for user meditation goals
  ///   6 — Added notification_settings table for push notification preferences
  ///   7 — Added motivational_time and goal_reminder_time columns
  ///   8 — Added subscription table for RevenueCat subscription caching
  static const int _dbVersion = 8;

  /// Database name.
  static const String _dbName = 'zenbalance.db';

  /// Table name for meditation sessions.
  static const String tableSessions = 'sessions';

  /// Table name for user meditation goals.
  static const String tableGoals = 'goals';

  /// Table name for push notification settings.
  static const String tableNotificationSettings = 'notification_settings';

  /// Table name for subscription caching.
  static const String tableSubscription = 'subscription';

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

    // If initialization previously failed, throw the stored error
    if (_initError != null) {
      throw DatabaseException(
        'База данных не инициализирована. Пожалуйста, перезапустите приложение. '
        'Причина: $_initError',
      );
    }

    // Guard against concurrent initialization
    if (_initializing) {
      // Wait for the current initialization to complete
      while (_initializing) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      if (_instance != null) return _instance!;
      if (_initError != null) {
        throw DatabaseException(
          'База данных не инициализирована. Пожалуйста, перезапустите приложение. '
          'Причина: $_initError',
        );
      }
      throw DatabaseException(
        'База данных не инициализирована. Пожалуйста, перезапустите приложение.',
      );
    }

    _initializing = true;
    try {
      final provider = DatabaseProvider._();
      await provider._init();
      _instance = provider;
      return _instance!;
    } catch (e) {
      _initError = e;
      rethrow;
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
        note TEXT,
        mood_rating INTEGER,
        tag TEXT,
        updated_at TEXT
      )
    ''');

    // Create index on timestamp for efficient date-range queries
    await db.execute('''
      CREATE INDEX idx_sessions_timestamp ON $tableSessions (timestamp)
    ''');

    // Create goals table (v5)
    await db.execute('''
      CREATE TABLE $tableGoals (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        target_value REAL NOT NULL,
        bonus_xp INTEGER NOT NULL DEFAULT 50,
        rewarded INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create notification_settings table (v6, extended in v7)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableNotificationSettings (
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
    // Миграция v2 → v3: гарантируем наличие колонок (для Web, где БД
    // могла быть создана без них, т.к. _onCreate не включал их ранее)
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE sessions ADD COLUMN mood_rating INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE sessions ADD COLUMN tag TEXT');
      } catch (_) {}
    }
    // Миграция v3 → v4: добавляем колонку updated_at для разрешения
    // конфликтов при синхронизации (Race Condition fix)
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE sessions ADD COLUMN updated_at TEXT');
        debugPrint('Migration v3→v4: added updated_at column');
      } catch (e) {
        debugPrint('Migration v3→v4: column may already exist: $e');
      }
    }
    // Миграция v4 → v5: добавляем таблицу goals
    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableGoals (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            target_value REAL NOT NULL,
            bonus_xp INTEGER NOT NULL DEFAULT 50,
            rewarded INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        debugPrint('Migration v4→v5: created goals table');
      } catch (e) {
        debugPrint('Migration v4→v5: error creating goals table: $e');
      }
    }
    // Миграция v5 → v6: добавляем таблицу notification_settings
    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableNotificationSettings (
            id TEXT PRIMARY KEY DEFAULT 'default',
            enabled INTEGER NOT NULL DEFAULT 1,
            reminder_time TEXT NOT NULL DEFAULT '08:00',
            motivational_enabled INTEGER NOT NULL DEFAULT 0,
            goal_reminder_enabled INTEGER NOT NULL DEFAULT 0,
            quiet_hours_start TEXT,
            quiet_hours_end TEXT,
            fcm_token TEXT,
            updated_at TEXT NOT NULL
          )
        ''');
        debugPrint('Migration v5→v6: created notification_settings table');
      } catch (e) {
        debugPrint('Migration v5→v6: error creating notification_settings table: $e');
      }
    }
    // Миграция v6 → v7: добавляем колонки motivational_time и goal_reminder_time
    if (oldVersion < 7) {
      try {
        await db.execute(
          'ALTER TABLE $tableNotificationSettings ADD COLUMN motivational_time TEXT NOT NULL DEFAULT \'12:00\'',
        );
        debugPrint('Migration v6→v7: added motivational_time column');
      } catch (e) {
        debugPrint('Migration v6→v7: motivational_time column may already exist: $e');
      }
      try {
        await db.execute(
          'ALTER TABLE $tableNotificationSettings ADD COLUMN goal_reminder_time TEXT NOT NULL DEFAULT \'19:00\'',
        );
        debugPrint('Migration v6→v7: added goal_reminder_time column');
      } catch (e) {
        debugPrint('Migration v6→v7: goal_reminder_time column may already exist: $e');
      }
    }
    // Миграция v7 → v8: добавляем таблицу subscription для кэширования подписки
    if (oldVersion < 8) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableSubscription (
            id TEXT PRIMARY KEY DEFAULT 'default',
            is_active INTEGER NOT NULL DEFAULT 0,
            is_trial INTEGER NOT NULL DEFAULT 0,
            expiration_date TEXT,
            product_id TEXT,
            purchased_at TEXT,
            updated_at TEXT NOT NULL
          )
        ''');
        debugPrint('Migration v7→v8: created subscription table');
      } catch (e) {
        debugPrint('Migration v7→v8: error creating subscription table: $e');
      }
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

  /// Вставляет сессию только если она новее существующей (по [updatedAt]).
  ///
  /// Используется при синхронизации из облака, чтобы предотвратить
  /// восстановление удалённых или устаревших данных (Race Condition fix).
  ///
  /// Логика:
  /// - Если в БД нет сессии с таким [id] — вставляем (новая запись).
  /// - Если есть, но у неё нет [updatedAt] — считаем устаревшей, перезаписываем.
  /// - Если есть и [updatedAt] у новой версии больше — перезаписываем.
  /// - Иначе — пропускаем (локальная версия новее).
  Future<void> insertSessionIfNewer(Session session) async {
    try {
      await db.transaction((txn) async {
        // Проверяем, есть ли уже такая сессия
        final existing = await txn.query(
          tableSessions,
          columns: ['updated_at'],
          where: 'id = ?',
          whereArgs: [session.id],
        );

        if (existing.isEmpty) {
          // Новая запись — вставляем
          await txn.insert(
            tableSessions,
            session.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          return;
        }

        // Проверяем updatedAt
        final existingUpdatedAt = existing.first['updated_at'] as String?;

        // Если у существующей нет updatedAt — она устаревшая, перезаписываем
        if (existingUpdatedAt == null) {
          await txn.update(
            tableSessions,
            session.toMap(),
            where: 'id = ?',
            whereArgs: [session.id],
          );
          return;
        }

        // Если у новой нет updatedAt — пропускаем (не можем определить новизну)
        if (session.updatedAt == null) return;

        // Сравниваем: если новая версия новее — обновляем
        if (session.updatedAt!.compareTo(existingUpdatedAt) > 0) {
          await txn.update(
            tableSessions,
            session.toMap(),
            where: 'id = ?',
            whereArgs: [session.id],
          );
        }
        // Иначе — локальная версия новее, ничего не делаем
      });
    } catch (e) {
      throw DatabaseException('Failed to insert session if newer: $e');
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
  ///
  /// **Важно**: использует `date(timestamp, 'localtime')`, чтобы даты
  /// сессий соответствовали локальному часовому поясу пользователя.
  /// Без 'localtime' при смене часового пояса streak может сброситься,
  /// т.к. timestamp хранится в UTC.
  Future<List<String>> getDistinctSessionDates() async {
    try {
      final result = await db.rawQuery('''
        SELECT DISTINCT date(timestamp, 'localtime') AS session_date
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

  /// Обновляет поле [updatedAt] существующей сессии.
  ///
  /// Используется при частичном обновлении полей (заметка, оценка, тег),
  /// чтобы отметить сессию как изменённую для корректной синхронизации.
  Future<void> updateSessionUpdatedAt(String sessionId, String updatedAt) async {
    try {
      await db.update(
        tableSessions,
        {'updated_at': updatedAt},
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    } catch (e) {
      throw DatabaseException('Не удалось обновить updated_at: $e');
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

  // ===========================================================================
  // Goals table methods
  // ===========================================================================

  /// Возвращает все цели из таблицы goals.
  Future<List<Map<String, dynamic>>> getGoals() async {
    try {
      return await db.query(tableGoals, orderBy: 'created_at ASC');
    } catch (e) {
      throw DatabaseException('Не удалось получить цели: $e');
    }
  }

  /// Возвращает одну цель по ID.
  Future<Map<String, dynamic>?> getGoalById(String id) async {
    try {
      final result = await db.query(
        tableGoals,
        where: 'id = ?',
        whereArgs: [id],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      throw DatabaseException('Не удалось получить цель: $e');
    }
  }

  /// Сохраняет или обновляет цель (UPSERT).
  Future<void> saveGoal(Map<String, dynamic> goalMap) async {
    try {
      await db.transaction((txn) async {
        await txn.insert(
          tableGoals,
          goalMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    } catch (e) {
      throw DatabaseException('Не удалось сохранить цель: $e');
    }
  }

  /// Удаляет цель по ID.
  Future<void> deleteGoal(String id) async {
    try {
      await db.delete(
        tableGoals,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Не удалось удалить цель: $e');
    }
  }

  /// Обновляет флаг rewarded для цели.
  Future<void> updateGoalRewarded(String id, bool rewarded) async {
    try {
      await db.update(
        tableGoals,
        {
          'rewarded': rewarded ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Не удалось обновить rewarded: $e');
    }
  }

  /// Сбрасывает rewarded для daily целей (новый день).
  Future<void> resetDailyRewards() async {
    try {
      await db.update(
        tableGoals,
        {'rewarded': 0},
        where: 'type = ?',
        whereArgs: ['daily_minutes'],
      );
    } catch (e) {
      throw DatabaseException('Не удалось сбросить daily rewards: $e');
    }
  }

  /// Сбрасывает rewarded для weekly целей (новая неделя).
  Future<void> resetWeeklyRewards() async {
    try {
      await db.update(
        tableGoals,
        {'rewarded': 0},
        where: 'type IN (?, ?)',
        whereArgs: ['weekly_sessions', 'weekly_minutes'],
      );
    } catch (e) {
      throw DatabaseException('Не удалось сбросить weekly rewards: $e');
    }
  }

  /// Возвращает сумму bonus_xp всех целей с rewarded=1.
  Future<int> getTotalBonusXp() async {
    try {
      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(bonus_xp), 0) AS total
        FROM $tableGoals
        WHERE rewarded = 1
      ''');
      return (result.first['total'] as num).toInt();
    } catch (e) {
      throw DatabaseException('Не удалось получить сумму бонусных XP: $e');
    }
  }

  // ===========================================================================
  // Notification settings table methods
  // ===========================================================================

  /// Возвращает настройки уведомлений (одна строка с id='default').
  /// Возвращает null, если запись не найдена.
  Future<Map<String, dynamic>?> getNotificationSettings() async {
    try {
      final result = await db.query(
        tableNotificationSettings,
        where: 'id = ?',
        whereArgs: ['default'],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      throw DatabaseException('Не удалось получить настройки уведомлений: $e');
    }
  }

  /// Сохраняет настройки уведомлений (UPSERT).
  Future<void> saveNotificationSettings(Map<String, dynamic> settings) async {
    try {
      await db.transaction((txn) async {
        await txn.insert(
          tableNotificationSettings,
          settings,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    } catch (e) {
      throw DatabaseException('Не удалось сохранить настройки уведомлений: $e');
    }
  }

  /// Сохраняет FCM токен устройства.
  Future<void> saveFcmToken(String token) async {
    try {
      await db.transaction((txn) async {
        // Проверяем, есть ли уже запись
        final existing = await txn.query(
          tableNotificationSettings,
          where: 'id = ?',
          whereArgs: ['default'],
        );

        if (existing.isNotEmpty) {
          await txn.update(
            tableNotificationSettings,
            {
              'fcm_token': token,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: ['default'],
          );
        } else {
          await txn.insert(
            tableNotificationSettings,
            {
              'id': 'default',
              'fcm_token': token,
              'updated_at': DateTime.now().toIso8601String(),
            },
          );
        }
      });
    } catch (e) {
      throw DatabaseException('Не удалось сохранить FCM токен: $e');
    }
  }

  /// Возвращает сохранённый FCM токен (null если нет).
  Future<String?> getFcmToken() async {
    try {
      final result = await db.query(
        tableNotificationSettings,
        columns: ['fcm_token'],
        where: 'id = ?',
        whereArgs: ['default'],
      );
      if (result.isNotEmpty) {
        return result.first['fcm_token'] as String?;
      }
      return null;
    } catch (e) {
      throw DatabaseException('Не удалось получить FCM токен: $e');
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
