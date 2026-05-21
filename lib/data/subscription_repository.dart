import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'database_provider.dart';
import 'subscription_status.dart';

/// Репозиторий для локального кэширования статуса подписки.
///
/// Позволяет приложению работать офлайн и не показывать paywall
/// при каждом запуске. Данные хранятся в SQLite в таблице `subscription`.
class SubscriptionRepository {
  final DatabaseProvider _db;

  SubscriptionRepository(this._db);

  static const String _tableName = 'subscription';

  /// Возвращает кэшированный статус подписки.
  /// Возвращает [SubscriptionStatus] с isActive=false, если записи нет.
  Future<SubscriptionStatus> getStatus() async {
    try {
      final result = await _db.db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: ['default'],
      );
      if (result.isNotEmpty) {
        return SubscriptionStatus.fromMap(result.first);
      }
    } catch (e) {
      debugPrint('Ошибка чтения статуса подписки: $e');
    }
    return SubscriptionStatus(updatedAt: DateTime(2000));
  }

  /// Сохраняет статус подписки (UPSERT).
  Future<void> saveStatus(SubscriptionStatus status) async {
    try {
      await _db.db.transaction((txn) async {
        await txn.insert(
          _tableName,
          status.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    } catch (e) {
      debugPrint('Ошибка сохранения статуса подписки: $e');
    }
  }

  /// Очищает статус подписки (при выходе или ошибке).
  Future<void> clearStatus() async {
    try {
      await _db.db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: ['default'],
      );
    } catch (e) {
      debugPrint('Ошибка очистки статуса подписки: $e');
    }
  }
}
