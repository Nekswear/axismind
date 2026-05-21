// =============================================================================
// ZenBalance — Unit-тесты для NotificationSettings модели
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ЗАПУСК ТЕСТОВ                                  ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║  flutter test test/notification/notification_settings_test.dart         ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Проверяет:
//   • Конструктор и значения по умолчанию
//   • fromMap / toMap сериализацию
//   • copyWith
//   • isInQuietHours
//   • toString
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:zenbalance/data/notification_settings.dart';

void main() {
  group('📋 NotificationSettings — конструктор и значения по умолчанию', () {
    test('создаётся с default-значениями', () {
      final settings = NotificationSettings(updatedAt: DateTime(2026, 5, 20));

      expect(settings.id, equals('default'));
      expect(settings.enabled, isTrue);
      expect(settings.reminderTime, equals('08:00'));
      expect(settings.motivationalEnabled, isFalse);
      expect(settings.motivationalTime, equals('12:00'));
      expect(settings.goalReminderEnabled, isFalse);
      expect(settings.goalReminderTime, equals('19:00'));
      expect(settings.quietHoursStart, isNull);
      expect(settings.quietHoursEnd, isNull);
      expect(settings.fcmToken, isNull);
    });

    test('можно задать кастомные значения', () {
      final settings = NotificationSettings(
        id: 'custom',
        enabled: false,
        reminderTime: '10:30',
        motivationalEnabled: true,
        motivationalTime: '14:00',
        goalReminderEnabled: true,
        goalReminderTime: '21:00',
        quietHoursStart: '23:00',
        quietHoursEnd: '06:00',
        fcmToken: 'abc123',
        updatedAt: DateTime(2026, 5, 20, 12, 0),
      );

      expect(settings.id, equals('custom'));
      expect(settings.enabled, isFalse);
      expect(settings.reminderTime, equals('10:30'));
      expect(settings.motivationalEnabled, isTrue);
      expect(settings.motivationalTime, equals('14:00'));
      expect(settings.goalReminderEnabled, isTrue);
      expect(settings.goalReminderTime, equals('21:00'));
      expect(settings.quietHoursStart, equals('23:00'));
      expect(settings.quietHoursEnd, equals('06:00'));
      expect(settings.fcmToken, equals('abc123'));
    });
  });

  group('🔄 fromMap / toMap — сериализация', () {
    test('toMap содержит все поля', () {
      final settings = NotificationSettings(
        enabled: true,
        reminderTime: '07:30',
        motivationalEnabled: true,
        motivationalTime: '13:00',
        goalReminderEnabled: false,
        goalReminderTime: '20:00',
        quietHoursStart: '22:00',
        quietHoursEnd: '07:00',
        fcmToken: 'token123',
        updatedAt: DateTime(2026, 5, 20, 10, 0, 0),
      );

      final map = settings.toMap();

      expect(map['id'], equals('default'));
      expect(map['enabled'], equals(1));
      expect(map['reminder_time'], equals('07:30'));
      expect(map['motivational_enabled'], equals(1));
      expect(map['motivational_time'], equals('13:00'));
      expect(map['goal_reminder_enabled'], equals(0));
      expect(map['goal_reminder_time'], equals('20:00'));
      expect(map['quiet_hours_start'], equals('22:00'));
      expect(map['quiet_hours_end'], equals('07:00'));
      expect(map['fcm_token'], equals('token123'));
      expect(map['updated_at'], equals('2026-05-20T10:00:00.000'));
    });

    test('fromMap восстанавливает объект из мапы', () {
      final map = <String, dynamic>{
        'id': 'default',
        'enabled': 1,
        'reminder_time': '09:00',
        'motivational_enabled': 1,
        'motivational_time': '15:30',
        'goal_reminder_enabled': 0,
        'goal_reminder_time': '18:45',
        'quiet_hours_start': '23:00',
        'quiet_hours_end': '06:00',
        'fcm_token': 'fcm_test',
        'updated_at': '2026-05-20T08:00:00.000',
      };

      final settings = NotificationSettings.fromMap(map);

      expect(settings.id, equals('default'));
      expect(settings.enabled, isTrue);
      expect(settings.reminderTime, equals('09:00'));
      expect(settings.motivationalEnabled, isTrue);
      expect(settings.motivationalTime, equals('15:30'));
      expect(settings.goalReminderEnabled, isFalse);
      expect(settings.goalReminderTime, equals('18:45'));
      expect(settings.quietHoursStart, equals('23:00'));
      expect(settings.quietHoursEnd, equals('06:00'));
      expect(settings.fcmToken, equals('fcm_test'));
      expect(settings.updatedAt, equals(DateTime(2026, 5, 20, 8, 0, 0)));
    });

    test('fromMap использует default-значения при отсутствии полей', () {
      final map = <String, dynamic>{
        'id': 'default',
        'updated_at': '2026-05-20T00:00:00.000',
      };

      final settings = NotificationSettings.fromMap(map);

      expect(settings.enabled, isTrue);
      expect(settings.reminderTime, equals('08:00'));
      expect(settings.motivationalEnabled, isFalse);
      expect(settings.motivationalTime, equals('12:00'));
      expect(settings.goalReminderEnabled, isFalse);
      expect(settings.goalReminderTime, equals('19:00'));
      expect(settings.quietHoursStart, isNull);
      expect(settings.quietHoursEnd, isNull);
      expect(settings.fcmToken, isNull);
    });

    test('Round-trip: toMap → fromMap даёт идентичный объект', () {
      final original = NotificationSettings(
        enabled: false,
        reminderTime: '06:00',
        motivationalEnabled: true,
        motivationalTime: '11:00',
        goalReminderEnabled: true,
        goalReminderTime: '22:00',
        quietHoursStart: '00:00',
        quietHoursEnd: '08:00',
        fcmToken: 'roundtrip',
        updatedAt: DateTime(2026, 5, 20, 1, 2, 3),
      );

      final map = original.toMap();
      final restored = NotificationSettings.fromMap(map);

      expect(restored.enabled, equals(original.enabled));
      expect(restored.reminderTime, equals(original.reminderTime));
      expect(restored.motivationalEnabled, equals(original.motivationalEnabled));
      expect(restored.motivationalTime, equals(original.motivationalTime));
      expect(restored.goalReminderEnabled, equals(original.goalReminderEnabled));
      expect(restored.goalReminderTime, equals(original.goalReminderTime));
      expect(restored.quietHoursStart, equals(original.quietHoursStart));
      expect(restored.quietHoursEnd, equals(original.quietHoursEnd));
      expect(restored.fcmToken, equals(original.fcmToken));
      expect(restored.updatedAt, equals(original.updatedAt));
    });
  });

  group('📝 copyWith', () {
    test('без параметров возвращает ту же копию', () {
      final settings = NotificationSettings(updatedAt: DateTime(2026, 5, 20));
      final copy = settings.copyWith();

      expect(copy.enabled, equals(settings.enabled));
      expect(copy.reminderTime, equals(settings.reminderTime));
      expect(copy.motivationalTime, equals(settings.motivationalTime));
      expect(copy.goalReminderTime, equals(settings.goalReminderTime));
    });

    test('изменяет только переданные поля', () {
      final settings = NotificationSettings(
        enabled: true,
        reminderTime: '08:00',
        motivationalTime: '12:00',
        goalReminderTime: '19:00',
        updatedAt: DateTime(2026, 5, 20),
      );

      final updated = settings.copyWith(
        motivationalTime: '14:00',
        goalReminderTime: '20:30',
      );

      expect(updated.enabled, isTrue); // не изменилось
      expect(updated.reminderTime, equals('08:00')); // не изменилось
      expect(updated.motivationalTime, equals('14:00')); // изменилось
      expect(updated.goalReminderTime, equals('20:30')); // изменилось
    });
  });

  group('🔇 isInQuietHours', () {
    test('возвращает false, если тихие часы не заданы', () {
      final settings = NotificationSettings(updatedAt: DateTime(2026, 5, 20));
      expect(settings.isInQuietHours(DateTime(2026, 5, 20, 15, 0)), isFalse);
    });

    test('возвращает true, если время внутри диапазона (обычный)', () {
      final settings = NotificationSettings(
        quietHoursStart: '22:00',
        quietHoursEnd: '07:00',
        updatedAt: DateTime(2026, 5, 20),
      );

      expect(settings.isInQuietHours(DateTime(2026, 5, 20, 23, 0)), isTrue);
      expect(settings.isInQuietHours(DateTime(2026, 5, 20, 3, 0)), isTrue);
      expect(settings.isInQuietHours(DateTime(2026, 5, 20, 22, 0)), isTrue);
      expect(settings.isInQuietHours(DateTime(2026, 5, 20, 7, 0)), isFalse);
      expect(settings.isInQuietHours(DateTime(2026, 5, 20, 15, 0)), isFalse);
    });

    test('возвращает true, если время внутри диапазона (в пределах дня)', () {
      final settings = NotificationSettings(
        quietHoursStart: '07:00',
        quietHoursEnd: '22:00',
        updatedAt: DateTime(2026, 5, 20),
      );

      expect(settings.isInQuietHours(DateTime(2026, 5, 20, 10, 0)), isTrue);
      expect(settings.isInQuietHours(DateTime(2026, 5, 20, 21, 59)), isTrue);
      expect(settings.isInQuietHours(DateTime(2026, 5, 20, 7, 0)), isTrue);
      expect(settings.isInQuietHours(DateTime(2026, 5, 20, 22, 0)), isFalse);
      expect(settings.isInQuietHours(DateTime(2026, 5, 20, 6, 59)), isFalse);
    });
  });

  group('🔤 toString', () {
    test('содержит все ключевые поля', () {
      final settings = NotificationSettings(
        enabled: true,
        reminderTime: '08:00',
        motivationalEnabled: true,
        motivationalTime: '12:00',
        goalReminderEnabled: false,
        goalReminderTime: '19:00',
        updatedAt: DateTime(2026, 5, 20),
      );

      final str = settings.toString();

      expect(str, contains('enabled: true'));
      expect(str, contains('reminderTime: 08:00'));
      expect(str, contains('motivational: true'));
      expect(str, contains('12:00'));
      expect(str, contains('goalReminder: false'));
      expect(str, contains('19:00'));
    });
  });

  group('🏷️ NotificationType', () {
    test('displayName возвращает русские названия', () {
      expect(NotificationType.dailyReminder.displayName,
          equals('Напоминание о практике'));
      expect(NotificationType.motivational.displayName,
          equals('Мотивационные сообщения'));
      expect(NotificationType.goalReminder.displayName,
          equals('Напоминание о целях'));
      expect(NotificationType.streakCelebration.displayName,
          equals('Поздравления с рекордами'));
    });

    test('description возвращает описания', () {
      expect(NotificationType.dailyReminder.description,
          contains('Ежедневное напоминание'));
      expect(NotificationType.motivational.description,
          contains('Вдохновляющие цитаты'));
      expect(NotificationType.goalReminder.description,
          contains('Напоминание вечером'));
    });

    test('все типы имеют иконку', () {
      for (final type in NotificationType.values) {
        expect(type.icon, isNotEmpty);
      }
    });
  });
}
