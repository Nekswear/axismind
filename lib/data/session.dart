import 'package:uuid/uuid.dart';

/// Immutable session model representing a single meditation session.
///
/// All fields are [final], ensuring the object is immutable after construction.
/// This prevents accidental mutation of session data throughout the app.
class Session {
  /// UUID v4 — universally unique identifier.
  ///
  /// Using UUID avoids ID conflicts during potential future sync scenarios
  /// (e.g., multi-device or cloud synchronization).
  final String id;

  /// ISO 8601 timestamp of when the session was recorded.
  final String timestamp;

  /// Duration of the session in seconds.
  final int seconds;

  /// Optional note for future use (migration-ready).
  final String? note;

  /// Настроение после медитации (1–5), где 1 — плохо, 5 — отлично.
  ///
  /// Заполняется в JournalDialog после завершения сессии.
  /// Может быть null, если пользователь пропустил оценку.
  final int? moodRating;

  /// Категория сессии (например, "Утро", "Вечер", "Стресс").
  ///
  /// Позволяет группировать и фильтровать записи в дневнике.
  final String? tag;

  /// ISO 8601 timestamp of the last update to this session.
  ///
  /// Используется для разрешения конфликтов при синхронизации:
  /// если облачная версия новее — она перезаписывает локальную, и наоборот.
  /// Если null — считается устаревшей (всегда перезаписывается).
  final String? updatedAt;

  static const _uuid = Uuid();

  /// Creates an immutable [Session].
  ///
  /// If [id] is not provided, a UUID v4 is auto-generated.
  /// If [timestamp] is not provided, the current UTC time in ISO 8601 is used.
  /// [updatedAt] по умолчанию равен [timestamp] (сессия только что создана).
  Session({
    String? id,
    String? timestamp,
    required this.seconds,
    this.note,
    this.moodRating,
    this.tag,
    String? updatedAt,
  }) : id = id ?? _uuid.v4(),
       timestamp = timestamp ?? iso8601Now(),
       updatedAt = updatedAt ?? timestamp ?? iso8601Now();

  /// Creates a [Session] from a database [Map].
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as String,
      timestamp: map['timestamp'] as String,
      seconds: map['seconds'] as int,
      note: map['note'] as String?,
      moodRating: map['mood_rating'] as int?,
      tag: map['tag'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// Converts this [Session] to a database-compatible [Map].
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'seconds': seconds,
      'note': note,
      'mood_rating': moodRating,
      'tag': tag,
      'updated_at': updatedAt,
    };
  }

  /// Returns a copy with optionally updated fields.
  Session copyWith({
    String? id,
    String? timestamp,
    int? seconds,
    String? note,
    int? moodRating,
    String? tag,
    String? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      seconds: seconds ?? this.seconds,
      note: note ?? this.note,
      moodRating: moodRating ?? this.moodRating,
      tag: tag ?? this.tag,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Создаёт копию сессии с обновлённым [updatedAt] (текущее время UTC).
  Session copyWithUpdatedAt() {
    return copyWith(updatedAt: Session.iso8601Now());
  }

  @override
  String toString() =>
      'Session(id: $id, timestamp: $timestamp, seconds: $seconds, '
      'moodRating: $moodRating, tag: $tag, updatedAt: $updatedAt)';

  /// Returns the current UTC time as an ISO 8601 string.
  static String iso8601Now() {
    final now = DateTime.now().toUtc();
    return '${now.year}-'
        '${_pad(now.month)}-'
        '${_pad(now.day)}T'
        '${_pad(now.hour)}:'
        '${_pad(now.minute)}:'
        '${_pad(now.second)}'
        '.${now.millisecond.toString().padLeft(3, '0')}Z';
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');
}
