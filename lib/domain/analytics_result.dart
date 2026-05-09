/// Универсальный DTO для любого аналитического запроса.
///
/// [data] — полезная нагрузка (список дней, статистика, ошибка).
/// [timestamp] — момент получения данных (для проверки актуальности).
/// [isStale] — флаг устаревания (true, если данные старше N секунд).
class AnalyticsResult<T> {
  final T data;
  final DateTime timestamp;
  final bool isStale;

  const AnalyticsResult({
    required this.data,
    required this.timestamp,
    this.isStale = false,
  });

  /// Проверяет, не устарели ли данные относительно [maxAge].
  bool isFresh(Duration maxAge) =>
      DateTime.now().difference(timestamp) <= maxAge;
}
