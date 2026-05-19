import 'package:flutter/foundation.dart';

import 'database_provider.dart';
import 'notification_settings.dart';

/// Репозиторий для работы с настройками пуш-уведомлений.
///
/// Предоставляет CRUD-операции для [NotificationSettings]
/// и управление FCM токеном устройства.
class NotificationRepository {
  final DatabaseProvider _db;

  const NotificationRepository(this._db);

  /// Загружает настройки уведомлений из БД.
  ///
  /// Если записи нет — возвращает настройки по умолчанию.
  Future<NotificationSettings> getSettings() async {
    try {
      final row = await _db.getNotificationSettings();
      if (row != null) {
        return NotificationSettings.fromMap(row);
      }
      // Возвращаем настройки по умолчанию
      return NotificationSettings(
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Failed to load notification settings: $e');
      return NotificationSettings(
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Сохраняет настройки уведомлений.
  Future<void> saveSettings(NotificationSettings settings) async {
    try {
      await _db.saveNotificationSettings(settings.toMap());
      debugPrint(
        'Notification settings saved: enabled=${settings.enabled}, '
        'reminderTime=${settings.reminderTime}',
      );
    } catch (e) {
      debugPrint('Failed to save notification settings: $e');
      rethrow;
    }
  }

  /// Сохраняет FCM токен устройства.
  Future<void> saveFcmToken(String token) async {
    try {
      await _db.saveFcmToken(token);
      debugPrint('FCM token saved');
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// Возвращает сохранённый FCM токен (null если нет).
  Future<String?> getFcmToken() async {
    try {
      return await _db.getFcmToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Проверяет, нужно ли показывать уведомление сейчас
  /// (учитывая тихие часы).
  bool canShowNotification(NotificationSettings settings) {
    if (!settings.enabled) return false;
    if (settings.isInQuietHours(DateTime.now())) return false;
    return true;
  }
}
