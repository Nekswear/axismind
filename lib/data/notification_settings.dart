import 'package:flutter/foundation.dart';

/// Тип пуш-уведомления.
enum NotificationType {
  /// Ежедневное напоминание о медитации.
  dailyReminder,

  /// Мотивационные сообщения и цитаты.
  motivational,

  /// Напоминание о невыполненной цели (вечером).
  goalReminder,

  /// Поздравление с новым streak-рекордом.
  streakCelebration;

  /// Человекочитаемое название типа уведомления.
  String get displayName {
    switch (this) {
      case NotificationType.dailyReminder:
        return 'Напоминание о практике';
      case NotificationType.motivational:
        return 'Мотивационные сообщения';
      case NotificationType.goalReminder:
        return 'Напоминание о целях';
      case NotificationType.streakCelebration:
        return 'Поздравления с рекордами';
    }
  }

  /// Иконка Material Icons для типа уведомления.
  String get icon {
    switch (this) {
      case NotificationType.dailyReminder:
        return 'schedule';
      case NotificationType.motivational:
        return 'psychology';
      case NotificationType.goalReminder:
        return 'track_changes';
      case NotificationType.streakCelebration:
        return 'local_fire_department';
    }
  }

  /// Описание типа уведомления.
  String get description {
    switch (this) {
      case NotificationType.dailyReminder:
        return 'Ежедневное напоминание в выбранное время';
      case NotificationType.motivational:
        return 'Вдохновляющие цитаты и статистика прогресса';
      case NotificationType.goalReminder:
        return 'Напоминание вечером, если цель дня ещё не выполнена';
      case NotificationType.streakCelebration:
        return 'Поздравление при достижении нового рекорда дней подряд';
    }
  }
}

/// Настройки пуш-уведомлений пользователя.
///
/// Хранится в SQLite в таблице `notification_settings`.
/// Всегда одна запись с id = 'default'.
@immutable
class NotificationSettings {
  /// Уникальный ID (всегда 'default' — одна запись).
  final String id;

  /// Включены ли уведомления вообще.
  final bool enabled;

  /// Время ежедневного напоминания (HH:mm).
  final String reminderTime;

  /// Включены ли мотивационные уведомления.
  final bool motivationalEnabled;

  /// Время показа мотивационных уведомлений (HH:mm).
  final String motivationalTime;

  /// Включено ли напоминание о целях (вечером).
  final bool goalReminderEnabled;

  /// Время напоминания о целях (HH:mm).
  final String goalReminderTime;

  /// Время начала тихих часов (HH:mm), null = отключено.
  final String? quietHoursStart;

  /// Время окончания тихих часов (HH:mm), null = отключено.
  final String? quietHoursEnd;

  /// FCM токен устройства (заполняется автоматически).
  final String? fcmToken;

  /// Дата последнего обновления.
  final DateTime updatedAt;

  const NotificationSettings({
    this.id = 'default',
    this.enabled = true,
    this.reminderTime = '08:00',
    this.motivationalEnabled = false,
    this.motivationalTime = '12:00',
    this.goalReminderEnabled = false,
    this.goalReminderTime = '19:00',
    this.quietHoursStart,
    this.quietHoursEnd,
    this.fcmToken,
    required this.updatedAt,
  });

  /// Создаёт [NotificationSettings] из мапы SQLite.
  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      id: map['id'] as String? ?? 'default',
      enabled: map.containsKey('enabled')
          ? (map['enabled'] as num).toInt() == 1
          : true,
      reminderTime: map['reminder_time'] as String? ?? '08:00',
      motivationalEnabled: map.containsKey('motivational_enabled')
          ? (map['motivational_enabled'] as num).toInt() == 1
          : false,
      motivationalTime: map['motivational_time'] as String? ?? '12:00',
      goalReminderEnabled: map.containsKey('goal_reminder_enabled')
          ? (map['goal_reminder_enabled'] as num).toInt() == 1
          : false,
      goalReminderTime: map['goal_reminder_time'] as String? ?? '19:00',
      quietHoursStart: map['quiet_hours_start'] as String?,
      quietHoursEnd: map['quiet_hours_end'] as String?,
      fcmToken: map['fcm_token'] as String?,
      updatedAt: map.containsKey('updated_at')
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Сериализует в мапу для SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enabled': enabled ? 1 : 0,
      'reminder_time': reminderTime,
      'motivational_enabled': motivationalEnabled ? 1 : 0,
      'motivational_time': motivationalTime,
      'goal_reminder_enabled': goalReminderEnabled ? 1 : 0,
      'goal_reminder_time': goalReminderTime,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'fcm_token': fcmToken,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Возвращает копию с обновлёнными полями.
  NotificationSettings copyWith({
    String? id,
    bool? enabled,
    String? reminderTime,
    bool? motivationalEnabled,
    String? motivationalTime,
    bool? goalReminderEnabled,
    String? goalReminderTime,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? fcmToken,
    DateTime? updatedAt,
  }) {
    return NotificationSettings(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      reminderTime: reminderTime ?? this.reminderTime,
      motivationalEnabled: motivationalEnabled ?? this.motivationalEnabled,
      motivationalTime: motivationalTime ?? this.motivationalTime,
      goalReminderEnabled: goalReminderEnabled ?? this.goalReminderEnabled,
      goalReminderTime: goalReminderTime ?? this.goalReminderTime,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      fcmToken: fcmToken ?? this.fcmToken,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Проверяет, активны ли тихие часы в указанное время.
  bool isInQuietHours(DateTime time) {
    if (quietHoursStart == null || quietHoursEnd == null) return false;

    final partsStart = quietHoursStart!.split(':');
    final partsEnd = quietHoursEnd!.split(':');
    final startMin =
        int.parse(partsStart[0]) * 60 + int.parse(partsStart[1]);
    final endMin = int.parse(partsEnd[0]) * 60 + int.parse(partsEnd[1]);
    final currentMin = time.hour * 60 + time.minute;

    if (startMin <= endMin) {
      // Обычный случай: например 07:00–22:00 — диапазон в пределах дня
      return currentMin >= startMin && currentMin < endMin;
    } else {
      // startMin > endMin: диапазон через полночь, например 22:00–07:00
      return currentMin >= startMin || currentMin < endMin;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettings &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'NotificationSettings(enabled: $enabled, reminderTime: $reminderTime, '
      'motivational: $motivationalEnabled ($motivationalTime), '
      'goalReminder: $goalReminderEnabled ($goalReminderTime), '
      'quietHours: $quietHoursStart–$quietHoursEnd)';
}
