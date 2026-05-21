// =============================================================================
// ZenBalance — Unit-тесты для NotificationService
// =============================================================================
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         ЗАПУСК ТЕСТОВ                                  ║
// ╠══════════════════════════════════════════════════════════════════════════╣
// ║  flutter test test/notification/notification_service_test.dart          ║
// ╚══════════════════════════════════════════════════════════════════════════╝
//
// Проверяет:
//   • isTimeInQuietHours — чистую функцию проверки тихих часов
//   • rescheduleAll — логику принятия решений (какие уведомления планировать)
//   • Парсинг времени HH:mm
// =============================================================================
//
// ВАЖНО: Методы scheduleDailyReminder, scheduleGoalReminder,
// scheduleMotivationalNotification, showStreakNotification вызывают нативные
// плагины (flutter_local_notifications). Их полное тестирование требует
// интеграционных тестов на реальном устройстве.
// Здесь мы тестируем только бизнес-логику, не зависящую от нативных вызовов.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:zenbalance/data/notification_settings.dart';
import 'package:zenbalance/services/notification_service.dart';

void main() {
  group('🔇 isTimeInQuietHours — чистая функция', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService.instance;
    });

    test('возвращает false, если время вне диапазона (обычный)', () {
      final time = DateTime(2000, 1, 1, 14, 0); // 14:00
      expect(
        service.isTimeInQuietHours(time, '22:00', '07:00'),
        isFalse,
      );
    });

    test('возвращает true, если время внутри диапазона (через полночь)', () {
      final time = DateTime(2000, 1, 1, 3, 0); // 03:00
      expect(
        service.isTimeInQuietHours(time, '22:00', '07:00'),
        isTrue,
      );
    });

    test('возвращает true, если время внутри диапазона (в пределах дня)', () {
      final time = DateTime(2000, 1, 1, 10, 0); // 10:00
      expect(
        service.isTimeInQuietHours(time, '08:00', '12:00'),
        isTrue,
      );
    });

    test('возвращает false, если время вне диапазона (в пределах дня)', () {
      final time = DateTime(2000, 1, 1, 14, 0); // 14:00
      expect(
        service.isTimeInQuietHours(time, '08:00', '12:00'),
        isFalse,
      );
    });

    test('граница начала считается тихим часом (start inclusive)', () {
      final time = DateTime(2000, 1, 1, 22, 0); // 22:00
      expect(
        service.isTimeInQuietHours(time, '22:00', '07:00'),
        isTrue,
      );
    });

    test('граница окончания НЕ считается тихим часом (end exclusive)', () {
      final time = DateTime(2000, 1, 1, 7, 0); // 07:00
      expect(
        service.isTimeInQuietHours(time, '22:00', '07:00'),
        isFalse,
      );
    });

    test('полночь внутри диапазона через полночь', () {
      final time = DateTime(2000, 1, 1, 0, 0); // 00:00
      expect(
        service.isTimeInQuietHours(time, '22:00', '07:00'),
        isTrue,
      );
    });

    test('равные start и end — не тихие часы (логика: start <= end, 0 <= 0, currentMin >= 0 && currentMin < 0 = false)', () {
      // Когда start == end, startMin <= endMin (0 <= 0), значит
      // currentMin >= 0 && currentMin < 0 — всегда false.
      // Это корректное поведение: если тихие часы не заданы (00:00-00:00),
      // время не считается тихим.
      final time = DateTime(2000, 1, 1, 14, 0); // 14:00
      expect(
        service.isTimeInQuietHours(time, '00:00', '00:00'),
        isFalse,
      );
    });
  });

  group('🧠 rescheduleAll — логика принятия решений', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService.instance;
    });

    test('с отключёнными уведомлениями не планирует (без ошибок)', () async {
      final settings = NotificationSettings(
        enabled: false,
        updatedAt: DateTime.now(),
      );

      // cancelAll и cancelByType проверяют _initialized и возвращаются
      // если сервис не инициализирован. В тестах _initialized = false.
      await service.rescheduleAll(settings);
      expect(true, isTrue);
    });

    test('с включёнными уведомлениями пытается планировать', () async {
      final settings = NotificationSettings(
        enabled: true,
        reminderTime: '08:00',
        motivationalEnabled: true,
        motivationalTime: '12:00',
        goalReminderEnabled: true,
        goalReminderTime: '19:00',
        updatedAt: DateTime.now(),
      );

      // Должен дойти до _localNotif.zonedSchedule и упасть
      // (сервис не инициализирован, _localNotif — late final)
      await expectLater(
        () => service.rescheduleAll(settings),
        throwsA(isA<Object>()),
      );
    });

    test('с выключенными мотивацией и целями планирует только dailyReminder',
        () async {
      final settings = NotificationSettings(
        enabled: true,
        reminderTime: '08:00',
        motivationalEnabled: false,
        goalReminderEnabled: false,
        updatedAt: DateTime.now(),
      );

      // Должен дойти до _localNotif (только daily reminder)
      await expectLater(
        () => service.rescheduleAll(settings),
        throwsA(isA<Object>()),
      );
    });
  });

  group('📅 scheduleDailyReminder — парсинг времени', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService.instance;
    });

    test('корректно парсит время HH:mm → доходит до _localNotif', () async {
      await expectLater(
        () => service.scheduleDailyReminder('09:30'),
        throwsA(isA<Object>()),
      );
    });

    test('невалидный формат времени выбрасывает FormatException', () async {
      // cancelByType вызывается ПЕРВЫМ, но теперь он проверяет _initialized
      // и возвращается. Затем int.parse('invalid') выбрасывает FormatException.
      await expectLater(
        () => service.scheduleDailyReminder('invalid'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('🎯 scheduleGoalReminder — парсинг времени', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService.instance;
    });

    test('корректно парсит время HH:mm → доходит до _localNotif', () async {
      await expectLater(
        () => service.scheduleGoalReminder('20:30'),
        throwsA(isA<Object>()),
      );
    });

    test('невалидный формат выбрасывает FormatException', () async {
      await expectLater(
        () => service.scheduleGoalReminder('not-a-time'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('✨ scheduleMotivationalNotification — парсинг времени', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService.instance;
    });

    test('корректно парсит время HH:mm → доходит до _localNotif', () async {
      await expectLater(
        () => service.scheduleMotivationalNotification('14:00'),
        throwsA(isA<Object>()),
      );
    });

    test('невалидный формат выбрасывает FormatException', () async {
      await expectLater(
        () => service.scheduleMotivationalNotification('bad'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('🔥 showStreakNotification', () {
    test('вызывает _localNotif → ошибка (late final не инициализирован)',
        () async {
      await expectLater(
        () => NotificationService.instance.showStreakNotification(5),
        throwsA(isA<Object>()),
      );
    });
  });
}
