import 'package:flutter/foundation.dart';

import '../domain/level_up_event.dart';

/// Тип цели медитации.
enum GoalType {
  /// Минут медитации в день.
  dailyMinutes,

  /// Количество сессий в неделю.
  weeklySessions,

  /// Минут медитации в неделю.
  weeklyMinutes,

  /// Цель по непрерывной серии дней (streak).
  streakDays;

  /// Возвращает строковое представление для SQLite.
  String get dbValue => name;

  /// Создаёт [GoalType] из строки SQLite.
  static GoalType fromDb(String value) {
    return GoalType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GoalType.dailyMinutes,
    );
  }

  /// Человекочитаемое название цели.
  String get displayName {
    switch (this) {
      case GoalType.dailyMinutes:
        return 'Ежедневная практика';
      case GoalType.weeklySessions:
        return 'Сессий в неделю';
      case GoalType.weeklyMinutes:
        return 'Минут в неделю';
      case GoalType.streakDays:
        return 'Дней подряд';
    }
  }

  /// XP за выполнение этой цели.
  int get defaultBonusXp {
    switch (this) {
      case GoalType.dailyMinutes:
        return 50;
      case GoalType.weeklySessions:
        return 100;
      case GoalType.weeklyMinutes:
        return 150;
      case GoalType.streakDays:
        return 200;
    }
  }
}

/// Модель цели медитации.
///
/// Хранится в SQLite в таблице `goals`.
@immutable
class MeditationGoal {
  /// Уникальный идентификатор цели (UUID).
  final String id;

  /// Тип цели.
  final GoalType type;

  /// Целевое значение (например, 10.0 для 10 минут).
  final double targetValue;

  /// XP за выполнение цели.
  final int bonusXp;

  /// Флаг: начислены ли XP за текущий период.
  final bool rewarded;

  /// Дата создания.
  final DateTime createdAt;

  /// Дата последнего обновления.
  final DateTime updatedAt;

  const MeditationGoal({
    required this.id,
    required this.type,
    required this.targetValue,
    this.bonusXp = 50,
    this.rewarded = false,
    required this.createdAt,
    required this.updatedAt,
  });

  MeditationGoal copyWith({
    String? id,
    GoalType? type,
    double? targetValue,
    int? bonusXp,
    bool? rewarded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeditationGoal(
      id: id ?? this.id,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      bonusXp: bonusXp ?? this.bonusXp,
      rewarded: rewarded ?? this.rewarded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Создаёт [MeditationGoal] из мапы SQLite.
  factory MeditationGoal.fromMap(Map<String, dynamic> map) {
    return MeditationGoal(
      id: map['id'] as String,
      type: GoalType.fromDb(map['type'] as String),
      targetValue: (map['target_value'] as num).toDouble(),
      bonusXp: (map['bonus_xp'] as num?)?.toInt() ?? 50,
      rewarded: (map['rewarded'] as num?)?.toInt() == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Сериализует в мапу для SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.dbValue,
      'target_value': targetValue,
      'bonus_xp': bonusXp,
      'rewarded': rewarded ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeditationGoal &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MeditationGoal(id: $id, type: $type, target: $targetValue, '
      'bonusXp: $bonusXp, rewarded: $rewarded)';
}

/// Прогресс по конкретной цели.
@immutable
class GoalWithProgress {
  /// Цель.
  final MeditationGoal goal;

  /// Прогресс от 0.0 до 1.0.
  final double progress;

  /// Текущее накопленное значение (например, 8 минут из 10).
  final double currentValue;

  /// Выполнена ли цель (progress >= 1.0).
  final bool isCompleted;

  const GoalWithProgress({
    required this.goal,
    required this.progress,
    required this.currentValue,
    required this.isCompleted,
  });

  @override
  String toString() =>
      'GoalWithProgress(goal: ${goal.type}, '
      '${(progress * 100).toStringAsFixed(0)}%, '
      '${isCompleted ? "✓" : "○"})';
}

/// Результат завершения сессии — содержит информацию
/// о повышении уровня и/или выполненных целях.
class SessionEndResult {
  /// Событие повышения уровня (null, если уровень не изменился).
  final LevelUpEvent? levelUp;

  /// Список целей, которые были выполнены в этой сессии.
  final List<GoalWithProgress> completedGoals;

  /// Новая длина streak после этой сессии.
  final int newStreak;

  /// Был ли повышение уровня?
  bool get hasLevelUp => levelUp != null;

  /// Были ли выполнены какие-то цели?
  bool get hasCompletedGoals => completedGoals.isNotEmpty;

  /// Был ли установлен новый рекорд streak?
  bool get hasNewStreakRecord => newStreak > 1;

  const SessionEndResult({
    this.levelUp,
    this.completedGoals = const [],
    this.newStreak = 0,
  });
}
