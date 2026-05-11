import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/analytics_result.dart';
import '../domain/level_up_event.dart';
import '../domain/progress_calculator.dart';
import '../utils/time_utils.dart';
import 'database_provider.dart';
import 'session.dart';

/// Repository for analytics data access.
///
/// Encapsulates all analytics-related database queries and provides
/// high-level data models for the UI layer.
class AnalyticsRepository {
  final DatabaseProvider _dbProvider;

  /// Счётчик запросов для защиты от race conditions.
  /// Каждый вызов [fetchStatistics] инкрементирует его.
  /// Если приходит новый запрос до завершения старого,
  /// старый результат отбрасывается.
  int _requestCounter = 0;

  /// Creates an [AnalyticsRepository] with the given [DatabaseProvider].
  AnalyticsRepository(this._dbProvider);

  /// Returns daily meditation minutes for the last 7 days.
  ///
  /// Every day is represented, including days with zero sessions
  /// (thanks to the LEFT JOIN + date generation in SQL).
  Future<List<DailyStats>> getLast7Days() async {
    try {
      final rows = await _dbProvider.getDailyMinutes(7);
      return rows.map((row) {
        return DailyStats(
          date: row['date'] as String,
          minutes: (row['minutes'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      throw AnalyticsException('Не удалось получить данные за 7 дней: $e');
    }
  }

  /// Saves a completed meditation session.
  Future<void> saveSession(int seconds) async {
    try {
      final session = Session(seconds: seconds);
      await _dbProvider.insertSession(session);
    } catch (e) {
      throw AnalyticsException('Не удалось сохранить сессию: $e');
    }
  }

  /// Обрабатывает завершение сессии и проверяет повышение уровня.
  ///
  /// 1. Получает старое общее количество минут.
  /// 2. Сохраняет новую сессию.
  /// 3. Получает новое общее количество минут.
  /// 4. Сравнивает уровни через [ProgressCalculator].
  /// 5. Если уровень вырос — возвращает [LevelUpEvent].
  ///
  /// Возвращает [LevelUpEvent] при повышении уровня, иначе `null`.
  Future<LevelUpEvent?> processSessionEnd(int durationSeconds) async {
    try {
      // Шаг 1: старый уровень до сохранения
      final oldMinutes = await getTotalMinutes();
      final oldLevel = ProgressCalculator.calculateLevel(oldMinutes);

      // Шаг 2: сохраняем сессию
      final session = Session(seconds: durationSeconds);
      await _dbProvider.insertSession(session);

      // Шаг 3: новый уровень после сохранения
      final newMinutes = await getTotalMinutes();
      final newLevel = ProgressCalculator.calculateLevel(newMinutes);

      // Шаг 4–5: сравниваем
      if (newLevel > oldLevel) {
        return LevelUpEvent(
          level: newLevel,
          rank: ProgressCalculator.getRank(newLevel),
        );
      }

      return null;
    } catch (e) {
      throw AnalyticsException('Не удалось обработать завершение сессии: $e');
    }
  }

  /// Returns total meditation minutes (целое число) across all sessions.
  ///
  /// Расчёт: SUM(seconds) / 60, округление вниз.
  /// При отсутствии данных возвращает 0.
  Future<int> getTotalMinutes() async {
    try {
      final totalSeconds = await _dbProvider.getTotalDurationSeconds();
      return (totalSeconds / 60).floor();
    } catch (e) {
      throw AnalyticsException('Не удалось получить общее количество минут: $e');
    }
  }

  /// Рассчитывает уровень пользователя на основе общего количества минут.
  ///
  /// Делегирует вычисление в [ProgressCalculator.calculateLevel].
  int calculateLevel(int minutes) {
    return ProgressCalculator.calculateLevel(minutes);
  }

  /// Возвращает название ранга по количеству минут.
  ///
  /// Делегирует вычисление уровня в [ProgressCalculator.calculateLevel],
  /// затем маппинг ранга — в [ProgressCalculator.getRank].
  String getRankTitle(int minutes) {
    final level = ProgressCalculator.calculateLevel(minutes);
    return ProgressCalculator.getRank(level);
  }

  /// Загружает уровень, ранг и streak пользователя.
  ///
  /// Возвращает [UserProgression] с актуальными данными.
  Future<UserProgression> getUserProgression() async {
    try {
      final minutes = await getTotalMinutes();
      final level = ProgressCalculator.calculateLevel(minutes);
      final rank = ProgressCalculator.getRank(level);
      final dates = await _dbProvider.getDistinctSessionDates();
      final streak = ProgressCalculator.calculateStreak(dates);
      return UserProgression(
        minutes: minutes,
        level: level,
        rank: rank,
        streak: streak,
      );
    } catch (e) {
      throw AnalyticsException('Не удалось загрузить прогрессию пользователя: $e');
    }
  }

  /// Returns total session count.
  Future<int> getSessionCount() async {
    try {
      return await _dbProvider.getSessionCount();
    } catch (e) {
      throw AnalyticsException('Не удалось получить количество сессий: $e');
    }
  }

  /// Возвращает все сессии для дневника, отсортированные по дате (сначала новые).
  ///
  /// [limit] — максимальное количество записей (пагинация, по умолчанию 20).
  /// [offset] — смещение от начала.
  Future<List<Session>> getJournalSessions({int limit = 20, int offset = 0}) async {
    try {
      return await _dbProvider.getAllSessions(limit: limit, offset: offset);
    } catch (e) {
      throw AnalyticsException('Не удалось загрузить дневник: $e');
    }
  }

  /// Обновляет заметку, оценку настроения и тег последней сессии.
  ///
  /// Вызывается после [JournalDialog], когда пользователь ввёл свои ощущения.
  /// Находит последнюю сессию по ID (передаётся из диалога).
  Future<void> updateSessionJournal(
    String sessionId, {
    String? note,
    int? moodRating,
    String? tag,
  }) async {
    try {
      await _dbProvider.updateSessionFields(
        sessionId,
        note: note,
        moodRating: moodRating,
        tag: tag,
      );
    } catch (e) {
      throw AnalyticsException('Не удалось обновить запись дневника: $e');
    }
  }

  /// Returns a summary model combining all analytics data.
  Future<AnalyticsSummary> getSummary() async {
    try {
      final results = await Future.wait([
        getLast7Days(),
        getTotalMinutes(),
        getSessionCount(),
      ]);

      return AnalyticsSummary(
        dailyStats: results[0] as List<DailyStats>,
        totalMinutes: (results[1] as int).toDouble(),
        sessionCount: results[2] as int,
      );
    } catch (e) {
      throw AnalyticsException('Не удалось получить сводку: $e');
    }
  }
  /// Возвращает данные для Heatmap за последние [days] дней.
  ///
  /// Каждый день представлен моделью [HeatmapDay] с датой и минутами.
  /// Дни без сессий возвращаются с minutes = 0.0.
  Future<List<HeatmapDay>> getHeatmapData({int days = 30}) async {
    try {
      final rows = await _dbProvider.getDailyMinutesForPeriod(days);
      return rows.map((row) {
        return HeatmapDay(
          date: row['date'] as String,
          minutes: (row['minutes'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      throw AnalyticsException('Не удалось получить данные heatmap: $e');
    }
  }

  /// Рассчитывает прогресс XP до следующего уровня.
  ///
  /// Возвращает [XpProgress] с текущим XP, XP до следующего уровня
  /// и процентом заполнения шкалы.
  Future<XpProgress> getXpProgress() async {
    try {
      final minutes = await getTotalMinutes();
      final level = calculateLevel(minutes);

      // Формула: level = floor(sqrt((minutes * 10) / 100))
      // Обратная: minutesForLevel = ((level + 1)^2 * 100) / 10
      final nextLevelMinutes = ((pow(level + 1, 2) * 100) / 10).round();
      final currentLevelMinutes = ((pow(level, 2) * 100) / 10).round();

      final xpInLevel = minutes - currentLevelMinutes;
      final xpNeeded = nextLevelMinutes - currentLevelMinutes;
      final progress = xpNeeded > 0 ? xpInLevel / xpNeeded : 1.0;

      // Остаток минут до следующего уровня
      final remainingMinutes = nextLevelMinutes - minutes;

      return XpProgress(
        currentXp: xpInLevel,
        nextLevelXp: xpNeeded,
        progress: progress.clamp(0.0, 1.0),
        remainingMinutes: remainingMinutes > 0 ? remainingMinutes : 0,
      );
    } catch (e) {
      throw AnalyticsException('Не удалось рассчитать прогресс XP: $e');
    }
  }
  /// Загружает всю статистику за диапазон [range].
  ///
  /// Возвращает [AnalyticsResult] с [ExtendedStatisticsDTO] внутри.
  ///
  /// Защита от race condition: каждая загрузка получает уникальный
  /// номер запроса. Если приходит новый запрос до завершения старого,
  /// старый результат отбрасывается выбрасыванием [StaleRequestException].
  Future<AnalyticsResult<ExtendedStatisticsDTO>> fetchStatistics(
    DateRange range,
  ) async {
    final requestId = ++_requestCounter;
    final timestamp = DateTime.now();

    try {
      // Загружаем все данные параллельно
      final results = await Future.wait([
        getTotalMinutes(),
        getSessionCount(),
        getLast7Days(),
        getHeatmapData(days: 30),
        getXpProgress(),
        getUserProgression(),
        _dbProvider.getDistinctSessionDates(),
        _getPreviousWeekMinutes(range),
      ]);

      // Проверка: не устарел ли запрос
      if (_requestCounter != requestId) {
        throw StaleRequestException();
      }

      final totalMinutes = results[0] as int;
      final sessionCount = results[1] as int;
      final dailyStats = results[2] as List<DailyStats>;
      final heatmapData = results[3] as List<HeatmapDay>;
      final xpProgress = results[4] as XpProgress;
      final progression = results[5] as UserProgression;
      final dates = results[6] as List<String>;
      final previousWeekMinutes = results[7] as int;

      // Рассчитываем streak
      final streak = ProgressCalculator.calculateStreak(dates);

      // Рассчитываем growth: текущая неделя vs предыдущая неделя
      final currentWeekMinutes = dailyStats.fold<int>(
        0,
        (sum, d) => sum + d.minutes.toInt(),
      );
      final growth = ProgressCalculator.calculateGrowth(
        currentWeekMinutes,
        previousWeekMinutes,
      );

      return AnalyticsResult<ExtendedStatisticsDTO>(
        data: ExtendedStatisticsDTO(
          totalMinutes: totalMinutes,
          sessionCount: sessionCount,
          streak: streak,
          growth: growth,
          dailyStats: dailyStats,
          heatmapData: heatmapData,
          xpProgress: xpProgress,
          progression: progression,
        ),
        timestamp: timestamp,
      );
    } on StaleRequestException {
      // Пробрасываем дальше — это не ошибка, а отмена
      rethrow;
    } catch (e) {
      throw AnalyticsException('Не удалось загрузить статистику: $e');
    }
  }

  /// Загружает сумму минут за неделю, предшествующую [range].
  ///
  /// Используется для расчёта growth: сравниваем текущие 7 дней
  /// с предыдущими 7 днями.
  Future<int> _getPreviousWeekMinutes(DateRange range) async {
    try {
      final previousEnd = range.start.subtract(const Duration(days: 1));
      final previousStart = previousEnd.subtract(const Duration(days: 6));

      final startStr =
          '${previousStart.year}-${_pad(previousStart.month)}-${_pad(previousStart.day)}';
      final endStr =
          '${previousEnd.year}-${_pad(previousEnd.month)}-${_pad(previousEnd.day)}';

      final sessions =
          await _dbProvider.getSessionsInRange(startStr, endStr);
      final totalSeconds =
          sessions.fold<int>(0, (sum, s) => sum + s.seconds);
      return (totalSeconds / 60).floor();
    } catch (e) {
      // Если предыдущая неделя не загрузилась — возвращаем 0
      debugPrint('Ошибка загрузки предыдущей недели: $e');
      return 0;
    }
  }

  /// Дополняет число ведущим нулём до 2 символов.
  String _pad(int value) => value.toString().padLeft(2, '0');
}

/// Диапазон дат для статистики.
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});
}

/// Расширенное DTO статистики — возвращается из [fetchStatistics].
///
/// Содержит все данные, необходимые для отрисовки панели статистики:
/// общие минуты, количество сессий, streak, growth, графики и прогрессию.
class ExtendedStatisticsDTO {
  /// Общее количество минут медитации.
  final int totalMinutes;

  /// Общее количество завершённых сессий.
  final int sessionCount;

  /// Текущая серия дней подряд.
  final int streak;

  /// Относительный рост практики (может быть null, если нет данных).
  final double? growth;

  /// Почасовая статистика за последние 7 дней.
  final List<DailyStats> dailyStats;

  /// Данные для heatmap за 30 дней.
  final List<HeatmapDay> heatmapData;

  /// Прогресс XP до следующего уровня.
  final XpProgress xpProgress;

  /// Прогрессия пользователя (минуты, уровень, ранг).
  final UserProgression progression;

  const ExtendedStatisticsDTO({
    required this.totalMinutes,
    required this.sessionCount,
    required this.streak,
    this.growth,
    required this.dailyStats,
    required this.heatmapData,
    required this.xpProgress,
    required this.progression,
  });

  /// Есть ли хотя бы одна сессия.
  bool get hasData => sessionCount > 0;
}

/// Исключение, указывающее, что запрос статистики устарел
/// и был заменён более новым запросом.
///
/// Не является ошибкой — это механизм отмены для защиты
/// от race conditions при быстрых последовательных вызовах.
class StaleRequestException implements Exception {
  @override
  String toString() => 'Запрос устарел — был заменён более новым';
}

/// Модель прогрессии пользователя: минуты, уровень, ранг, серия дней.
class UserProgression {
  /// Общее количество минут медитации.
  final int minutes;

  /// Текущий уровень (рассчитывается по формуле).
  final int level;

  /// Название ранга.
  final String rank;

  /// Количество дней подряд с медитацией (streak).
  final int streak;

  const UserProgression({
    required this.minutes,
    required this.level,
    required this.rank,
    this.streak = 0,
  });
}

/// Модель одного дня для Heatmap.
///
/// Содержит дату и суммарную длительность медитации в минутах.
class HeatmapDay {
  /// Дата в ISO-формате (например, "2026-05-08").
  final String date;

  /// Суммарная длительность медитации за этот день в минутах.
  final double minutes;

  const HeatmapDay({required this.date, required this.minutes});
}

/// Модель прогресса XP до следующего уровня.
///
/// Содержит текущий XP, необходимый XP для следующего уровня,
/// прогресс (0.0–1.0) и остаток минут.
class XpProgress {
  /// Текущее количество XP в уровне.
  final int currentXp;

  /// Сколько XP нужно для следующего уровня.
  final int nextLevelXp;

  /// Прогресс от 0.0 до 1.0.
  final double progress;

  /// Остаток минут до следующего уровня.
  final int remainingMinutes;

  const XpProgress({
    required this.currentXp,
    required this.nextLevelXp,
    required this.progress,
    required this.remainingMinutes,
  });
}

/// Daily aggregated meditation statistics.
class DailyStats {
  /// Date string in ISO format (e.g., "2026-05-08").
  final String date;

  /// Total meditation minutes for this day.
  final double minutes;

  const DailyStats({required this.date, required this.minutes});

  /// Short label for chart display (e.g., "08.05").
  String get shortLabel => TimeUtils.formatDateShort(date);

  /// Day name for chart display (e.g., "Пт").
  String get dayLabel => TimeUtils.formatDayShort(date);
}

/// Comprehensive analytics summary.
class AnalyticsSummary {
  /// Daily stats for the last 7 days.
  final List<DailyStats> dailyStats;

  /// Total meditation minutes across all time.
  final double totalMinutes;

  /// Total number of completed sessions.
  final int sessionCount;

  const AnalyticsSummary({
    required this.dailyStats,
    required this.totalMinutes,
    required this.sessionCount,
  });

  /// Whether there is any data to display.
  bool get hasData => sessionCount > 0;

  /// Average minutes per day over the last 7 days.
  double get averageMinutes {
    if (dailyStats.isEmpty) return 0.0;
    final total = dailyStats.fold<double>(0.0, (sum, d) => sum + d.minutes);
    return (total / dailyStats.length).roundToDouble() / 1.0;
  }
}

/// Custom exception for analytics errors.
class AnalyticsException implements Exception {
  final String message;
  const AnalyticsException(this.message);

  @override
  String toString() => 'AnalyticsException: $message';
}
