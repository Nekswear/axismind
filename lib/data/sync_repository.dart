import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import 'database_provider.dart';
import 'session.dart';

/// Offline-first репозиторий с синхронизацией между SQLite и Firestore.
///
/// ## Принцип работы
/// - **Запись**: сначала в локальный SQLite (мгновенно), затем в Firestore (фоном)
/// - **Чтение**: сначала из SQLite (быстро), затем фоновое обновление из Firestore
/// - **Миграция**: при первом входе все локальные данные загружаются в облако
///
/// ## Почему SQLite + Firestore, а не только Firestore?
/// - SQLite работает offline без ограничений
/// - Firestore имеет лимиты на чтение/запись (50k/20k в день на Spark плане)
/// - SQLite быстрее для локальных запросов (агрегации, фильтрация)
class SyncRepository {
  final DatabaseProvider _localDb;
  final FirebaseFirestore _firestore;
  final AuthService _auth;

  /// Флаг, предотвращающий race condition при параллельных вызовах
  /// [_syncSessionsFromCloud]. Если синхронизация уже выполняется,
  /// последующие вызовы будут проигнорированы.
  bool _syncInProgress = false;

  /// Флаг, предотвращающий повторную миграцию локальных данных в облако.
  ///
  /// Миграция должна выполняться только один раз после первого входа.
  /// Без этого флага migrateLocalToCloud будет вызываться при каждом
  /// входе, загружая все локальные данные в облако повторно.
  bool _migrationComplete = false;

  SyncRepository({
    required DatabaseProvider localDb,
    required AuthService auth,
    FirebaseFirestore? firestore,
  })  : _localDb = localDb,
        _auth = auth,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Коллекция сессий пользователя в Firestore.
  CollectionReference<Map<String, dynamic>> _sessionsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('sessions');
  }

  // =========================================================================
  // Запись (offline-first)
  // =========================================================================

  /// Сохранить сессию: сначала в SQLite, затем в Firestore.
  ///
  /// Если пользователь не авторизован — данные сохраняются только локально.
  /// При следующем входе они будут автоматически перенесены в облако
  /// через [migrateLocalToCloud].
  Future<void> saveSession(Session session) async {
    // 1. Всегда пишем в локальную БД (мгновенно, без ошибок сети)
    // Проставляем updatedAt, чтобы при синхронизации облачная версия
    // не перезаписала более новую локальную
    final sessionWithTimestamp = session.copyWithUpdatedAt();
    await _localDb.insertSession(sessionWithTimestamp);

    // 2. Если пользователь авторизован — синхронизируем с облаком
    final user = _auth.currentUser;
    if (user != null) {
      await _syncSessionToCloud(user.uid, sessionWithTimestamp);
    }
  }

  /// Обновить поля сессии (заметка, оценка, тег).
  Future<void> updateSessionFields(
    String sessionId, {
    String? note,
    int? moodRating,
    String? tag,
  }) async {
    // 1. Локально — обновляем поля и проставляем updatedAt
    final now = Session.iso8601Now();
    await _localDb.updateSessionFields(
      sessionId,
      note: note,
      moodRating: moodRating,
      tag: tag,
    );
    // Обновляем updatedAt отдельно, т.к. updateSessionFields не трогает его
    await _localDb.updateSessionUpdatedAt(sessionId, now);

    // 2. В облако (если авторизован)
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final updates = <String, dynamic>{};
        if (note != null) updates['note'] = note;
        if (moodRating != null) updates['mood_rating'] = moodRating;
        if (tag != null) updates['tag'] = tag;
        updates['updated_at'] = now;

        if (updates.isNotEmpty) {
          await _sessionsCollection(user.uid)
              .doc(sessionId)
              .update(updates);
        }
      } catch (e) {
        debugPrint('Firestore update failed (offline): $e');
      }
    }
  }

  /// Удалить сессию.
  Future<bool> deleteSession(String sessionId) async {
    // 1. Локально
    final deleted = await _localDb.deleteSession(sessionId);

    // 2. Из облака (если авторизован)
    final user = _auth.currentUser;
    if (user != null && deleted) {
      try {
        await _sessionsCollection(user.uid).doc(sessionId).delete();
      } catch (e) {
        debugPrint('Firestore delete failed (offline): $e');
      }
    }

    return deleted;
  }

  // =========================================================================
  // Чтение (локально + фоновое обновление)
  // =========================================================================

  /// Получить все сессии с пагинацией.
  ///
  /// Сначала возвращает данные из SQLite (мгновенно),
  /// затем фоново обновляет их из Firestore.
  Future<List<Session>> getAllSessions({int? limit, int? offset}) async {
    // 1. Сначала из локальной БД
    final localSessions = await _localDb.getAllSessions(
      limit: limit,
      offset: offset,
    );

    // 2. Фоново обновляем из облака (fire-and-forget)
    final user = _auth.currentUser;
    if (user != null) {
      unawaited(
        _syncSessionsFromCloud(user.uid).catchError((e) {
          debugPrint('Unhandled sync error: $e');
        }),
      );
    }

    return localSessions;
  }

  /// Получить сессии в диапазоне дат.
  Future<List<Session>> getSessionsInRange(String start, String end) async {
    final localSessions = await _localDb.getSessionsInRange(start, end);

    final user = _auth.currentUser;
    if (user != null) {
      unawaited(
        _syncSessionsFromCloud(user.uid).catchError((e) {
          debugPrint('Unhandled sync error: $e');
        }),
      );
    }

    return localSessions;
  }

  /// Получить отфильтрованные сессии.
  Future<List<Session>> getFilteredSessions({
    String? tag,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    return _localDb.getFilteredSessions(
      tag: tag,
      searchQuery: searchQuery,
      limit: limit,
      offset: offset,
    );
  }

  // =========================================================================
  // Агрегации (только локально — быстрее)
  // =========================================================================

  /// Суммарная длительность в секундах.
  Future<int> getTotalDurationSeconds() =>
      _localDb.getTotalDurationSeconds();

  /// Количество сессий.
  Future<int> getSessionCount() => _localDb.getSessionCount();

  /// Уникальные даты сессий (для streak).
  Future<List<String>> getDistinctSessionDates() =>
      _localDb.getDistinctSessionDates();

  /// Минуты по дням (для графиков).
  Future<List<Map<String, dynamic>>> getDailyMinutes(int days) =>
      _localDb.getDailyMinutes(days);

  /// Минуты по дням за период (для heatmap).
  Future<List<Map<String, dynamic>>> getDailyMinutesForPeriod(int days) =>
      _localDb.getDailyMinutesForPeriod(days);

  /// Уникальные теги.
  Future<List<String>> getDistinctTags() => _localDb.getDistinctTags();

  // =========================================================================
  // Синхронизация
  // =========================================================================

  /// Миграция всех локальных данных в облако.
  ///
  /// Вызывается один раз после первого входа пользователя.
  /// Загружает все существующие локальные сессии в Firestore.
  ///
  /// Защита от повторного вызова: флаг [_migrationComplete] предотвращает
  /// повторную загрузку данных при повторных входах.
  Future<void> migrateLocalToCloud(String userId) async {
    if (_migrationComplete) {
      debugPrint('Migration already completed, skipping');
      return;
    }

    try {
      final localSessions = await _localDb.getAllSessions();
      if (localSessions.isEmpty) {
        _migrationComplete = true;
        return;
      }

      final batch = _firestore.batch();
      final sessionsRef = _sessionsCollection(userId);

      for (final session in localSessions) {
        final docRef = sessionsRef.doc(session.id);
        batch.set(docRef, session.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
      _migrationComplete = true;
      debugPrint(
        'Migrated ${localSessions.length} sessions to cloud for user $userId',
      );
    } catch (e) {
      debugPrint('Migration to cloud failed: $e');
      // Не устанавливаем _migrationComplete = true, чтобы
      // при следующем входе попробовать снова
    }
  }

  /// Фоновая синхронизация из Firestore в локальную БД.
  ///
  /// Загружает все сессии пользователя из облака и сохраняет их локально.
  /// Вызывается автоматически при чтении данных.
  ///
  /// Защита от race condition: если синхронизация уже выполняется,
  /// повторный вызов игнорируется (флаг [_syncInProgress]).
  Future<void> _syncSessionsFromCloud(String userId) async {
    if (_syncInProgress) {
      debugPrint('Cloud sync already in progress, skipping duplicate call');
      return;
    }

    _syncInProgress = true;
    try {
      final cloudSnapshots = await _sessionsCollection(userId).get();

      for (final doc in cloudSnapshots.docs) {
        try {
          final data = doc.data();
          final session = Session.fromMap(data);
          // Используем insertSessionIfNewer вместо insertSession,
          // чтобы не перезаписать более новую локальную версию
          // (например, если пользователь удалил сессию во время синхронизации)
          await _localDb.insertSessionIfNewer(session);
        } catch (e) {
          debugPrint('Failed to process cloud document: $e');
          // Продолжаем со следующим документом
        }
      }
    } catch (e) {
      debugPrint('Cloud sync failed (offline): $e');
    } finally {
      _syncInProgress = false;
    }
  }

  /// Отправить одну сессию в облако.
  Future<void> _syncSessionToCloud(String userId, Session session) async {
    try {
      await _sessionsCollection(userId)
          .doc(session.id)
          .set(session.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore write failed (offline): $e');
    }
  }
}
