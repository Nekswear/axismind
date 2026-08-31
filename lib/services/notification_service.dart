import 'dart:convert';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/notification_settings.dart' as settings;
import 'app_service_locator.dart';

/// Глобальный обработчик фоновых FCM-сообщений (требуется Dart top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[FCM Background] Received: ${message.messageId} — '
    '${message.notification?.title}',
  );
  // Показываем уведомление через локальный плагин
  await NotificationService.instance._showLocalNotification(message);
}

/// Сервис пуш-уведомлений.
///
/// Синглтон, управляющий:
/// - Инициализацией FCM и получением токена
/// - Планированием локальных уведомлений (daily reminder, goal reminder)
/// - Показом мгновенных уведомлений (streak, motivational)
/// - Обработкой входящих FCM-сообщений (foreground + background)
/// - Навигацией при тапе на уведомление
class NotificationService {
  NotificationService._();

  /// Единственный экземпляр сервиса.
  static final NotificationService instance = NotificationService._();

  /// FCM messaging instance.
  /// Инициализируется в [init] — late для возможности тестирования без Firebase.
  late final FirebaseMessaging _fcm;

  /// Локальный плагин уведомлений.
  /// Инициализируется в [init] — late для возможности тестирования без плагина.
  late final FlutterLocalNotificationsPlugin _localNotif;

  /// Инициализация для тестов (без Firebase и нативных плагинов).
  ///
  /// Устанавливает заглушки для [_fcm] и [_localNotif], чтобы методы
  /// планирования можно было тестировать без реальных нативных вызовов.
  /// Вызывается в setUp() тестов.
  // visibleForTesting
  void initForTest() {
    _fcm = FirebaseMessaging.instance;
    _localNotif = FlutterLocalNotificationsPlugin();
  }

  /// Текущий FCM токен устройства.
  String? _deviceToken;

  /// FCM токен устройства.
  String? get deviceToken => _deviceToken;

  /// Был ли сервис инициализирован.
  bool _initialized = false;

  /// Callback для навигации при тапе на уведомление.
  /// Принимает тип уведомления и опциональный screen name.
  void Function(settings.NotificationType type, String? screen)? onNotificationTap;

  /// Инициализирует сервис уведомлений.
  ///
  /// Должен быть вызван один раз после Firebase.initializeApp().
  Future<void> init() async {
    if (_initialized) return;

    try {
      // 0. Инициализируем поля, зависящие от нативных плагинов
      _fcm = FirebaseMessaging.instance;
      _localNotif = FlutterLocalNotificationsPlugin();

      // 1. Инициализируем timezone database для zonedSchedule
      tz_data.initializeTimeZones();

      // 2. Инициализируем локальные уведомления
      await _initLocalNotifications();

      // 3. Запрашиваем разрешения
      await _requestPermissions();

      // 4. Получаем FCM токен
      await _getFcmToken();

      // 5. Настраиваем обработчики FCM
      await _setupFcmHandlers();

      _initialized = true;
      debugPrint('[NotificationService] Initialized successfully');
      if (_deviceToken != null) {
        debugPrint('[NotificationService] FCM token: $_deviceToken');
      }
    } catch (e) {
      debugPrint('[NotificationService] Initialization failed: $e');
    }
  }

  /// Инициализирует flutter_local_notifications с каналами Android.
  Future<void> _initLocalNotifications() async {
    // Настройки для Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Настройки для iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Настройки для всех платформ
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Создаём каналы уведомлений (Android)
    await _createNotificationChannels();
  }

  /// Создаёт каналы уведомлений для Android.
  Future<void> _createNotificationChannels() async {
    final androidPlatform = _localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlatform == null) return;

    final channels = [
      AndroidNotificationChannel(
        'axismind_reminders',
        'Напоминания',
        description: 'Ежедневные напоминания о медитации',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'axismind_motivation',
        'Мотивация',
        description: 'Мотивационные сообщения и цитаты',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'axismind_goals',
        'Цели',
        description: 'Уведомления о прогрессе целей',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'axismind_streak',
        'Серия',
        description: 'Поздравления с рекордами дней подряд',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    ];

    for (final channel in channels) {
      await androidPlatform.createNotificationChannel(channel);
    }
  }

  /// Запрашивает разрешения на уведомления.
  Future<void> _requestPermissions() async {
    // Android 13+ — разрешение POST_NOTIFICATIONS
    final androidPlugin = _localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    // iOS — разрешения от Apple
    final iosPlugin = _localNotif.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // FCM разрешения (iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  /// Получает FCM токен устройства.
  Future<void> _getFcmToken() async {
    try {
      _deviceToken = await _fcm.getToken();
      if (_deviceToken != null) {
        debugPrint('[FCM] Device token obtained');
      }
    } catch (e) {
      debugPrint('[FCM] Failed to get token: $e');
    }

    // Слушаем обновления токена
    _fcm.onTokenRefresh.listen((newToken) {
      _deviceToken = newToken;
      debugPrint('[FCM] Token refreshed: $newToken');
    });
  }

  /// Настраивает обработчики FCM сообщений.
  Future<void> _setupFcmHandlers() async {
    // 1. Фоновые сообщения (приложение закрыто или в фоне)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Сообщения в foreground (приложение активно)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '[FCM Foreground] Received: ${message.messageId} — '
        '${message.notification?.title}',
      );
      _showLocalNotification(message);
    });

    // 3. Пользователь тапнул по уведомлению (приложение было в фоне)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // 4. Проверяем, не открыто ли приложение с уведомления (cold start)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // Небольшая задержка, чтобы UI успел инициализироваться
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage);
      });
    }
  }

  /// Показывает локальное уведомление на основе FCM сообщения.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Определяем канал по типу уведомления
    final type = _parseNotificationType(message.data);
    final channelId = _channelIdForType(type);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _channelNameForType(type),
      channelDescription: _channelDescriptionForType(type),
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Сериализуем данные в payload для обработки тапа
    final payload = jsonEncode({
      'type': type.name,
      'screen': message.data['screen'] ?? 'home',
    });

    await _localNotif.show(
      notification.hashCode, // уникальный ID
      notification.title,
      notification.body,
      details,
      payload: payload,
    );
  }

  /// Планирует ежедневное уведомление-напоминание.
  ///
  /// [time] — время в формате HH:mm (например, "08:00").
  /// [quietHoursStart] и [quietHoursEnd] — если время напоминания попадает
  /// в тихие часы, уведомление не планируется.
  /// Отменяет предыдущее запланированное уведомление этого типа.
  Future<void> scheduleDailyReminder(
    String time, {
    String? quietHoursStart,
    String? quietHoursEnd,
  }) async {
    // Отменяем предыдущее
    await cancelByType(settings.NotificationType.dailyReminder);

    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Проверяем, не попадает ли время напоминания в тихие часы
    if (quietHoursStart != null && quietHoursEnd != null) {
      final reminderTime = DateTime(2000, 1, 1, hour, minute);
      if (isTimeInQuietHours(reminderTime, quietHoursStart, quietHoursEnd)) {
        debugPrint(
          '[NotificationService] Daily reminder time $time is within quiet hours '
          '($quietHoursStart–$quietHoursEnd), skipping',
        );
        return;
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'axismind_reminders',
      'Напоминания',
      channelDescription: 'Ежедневные напоминания о медитации',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode({
      'type': 'dailyReminder',
      'screen': 'home',
    });

    // Рассчитываем ближайшее время срабатывания в локальной timezone
    final now = DateTime.now();
    final location = tz.local;
    var scheduledDate = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      // Если время уже прошло сегодня — планируем на завтра
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Используем zonedSchedule для точного времени + ежедневного повторения
    await _localNotif.zonedSchedule(
      1001, // фиксированный ID для daily reminder
      '🧘 Пора медитировать!',
      'Выделите 10 минут для внутренней тишины и покоя.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );

    debugPrint(
      '[NotificationService] Daily reminder scheduled at $time '
      '(next: ${scheduledDate.hour.toString().padLeft(2, '0')}:'
      '${scheduledDate.minute.toString().padLeft(2, '0')})',
    );
  }

  /// Планирует напоминание о целях (вечером, если цель не выполнена).
  ///
  /// [time] — время в формате HH:mm (например, "19:00").
  /// [quietHoursStart] и [quietHoursEnd] — если время попадает
  /// в тихие часы, уведомление не планируется.
  Future<void> scheduleGoalReminder(
    String time, {
    String? quietHoursStart,
    String? quietHoursEnd,
  }) async {
    await cancelByType(settings.NotificationType.goalReminder);

    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Проверяем, не попадает ли время в тихие часы
    if (quietHoursStart != null && quietHoursEnd != null) {
      final reminderTime = DateTime(2000, 1, 1, hour, minute);
      if (isTimeInQuietHours(reminderTime, quietHoursStart, quietHoursEnd)) {
        debugPrint(
          '[NotificationService] Goal reminder time $time is within quiet hours '
          '($quietHoursStart–$quietHoursEnd), skipping',
        );
        return;
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'axismind_goals',
      'Цели',
      channelDescription: 'Уведомления о прогрессе целей',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode({
      'type': 'goalReminder',
      'screen': 'goals',
    });

    // Рассчитываем ближайшее время в локальной timezone
    final now = DateTime.now();
    final location = tz.local;
    var scheduledDate = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      // Если время уже прошло сегодня — планируем на завтра
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Используем zonedSchedule для точного времени + ежедневного повторения
    await _localNotif.zonedSchedule(
      1002, // фиксированный ID для goal reminder
      '🎯 Осталось время до выполнения цели!',
      'Всего несколько минут медитации — и вы получите бонусные XP!',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );

    debugPrint(
      '[NotificationService] Goal reminder scheduled daily at $time '
      '(next: ${scheduledDate.hour.toString().padLeft(2, '0')}:'
      '${scheduledDate.minute.toString().padLeft(2, '0')})',
    );
  }

  /// Показывает мгновенное уведомление о новом streak-рекорде.
  Future<void> showStreakNotification(int streak) async {
    final androidDetails = AndroidNotificationDetails(
      'axismind_streak',
      'Серия',
      channelDescription: 'Поздравления с рекордами дней подряд',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode({
      'type': 'streakCelebration',
      'screen': 'home',
    });

    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // уникальный ID
      '🔥 Новый рекорд: $streak дней подряд!',
      'Поздравляем! Вы побили свой личный рекорд!',
      details,
      payload: payload,
    );
  }

  /// Показывает мотивационное уведомление со случайной цитатой.
  ///
  /// Возвращает `true`, если уведомление было показано,
  /// `false` — если мотивационные уведомления отключены в настройках.
  Future<bool> showMotivationalNotification() async {
    // Проверяем, включены ли мотивационные уведомления
    try {
      final repo = AppServiceLocator.instance.notificationRepo;
      if (repo != null) {
        final s = await repo.getSettings();
        if (!s.motivationalEnabled) {
          debugPrint(
            '[NotificationService] Motivational notifications disabled, skipping',
          );
          return false;
        }
      }
    } catch (e) {
      debugPrint(
        '[NotificationService] Failed to check motivational settings: $e',
      );
    }

    final random = Random();
    final quote =
        _motivationalQuotes[random.nextInt(_motivationalQuotes.length)];

    final androidDetails = AndroidNotificationDetails(
      'axismind_motivation',
      'Мотивация',
      channelDescription: 'Мотивационные сообщения и цитаты',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode({
      'type': 'motivational',
      'screen': 'home',
    });

    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '✨ Ваш прогресс',
      quote,
      details,
      payload: payload,
    );

    debugPrint('[NotificationService] Motivational notification shown');
    return true;
  }

  /// Отменяет все запланированные уведомления.
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _localNotif.cancelAll();
    debugPrint('[NotificationService] All notifications cancelled');
  }

  /// Отменяет уведомления определённого типа по ID.
  Future<void> cancelByType(settings.NotificationType type) async {
    if (!_initialized) return;
    switch (type) {
      case settings.NotificationType.dailyReminder:
        await _localNotif.cancel(1001);
        break;
      case settings.NotificationType.goalReminder:
        await _localNotif.cancel(1002);
        break;
      case settings.NotificationType.motivational:
        await _localNotif.cancel(1003);
        break;
      case settings.NotificationType.streakCelebration:
        // Этот тип не планируется, а показывается мгновенно
        break;
    }
  }

  /// Перепланирует все активные уведомления на основе настроек.
  ///
  /// Вызывается после изменения настроек.
  /// Учитывает тихие часы — не планирует уведомления на время тишины.
  Future<void> rescheduleAll(settings.NotificationSettings s) async {
    // Сначала отменяем всё
    await cancelAll();

    if (!s.enabled) {
      debugPrint(
        '[NotificationService] Notifications disabled, skipping reschedule',
      );
      return;
    }

    // Планируем daily reminder (с проверкой тихих часов)
    await scheduleDailyReminder(
      s.reminderTime,
      quietHoursStart: s.quietHoursStart,
      quietHoursEnd: s.quietHoursEnd,
    );

    // Планируем goal reminder (если включено, с проверкой тихих часов)
    if (s.goalReminderEnabled) {
      await scheduleGoalReminder(
        s.goalReminderTime,
        quietHoursStart: s.quietHoursStart,
        quietHoursEnd: s.quietHoursEnd,
      );
    }

    // Планируем мотивационные уведомления (если включено)
    if (s.motivationalEnabled) {
      await scheduleMotivationalNotification(
        s.motivationalTime,
        quietHoursStart: s.quietHoursStart,
        quietHoursEnd: s.quietHoursEnd,
      );
    }

    debugPrint('[NotificationService] All notifications rescheduled');
  }

  /// Планирует мотивационное уведомление (один раз в день).
  ///
  /// [time] — время в формате HH:mm (например, "12:00").
  /// [quietHoursStart] и [quietHoursEnd] — если время попадает
  /// в тихие часы, уведомление не планируется.
  Future<void> scheduleMotivationalNotification(
    String time, {
    String? quietHoursStart,
    String? quietHoursEnd,
  }) async {
    await cancelByType(settings.NotificationType.motivational);

    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Проверяем, не попадает ли время в тихие часы
    if (quietHoursStart != null && quietHoursEnd != null) {
      final reminderTime = DateTime(2000, 1, 1, hour, minute);
      if (isTimeInQuietHours(reminderTime, quietHoursStart, quietHoursEnd)) {
        debugPrint(
          '[NotificationService] Motivational time $time is within quiet hours '
          '($quietHoursStart–$quietHoursEnd), skipping',
        );
        return;
      }
    }

    final random = Random();
    final quote =
        _motivationalQuotes[random.nextInt(_motivationalQuotes.length)];

    final androidDetails = AndroidNotificationDetails(
      'axismind_motivation',
      'Мотивация',
      channelDescription: 'Мотивационные сообщения и цитаты',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode({
      'type': 'motivational',
      'screen': 'home',
    });

    // Рассчитываем ближайшее время в локальной timezone
    final now = DateTime.now();
    final location = tz.local;
    var scheduledDate = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      // Если время уже прошло сегодня — планируем на завтра
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Используем zonedSchedule для точного времени + ежедневного повторения
    await _localNotif.zonedSchedule(
      1003, // фиксированный ID для motivational
      '✨ Ваш прогресс',
      quote,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );

    debugPrint(
      '[NotificationService] Motivational notification scheduled daily at $time '
      '(next: ${scheduledDate.hour.toString().padLeft(2, '0')}:'
      '${scheduledDate.minute.toString().padLeft(2, '0')})',
    );
  }

  /// Проверяет, попадает ли указанное время в интервал тихих часов.
  ///
  /// [time] — время для проверки (дата игнорируется).
  /// [start] и [end] — границы в формате HH:mm.
  /// Поддерживает диапазоны через полночь (например, 22:00–07:00).
  // visibleForTesting
  bool isTimeInQuietHours(DateTime time, String start, String end) {
    final partsStart = start.split(':');
    final partsEnd = end.split(':');
    final startMin =
        int.parse(partsStart[0]) * 60 + int.parse(partsStart[1]);
    final endMin = int.parse(partsEnd[0]) * 60 + int.parse(partsEnd[1]);
    final currentMin = time.hour * 60 + time.minute;

    if (startMin <= endMin) {
      // Обычный диапазон: например 07:00–22:00
      return currentMin >= startMin && currentMin < endMin;
    } else {
      // Через полночь: например 22:00–07:00
      return currentMin >= startMin || currentMin < endMin;
    }
  }

  // ===========================================================================
  // Private helpers
  // ===========================================================================

  /// Обрабатывает тап пользователя по уведомлению.
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final typeName = data['type'] as String? ?? 'dailyReminder';
      final screen = data['screen'] as String?;

      final type = settings.NotificationType.values.firstWhere(
        (t) => t.name == typeName,
        orElse: () => settings.NotificationType.dailyReminder,
      );

      onNotificationTap?.call(type, screen);
    } catch (e) {
      debugPrint(
        '[NotificationService] Failed to parse notification payload: $e',
      );
    }
  }

  /// Обрабатывает тап по FCM-уведомлению (из фона).
  void _handleNotificationTap(RemoteMessage message) {
    final type = _parseNotificationType(message.data);
    final screen = message.data['screen'] as String?;
    onNotificationTap?.call(type, screen);
  }

  /// Парсит тип уведомления из данных FCM сообщения.
  settings.NotificationType _parseNotificationType(
      Map<String, dynamic> data) {
    final typeStr = data['type'] as String? ?? 'dailyReminder';
    return settings.NotificationType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => settings.NotificationType.dailyReminder,
    );
  }

  /// Возвращает ID канала для типа уведомления.
  String _channelIdForType(settings.NotificationType type) {
    switch (type) {
      case settings.NotificationType.dailyReminder:
        return 'axismind_reminders';
      case settings.NotificationType.motivational:
        return 'axismind_motivation';
      case settings.NotificationType.goalReminder:
        return 'axismind_goals';
      case settings.NotificationType.streakCelebration:
        return 'axismind_streak';
    }
  }

  /// Возвращает название канала для типа уведомления.
  String _channelNameForType(settings.NotificationType type) {
    switch (type) {
      case settings.NotificationType.dailyReminder:
        return 'Напоминания';
      case settings.NotificationType.motivational:
        return 'Мотивация';
      case settings.NotificationType.goalReminder:
        return 'Цели';
      case settings.NotificationType.streakCelebration:
        return 'Серия';
    }
  }

  /// Возвращает описание канала для типа уведомления.
  String _channelDescriptionForType(settings.NotificationType type) {
    switch (type) {
      case settings.NotificationType.dailyReminder:
        return 'Ежедневные напоминания о медитации';
      case settings.NotificationType.motivational:
        return 'Мотивационные сообщения и цитаты';
      case settings.NotificationType.goalReminder:
        return 'Уведомления о прогрессе целей';
      case settings.NotificationType.streakCelebration:
        return 'Поздравления с рекордами дней подряд';
    }
  }

  /// Коллекция мотивационных цитат.
  static const List<String> _motivationalQuotes = [
    'Тишина — это не отсутствие звуков, а присутствие себя.',
    'Каждая минута медитации — это инвестиция в спокойствие.',
    'Дышите глубже — внутри вас целый океан покоя.',
    'Не пытайтесь остановить мысли. Научитесь не вовлекаться в них.',
    'Медитация — это не техника, а способ быть.',
    'Внутренний покой начинается с того момента, как вы решаете не позволять внешнему миру управлять вами.',
    'Осознанность — это ключ, который открывает дверь к гармонии.',
    'Ваша практика — это ваш остров. Никто не может отнять его у вас.',
    'Сделайте паузу. Вдохните. Вы уже на правильном пути.',
    'Каждый день — это новая возможность вернуться к себе.',
    'Сила не в напряжении, а в расслаблении.',
    'Медитация — это возвращение домой, в своё истинное Я.',
    'Не ждите идеального момента. Начните сейчас.',
    'Ваше дыхание — это якорь в настоящем моменте.',
    'Прогресс — это не прямая линия. Каждая минута практики имеет значение.',
  ];
}
