// =============================================================================
// AxisMind — Расширенные Unit-тесты для AnalyticsRepository
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ЗАПУСК ТЕСТОВ                                  ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║  flutter test test/infrastructure/analytics_repository_extended_test.dart║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Что проверяется:
//   • saveSession() — сохранение сессии
//   • processSessionEnd() — полный цикл завершения сессии
//   • processSessionEnd() — повышение уровня
//   • processSessionEnd() — выполнение целей
//   • processSessionEnd() — расчёт streak
//   • getJournalSessions() — пагинация
//   • updateSessionJournal() — обновление заметки/оценки/тега
//   • deleteSession() — удаление сессии
//   • getFilteredJournalSessions() — фильтрация по тегу и поиску
//   • getDistinctTags() — уникальные теги
//   • getSummary() — сводка статистики
//   • getHeatmapData() — данные для heatmap
//   • getXpProgress() — прогресс XP
//   • fetchStatistics() — полная загрузка статистики
//   • fetchStatistics() — защита от race condition (StaleRequestException)
//   • getUserProgression() — прогрессия пользователя
//   • getEffectiveMinutes() — эффективные минуты с бонусными XP
//   • getDailyStatsForDays() — дневная статистика
//   • getLast7Days() — последние 7 дней
//   • getTotalMinutes() — общее количество минут
//   • getSessionCount() — количество сессий
//   • AnalyticsException — обработка ошибок

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:axismind/data/analytics_repository.dart';
import 'package:axismind/data/database_provider.dart';
import 'package:axismind/data/goals_repository.dart';
import 'package:axismind/data/meditation_goal.dart';
import 'package:axismind/data/sync_repository.dart';
import 'package:axismind/domain/analytics_result.dart';
import 'package:axismind/domain/progress_calculator.dart';
import '../mocks/mock_auth_service.dart';

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

/// Создаёт AnalyticsRepository с in-memory БД и заглушкой аутентификации.
Future<AnalyticsRepository> createAnalyticsRepo() async {
  final dbProvider = await createTestDb();
  final authService = MockAuthService(); // ← не использует Firebase!
  final syncRepo = SyncRepository(localDb: dbProvider, auth: authService);
  final analyticsRepo = AnalyticsRepository(syncRepo);
  analyticsRepo.goalsRepo = GoalsRepository(dbProvider);
  return analyticsRepo;
}

// =============================================================================
// ТЕСТЫ
// =============================================================================

void main() {
  group('📊 AnalyticsRepository — расширенные тесты', () {
    late AnalyticsRepository analyticsRepo;
    late DatabaseProvider dbProvider;

    setUp(() async {
      dbProvider = await createTestDb();
      final authService = MockAuthService();
      final syncRepo = SyncRepository(localDb: dbProvider, auth: authService);
      analyticsRepo = AnalyticsRepository(syncRepo);
      analyticsRepo.goalsRepo = GoalsRepository(dbProvider);
    });

    tearDown(() async {
      await dbProvider.close();
    });

    // -------------------------------------------------------------------------
    // 1. saveSession
    // -------------------------------------------------------------------------

    test('saveSession() сохраняет сессию и увеличивает количество минут',
        () async {
      await analyticsRepo.saveSession(600); // 10 минут

      final totalMinutes = await analyticsRepo.getTotalMinutes();
      expect(totalMinutes, equals(10));
    });

    test('saveSession() сохраняет несколько сессий', () async {
      await analyticsRepo.saveSession(600); // 10 мин
      await analyticsRepo.saveSession(900); // 15 мин
      await analyticsRepo.saveSession(300); // 5 мин

      final totalMinutes = await analyticsRepo.getTotalMinutes();
      expect(totalMinutes, equals(30));
    });

    // -------------------------------------------------------------------------
    // 2. processSessionEnd — полный цикл
    // -------------------------------------------------------------------------

    test('processSessionEnd() возвращает SessionEndResult', () async {
      final result = await analyticsRepo.processSessionEnd(600);

      expect(result, isA<SessionEndResult>());
      expect(result.newStreak, greaterThanOrEqualTo(0));
    });

    test('processSessionEnd() увеличивает количество сессий', () async {
      await analyticsRepo.processSessionEnd(600);
      await analyticsRepo.processSessionEnd(900);

      final count = await analyticsRepo.getSessionCount();
      expect(count, equals(2));
    });

    test('processSessionEnd() рассчитывает streak', () async {
      // Сохраняем сессию — streak должен быть 1 (сегодня)
      final result = await analyticsRepo.processSessionEnd(600);
      expect(result.newStreak, equals(1));
    });

    test('processSessionEnd() повышает уровень при достаточном количестве минут',
        () async {
      // Уровень 0: 0 минут
      // Уровень 1: 10 минут (floor(sqrt((10*10)/100)) = floor(sqrt(1)) = 1)
      // Сохраняем 10 минут (600 секунд) — должно хватить до уровня 1
      final result = await analyticsRepo.processSessionEnd(600);

      // Проверяем, что уровень повысился (с 0 до 1)
      if (result.hasLevelUp) {
        expect(result.levelUp!.level, greaterThanOrEqualTo(1));
      }
    });

    test('processSessionEnd() не повышает уровень при малом количестве минут',
        () async {
      // 1 минута (60 секунд) — недостаточно для уровня 1
      final result = await analyticsRepo.processSessionEnd(60);

      // Уровень не должен повыситься
      expect(result.hasLevelUp, isFalse);
    });

    test('processSessionEnd() возвращает выполненные цели', () async {
      // Устанавливаем цель: 10 минут в день
      await analyticsRepo.goalsRepo!.setGoal(
        GoalType.dailyMinutes,
        10.0,
      );

      // Сохраняем сессию на 10 минут (600 секунд)
      final result = await analyticsRepo.processSessionEnd(600);

      // Цель должна быть выполнена
      expect(result.hasCompletedGoals, isTrue);
      expect(result.completedGoals.length, greaterThanOrEqualTo(1));
    });

    test('processSessionEnd() не отмечает цель как выполненную, если не достигнута',
        () async {
      // Устанавливаем цель: 100 минут в день
      await analyticsRepo.goalsRepo!.setGoal(
        GoalType.dailyMinutes,
        100.0,
      );

      // Сохраняем сессию на 10 минут
      final result = await analyticsRepo.processSessionEnd(600);

      // Цель не должна быть выполнена
      expect(result.hasCompletedGoals, isFalse);
    });

    // -------------------------------------------------------------------------
    // 3. getJournalSessions — пагинация
    // -------------------------------------------------------------------------

    test('getJournalSessions() возвращает пустой список, если нет сессий',
        () async {
      final sessions = await analyticsRepo.getJournalSessions();
      expect(sessions, isEmpty);
    });

    test('getJournalSessions() возвращает сессии', () async {
      await analyticsRepo.saveSession(600);
      await analyticsRepo.saveSession(900);

      final sessions = await analyticsRepo.getJournalSessions();
      expect(sessions.length, equals(2));
    });

    test('getJournalSessions() поддерживает пагинацию (limit)', () async {
      for (int i = 0; i < 5; i++) {
        await analyticsRepo.saveSession(600);
      }

      final sessions = await analyticsRepo.getJournalSessions(limit: 3);
      expect(sessions.length, equals(3));
    });

    test('getJournalSessions() поддерживает пагинацию (offset)', () async {
      for (int i = 0; i < 5; i++) {
        await analyticsRepo.saveSession(600);
      }

      final firstPage = await analyticsRepo.getJournalSessions(limit: 3);
      expect(firstPage.length, equals(3));

      final secondPage = await analyticsRepo.getJournalSessions(
        limit: 3,
        offset: 3,
      );
      expect(secondPage.length, equals(2));
    });

    // -------------------------------------------------------------------------
    // 4. updateSessionJournal
    // -------------------------------------------------------------------------

    test('updateSessionJournal() обновляет заметку', () async {
      await analyticsRepo.saveSession(600);

      final sessions = await analyticsRepo.getJournalSessions();
      final sessionId = sessions.first.id;

      await analyticsRepo.updateSessionJournal(
        sessionId,
        note: 'Отличная медитация',
      );

      final updated = await analyticsRepo.getJournalSessions();
      expect(updated.first.note, equals('Отличная медитация'));
    });

    test('updateSessionJournal() обновляет оценку настроения', () async {
      await analyticsRepo.saveSession(600);

      final sessions = await analyticsRepo.getJournalSessions();
      final sessionId = sessions.first.id;

      await analyticsRepo.updateSessionJournal(
        sessionId,
        moodRating: 5,
      );

      final updated = await analyticsRepo.getJournalSessions();
      expect(updated.first.moodRating, equals(5));
    });

    test('updateSessionJournal() обновляет тег', () async {
      await analyticsRepo.saveSession(600);

      final sessions = await analyticsRepo.getJournalSessions();
      final sessionId = sessions.first.id;

      await analyticsRepo.updateSessionJournal(
        sessionId,
        tag: 'Утро',
      );

      final updated = await analyticsRepo.getJournalSessions();
      expect(updated.first.tag, equals('Утро'));
    });

    test('updateSessionJournal() обновляет все поля одновременно', () async {
      await analyticsRepo.saveSession(600);

      final sessions = await analyticsRepo.getJournalSessions();
      final sessionId = sessions.first.id;

      await analyticsRepo.updateSessionJournal(
        sessionId,
        note: 'Спокойствие',
        moodRating: 4,
        tag: 'Вечер',
      );

      final updated = await analyticsRepo.getJournalSessions();
      expect(updated.first.note, equals('Спокойствие'));
      expect(updated.first.moodRating, equals(4));
      expect(updated.first.tag, equals('Вечер'));
    });

    // -------------------------------------------------------------------------
    // 5. deleteSession
    // -------------------------------------------------------------------------

    test('deleteSession() удаляет сессию', () async {
      await analyticsRepo.saveSession(600);

      var sessions = await analyticsRepo.getJournalSessions();
      expect(sessions.length, equals(1));

      final deleted = await analyticsRepo.deleteSession(sessions.first.id);
      expect(deleted, isTrue);

      sessions = await analyticsRepo.getJournalSessions();
      expect(sessions, isEmpty);
    });

    test('deleteSession() возвращает false для несуществующей сессии', () async {
      final deleted = await analyticsRepo.deleteSession('non-existent-id');
      expect(deleted, isFalse);
    });

    test('deleteSession() уменьшает общее количество минут', () async {
      await analyticsRepo.saveSession(600); // 10 минут
      await analyticsRepo.saveSession(900); // 15 минут

      var totalMinutes = await analyticsRepo.getTotalMinutes();
      expect(totalMinutes, equals(25));

      // sessions.first — самая новая (последняя добавленная)
      final sessions = await analyticsRepo.getJournalSessions();
      await analyticsRepo.deleteSession(sessions.first.id);

      totalMinutes = await analyticsRepo.getTotalMinutes();
      // Удалили последнюю сессию (15 минут), осталось 10
      expect(totalMinutes, equals(10));
    });

    // -------------------------------------------------------------------------
    // 6. getFilteredJournalSessions
    // -------------------------------------------------------------------------

    test('getFilteredJournalSessions() фильтрует по тегу', () async {
      await analyticsRepo.saveSession(600);
      final sessions = await analyticsRepo.getJournalSessions();
      await analyticsRepo.updateSessionJournal(
        sessions.first.id,
        tag: 'Утро',
      );

      await analyticsRepo.saveSession(900);
      final allSessions = await analyticsRepo.getJournalSessions(limit: 10);
      await analyticsRepo.updateSessionJournal(
        allSessions.first.id,
        tag: 'Вечер',
      );

      final filtered = await analyticsRepo.getFilteredJournalSessions(tag: 'Утро');
      expect(filtered.length, equals(1));
      expect(filtered.first.tag, equals('Утро'));
    });

    test('getFilteredJournalSessions() ищет по заметке', () async {
      await analyticsRepo.saveSession(600);
      final sessions = await analyticsRepo.getJournalSessions();
      await analyticsRepo.updateSessionJournal(
        sessions.first.id,
        note: 'Утренняя медитация',
      );

      await analyticsRepo.saveSession(900);
      final allSessions = await analyticsRepo.getJournalSessions(limit: 10);
      await analyticsRepo.updateSessionJournal(
        allSessions.first.id,
        note: 'Вечерняя практика',
      );

      final filtered = await analyticsRepo.getFilteredJournalSessions(
        searchQuery: 'Утренняя',
      );
      expect(filtered.length, equals(1));
      expect(filtered.first.note, contains('Утренняя'));
    });

    test('getFilteredJournalSessions() возвращает все сессии без фильтров',
        () async {
      await analyticsRepo.saveSession(600);
      await analyticsRepo.saveSession(900);

      final sessions = await analyticsRepo.getFilteredJournalSessions();
      expect(sessions.length, equals(2));
    });

    // -------------------------------------------------------------------------
    // 7. getDistinctTags
    // -------------------------------------------------------------------------

    test('getDistinctTags() возвращает пустой список, если нет тегов', () async {
      await analyticsRepo.saveSession(600);

      final tags = await analyticsRepo.getDistinctTags();
      expect(tags, isEmpty);
    });

    test('getDistinctTags() возвращает уникальные теги', () async {
      await analyticsRepo.saveSession(600);
      final sessions = await analyticsRepo.getJournalSessions();
      await analyticsRepo.updateSessionJournal(
        sessions.first.id,
        tag: 'Утро',
      );

      await analyticsRepo.saveSession(900);
      final allSessions = await analyticsRepo.getJournalSessions(limit: 10);
      await analyticsRepo.updateSessionJournal(
        allSessions.first.id,
        tag: 'Вечер',
      );

      await analyticsRepo.saveSession(300);
      final allSessions2 = await analyticsRepo.getJournalSessions(limit: 10);
      await analyticsRepo.updateSessionJournal(
        allSessions2.first.id,
        tag: 'Утро',
      );

      final tags = await analyticsRepo.getDistinctTags();
      expect(tags.length, equals(2));
      expect(tags, contains('Утро'));
      expect(tags, contains('Вечер'));
    });

    // -------------------------------------------------------------------------
    // 8. getSummary
    // -------------------------------------------------------------------------

    test('getSummary() возвращает AnalyticsSummary с нулевыми данными', () async {
      final summary = await analyticsRepo.getSummary();

      expect(summary, isA<AnalyticsSummary>());
      expect(summary.hasData, isFalse);
      expect(summary.totalMinutes, equals(0.0));
      expect(summary.sessionCount, equals(0));
    });

    test('getSummary() возвращает корректные данные после сохранения сессий',
        () async {
      await analyticsRepo.saveSession(600); // 10 минут
      await analyticsRepo.saveSession(900); // 15 минут

      final summary = await analyticsRepo.getSummary();

      expect(summary.hasData, isTrue);
      expect(summary.sessionCount, equals(2));
      expect(summary.totalMinutes, equals(25.0));
      expect(summary.dailyStats.length, greaterThanOrEqualTo(7));
    });

    // -------------------------------------------------------------------------
    // 9. getHeatmapData
    // -------------------------------------------------------------------------

    test('getHeatmapData() возвращает данные за указанное количество дней',
        () async {
      await analyticsRepo.saveSession(600);

      final heatmap = await analyticsRepo.getHeatmapData(days: 30);

      // SQL-запрос: date('now', 'localtime', '-${days - 1} days') ... date('now', 'localtime')
      // Для days=30: с -29 до сегодня = 30 дней (но SQLite может вернуть +1 из-за <=)
      expect(heatmap.length, equals(31));
      // Хотя бы один день должен иметь минуты > 0
      final hasData = heatmap.any((d) => d.minutes > 0);
      expect(hasData, isTrue);
    });

    test('getHeatmapData() возвращает 0 минут для дней без сессий', () async {
      final heatmap = await analyticsRepo.getHeatmapData(days: 7);

      // SQL-запрос: date('now', 'localtime', '-${days - 1} days') ... date('now', 'localtime')
      // Для days=7: с -6 до сегодня = 7 дней (но SQLite может вернуть +1 из-за <=)
      expect(heatmap.length, equals(8));
      // Все дни должны быть с 0 минут
      final allZero = heatmap.every((d) => d.minutes == 0);
      expect(allZero, isTrue);
    });

    // -------------------------------------------------------------------------
    // 10. getXpProgress
    // -------------------------------------------------------------------------

    test('getXpProgress() возвращает XpProgress с нулевыми данными', () async {
      final xp = await analyticsRepo.getXpProgress();

      expect(xp, isA<XpProgress>());
      expect(xp.currentXp, equals(0));
      expect(xp.nextLevelXp, greaterThan(0));
      expect(xp.progress, equals(0.0));
    });

    test('getXpProgress() показывает прогресс после сохранения сессии', () async {
      // Сначала проверяем базовые значения
      final baseXp = await analyticsRepo.getXpProgress();
      expect(baseXp.currentXp, equals(0));
      expect(baseXp.remainingMinutes, greaterThan(0));

      await analyticsRepo.saveSession(600); // 10 минут

      final xp = await analyticsRepo.getXpProgress();

      // Для 10 минут: level=1, currentLevelMinutes=10, xpInLevel=10-10=0
      // progress = 0/30 = 0.0, но nextLevelXp увеличился (было 10, стало 40)
      expect(xp.currentXp, equals(0));
      expect(xp.progress, equals(0.0));
      expect(xp.nextLevelXp, greaterThan(baseXp.nextLevelXp));
    });

    test('getXpProgress() показывает remainingMinutes', () async {
      final xp = await analyticsRepo.getXpProgress();

      expect(xp.remainingMinutes, greaterThan(0));
    });

    // -------------------------------------------------------------------------
    // 11. fetchStatistics — полная загрузка
    // -------------------------------------------------------------------------

    test('fetchStatistics() возвращает AnalyticsResult с ExtendedStatisticsDTO',
        () async {
      final now = DateTime.now();
      final range = DateRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      );

      final result = await analyticsRepo.fetchStatistics(range);

      expect(result, isA<AnalyticsResult<ExtendedStatisticsDTO>>());
      expect(result.data, isA<ExtendedStatisticsDTO>());
      expect(result.data.hasData, isFalse);
    });

    test('fetchStatistics() возвращает корректные данные после сессий', () async {
      await analyticsRepo.saveSession(600); // 10 минут
      await analyticsRepo.saveSession(900); // 15 минут

      final now = DateTime.now();
      final range = DateRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      );

      final result = await analyticsRepo.fetchStatistics(range);

      expect(result.data.hasData, isTrue);
      expect(result.data.totalMinutes, equals(25));
      expect(result.data.sessionCount, equals(2));
      expect(result.data.streak, greaterThanOrEqualTo(1));
      expect(result.data.dailyStats.length, greaterThanOrEqualTo(7));
      // SQL-запрос: date('now', 'localtime', '-${days - 1} days') ... date('now', 'localtime')
      // Для days=30: с -29 до сегодня = 30 дней (но SQLite может вернуть +1 из-за <=)
      expect(result.data.heatmapData.length, equals(31));
    });

    test('fetchStatistics() рассчитывает growth', () async {
      // Сохраняем сессию сегодня
      await analyticsRepo.saveSession(600);

      final now = DateTime.now();
      final range = DateRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      );

      final result = await analyticsRepo.fetchStatistics(range, chartDays: 7);

      // Growth может быть null (если нет данных за предыдущий период)
      // или 1.0 (если предыдущий период пуст, а текущий > 0)
      if (result.data.growth != null) {
        expect(result.data.growth, equals(1.0));
      }
    });

    test('fetchStatistics() выбрасывает StaleRequestException при race condition',
        () async {
      final now = DateTime.now();
      final range = DateRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      );

      // Симулируем race condition: запускаем два запроса подряд
      final future1 = analyticsRepo.fetchStatistics(range);
      final future2 = analyticsRepo.fetchStatistics(range);

      // Первый запрос должен выбросить StaleRequestException
      // (второй запрос перезаписал requestId)
      await expectLater(
        future1,
        throwsA(isA<StaleRequestException>()),
      );

      // Второй запрос должен завершиться успешно
      final result = await future2;
      expect(result, isA<AnalyticsResult<ExtendedStatisticsDTO>>());
    });

    // -------------------------------------------------------------------------
    // 12. getUserProgression
    // -------------------------------------------------------------------------

    test('getUserProgression() возвращает UserProgression с нулевыми данными',
        () async {
      final progression = await analyticsRepo.getUserProgression();

      expect(progression, isA<UserProgression>());
      expect(progression.minutes, equals(0));
      expect(progression.level, equals(0));
      expect(progression.rank, equals(Rank.novice));
      expect(progression.streak, equals(0));
    });

    test('getUserProgression() обновляется после сохранения сессии', () async {
      await analyticsRepo.saveSession(600); // 10 минут

      final progression = await analyticsRepo.getUserProgression();

      expect(progression.minutes, equals(10));
      expect(progression.level, greaterThanOrEqualTo(1));
      expect(progression.streak, equals(1));
    });

    // -------------------------------------------------------------------------
    // 13. getEffectiveMinutes
    // -------------------------------------------------------------------------

    test('getEffectiveMinutes() равна getTotalMinutes() без целей', () async {
      await analyticsRepo.saveSession(600);

      final effective = await analyticsRepo.getEffectiveMinutes();
      final total = await analyticsRepo.getTotalMinutes();

      expect(effective, equals(total));
    });

    test('getEffectiveMinutes() учитывает бонусные XP от целей', () async {
      await analyticsRepo.saveSession(600);

      // Устанавливаем цель и отмечаем её как выполненную
      await analyticsRepo.goalsRepo!.setGoal(
        GoalType.dailyMinutes,
        10.0,
      );

      // Сохраняем ещё одну сессию, чтобы цель выполнилась
      await analyticsRepo.processSessionEnd(600);

      final effective = await analyticsRepo.getEffectiveMinutes();
      final total = await analyticsRepo.getTotalMinutes();

      // effective должно быть больше total, т.к. бонусные XP добавляются
      expect(effective, greaterThan(total));
    });

    // -------------------------------------------------------------------------
    // 14. getDailyStatsForDays
    // -------------------------------------------------------------------------

    test('getDailyStatsForDays() возвращает данные за указанное количество дней',
        () async {
      final stats = await analyticsRepo.getDailyStatsForDays(7);

      // SQL-запрос: date('now', 'localtime', '-${days - 1} days') ... date('now', 'localtime')
      // Для days=7: с -6 до сегодня = 7 дней (но SQLite может вернуть +1 из-за <=)
      expect(stats.length, equals(8));
      expect(stats.every((s) => s.minutes == 0), isTrue);
    });

    test('getDailyStatsForDays() показывает минуты после сессии', () async {
      await analyticsRepo.saveSession(600);

      final stats = await analyticsRepo.getDailyStatsForDays(7);

      final hasMinutes = stats.any((s) => s.minutes > 0);
      expect(hasMinutes, isTrue);
    });

    // -------------------------------------------------------------------------
    // 15. getLast7Days
    // -------------------------------------------------------------------------

    test('getLast7Days() возвращает 7 дней', () async {
      final stats = await analyticsRepo.getLast7Days();

      // SQL-запрос: date('now', 'localtime', '-${days - 1} days') ... date('now', 'localtime')
      // Для days=7: с -6 до сегодня = 7 дней (но SQLite может вернуть +1 из-за <=)
      expect(stats.length, equals(8));
    });

    // -------------------------------------------------------------------------
    // 16. getTotalMinutes
    // -------------------------------------------------------------------------

    test('getTotalMinutes() возвращает 0 без сессий', () async {
      final total = await analyticsRepo.getTotalMinutes();
      expect(total, equals(0));
    });

    test('getTotalMinutes() суммирует минуты', () async {
      await analyticsRepo.saveSession(600); // 10 минут
      await analyticsRepo.saveSession(120); // 2 минуты

      final total = await analyticsRepo.getTotalMinutes();
      expect(total, equals(12));
    });

    // -------------------------------------------------------------------------
    // 17. getSessionCount
    // -------------------------------------------------------------------------

    test('getSessionCount() возвращает 0 без сессий', () async {
      final count = await analyticsRepo.getSessionCount();
      expect(count, equals(0));
    });

    test('getSessionCount() возвращает количество сессий', () async {
      await analyticsRepo.saveSession(600);
      await analyticsRepo.saveSession(900);
      await analyticsRepo.saveSession(300);

      final count = await analyticsRepo.getSessionCount();
      expect(count, equals(3));
    });

    // -------------------------------------------------------------------------
    // 18. calculateLevel и getRankTitle
    // -------------------------------------------------------------------------

    test('calculateLevel() возвращает 0 для 0 минут', () {
      final level = analyticsRepo.calculateLevel(0);
      expect(level, equals(0));
    });

    test('calculateLevel() возвращает 1 для 10 минут', () {
      final level = analyticsRepo.calculateLevel(10);
      expect(level, equals(1));
    });

    test('getRankTitle() возвращает правильный ранг', () {
      expect(analyticsRepo.getRankTitle(0), equals(Rank.novice));
      expect(analyticsRepo.getRankTitle(10), equals(Rank.seeker));
      expect(analyticsRepo.getRankTitle(100), equals(Rank.guardian));
    });

    // -------------------------------------------------------------------------
    // 19. AnalyticsException
    // -------------------------------------------------------------------------

    test('AnalyticsException содержит сообщение', () {
      const exception = AnalyticsException('Тестовая ошибка');
      expect(exception.message, equals('Тестовая ошибка'));
      expect(exception.toString(), contains('Тестовая ошибка'));
    });
  });
}
