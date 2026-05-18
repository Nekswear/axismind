import 'package:uuid/uuid.dart';

import 'database_provider.dart';
import 'meditation_goal.dart';

/// Репозиторий для работы с целями медитации.
///
/// Предоставляет CRUD-операции для целей и расчёт прогресса
/// с управлением флагами rewarded (начисление бонусных XP).
class GoalsRepository {
  final DatabaseProvider _db;

  const GoalsRepository(this._db);

  /// Возвращает все цели.
  Future<List<MeditationGoal>> getGoals() async {
    final rows = await _db.getGoals();
    return rows.map((row) => MeditationGoal.fromMap(row)).toList();
  }

  /// Сохраняет или обновляет цель.
  ///
  /// Если цель с таким [type] уже существует — обновляет её.
  /// Иначе создаёт новую.
  Future<void> setGoal(
    GoalType type,
    double targetValue, {
    int? bonusXp,
  }) async {
    final now = DateTime.now().toIso8601String();
    final existing = await _findGoalByType(type);

    if (existing != null) {
      // Обновляем существующую
      await _db.saveGoal({
        'id': existing.id,
        'type': type.dbValue,
        'target_value': targetValue,
        'bonus_xp': bonusXp ?? type.defaultBonusXp,
        'rewarded': existing.rewarded ? 1 : 0,
        'created_at': existing.createdAt.toIso8601String(),
        'updated_at': now,
      });
    } else {
      // Создаём новую
      const uuid = Uuid();
      await _db.saveGoal({
        'id': uuid.v4(),
        'type': type.dbValue,
        'target_value': targetValue,
        'bonus_xp': bonusXp ?? type.defaultBonusXp,
        'rewarded': 0,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  /// Удаляет цель по ID.
  Future<void> removeGoal(String id) async {
    await _db.deleteGoal(id);
  }

  /// Рассчитывает прогресс по всем целям и обновляет флаги rewarded.
  ///
  /// Принимает готовые метрики, чтобы не дублировать логику запросов.
  /// Возвращает список целей с прогрессом.
  ///
  /// Логика rewarded:
  /// - Если цель выполнена и rewarded=false → начисляем XP (rewarded=true)
  /// - Если цель не выполнена и rewarded=true → отзываем XP (rewarded=false)
  Future<List<GoalWithProgress>> calculateAndUpdateProgress({
    required int todayMinutes,
    required int weeklySessions,
    required int weeklyMinutes,
    required int currentStreak,
  }) async {
    final goals = await getGoals();
    final results = <GoalWithProgress>[];

    for (final goal in goals) {
      final currentValue = _getCurrentValue(goal.type, todayMinutes,
          weeklySessions, weeklyMinutes, currentStreak);
      final progress =
          goal.targetValue > 0 ? (currentValue / goal.targetValue).clamp(0.0, 1.0) : 0.0;
      final isCompleted = progress >= 1.0;

      results.add(GoalWithProgress(
        goal: goal,
        progress: progress,
        currentValue: currentValue,
        isCompleted: isCompleted,
      ));

      // Управление rewarded
      if (isCompleted && !goal.rewarded) {
        // Начисляем XP
        await _db.updateGoalRewarded(goal.id, true);
      } else if (!isCompleted && goal.rewarded) {
        // Отзываем XP
        await _db.updateGoalRewarded(goal.id, false);
      }
    }

    return results;
  }

  /// Возвращает сумму бонусных XP всех целей с rewarded=1.
  Future<int> getTotalBonusXp() async {
    return _db.getTotalBonusXp();
  }

  /// Сбрасывает rewarded для целей, у которых начался новый период.
  ///
  /// Вызывается при загрузке приложения для daily (каждый день)
  /// и weekly (каждый понедельник) целей.
  Future<void> resetExpiredRewards() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Проверяем daily цели: сбрасываем rewarded, если сегодня новый день
    // относительно updated_at цели
    final goals = await getGoals();
    for (final goal in goals) {
      if (!goal.rewarded) continue;

      final goalDate = DateTime(
        goal.updatedAt.year,
        goal.updatedAt.month,
        goal.updatedAt.day,
      );

      switch (goal.type) {
        case GoalType.dailyMinutes:
          // Если updated_at был вчера или раньше — сбрасываем
          if (goalDate.isBefore(today)) {
            await _db.updateGoalRewarded(goal.id, false);
          }
          break;
        case GoalType.weeklySessions:
        case GoalType.weeklyMinutes:
          // Если updated_at был до понедельника — сбрасываем
          final lastMonday = today.subtract(Duration(days: today.weekday - 1));
          if (goalDate.isBefore(lastMonday)) {
            await _db.updateGoalRewarded(goal.id, false);
          }
          break;
        case GoalType.streakDays:
          // Streak цели не сбрасываются по периодам
          break;
      }
    }
  }

  // ===========================================================================
  // Private helpers
  // ===========================================================================

  /// Ищет цель по типу.
  Future<MeditationGoal?> _findGoalByType(GoalType type) async {
    final goals = await getGoals();
    try {
      return goals.firstWhere((g) => g.type == type);
    } catch (_) {
      return null;
    }
  }

  /// Возвращает текущее значение для цели по её типу.
  double _getCurrentValue(
    GoalType type,
    int todayMinutes,
    int weeklySessions,
    int weeklyMinutes,
    int currentStreak,
  ) {
    switch (type) {
      case GoalType.dailyMinutes:
        return todayMinutes.toDouble();
      case GoalType.weeklySessions:
        return weeklySessions.toDouble();
      case GoalType.weeklyMinutes:
        return weeklyMinutes.toDouble();
      case GoalType.streakDays:
        return currentStreak.toDouble();
    }
  }
}
