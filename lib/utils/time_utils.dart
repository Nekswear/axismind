/// Utility class for time formatting operations.
///
/// Centralizes all time-formatting logic to avoid duplication across the app.
/// Example: 125 seconds -> "2:05"
class TimeUtils {
  TimeUtils._();

  /// Formats [totalSeconds] into a "M:SS" or "MM:SS" string.
  ///
  /// Examples:
  /// - `formatSeconds(0)` → `"0:00"`
  /// - `formatSeconds(125)` → `"2:05"`
  /// - `formatSeconds(3661)` → `"61:01"`
  static String formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats [totalSeconds] into a human-readable localized string.
  ///
  /// Examples:
  /// - `formatReadable(0)` → `"0 мин"`
  /// - `formatReadable(125)` → `"2 мин 5 сек"`
  /// - `formatReadable(3600)` → `"60 мин"`
  static String formatReadable(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    if (minutes == 0) return '$seconds сек';
    if (seconds == 0) return '$minutes мин';
    return '$minutes мин $seconds сек';
  }

  /// Formats [totalMinutes] as a double into a short display string.
  ///
  /// Examples:
  /// - `formatMinutes(0.0)` → `"0 мин"`
  /// - `formatMinutes(5.5)` → `"5.5 мин"`
  /// - `formatMinutes(60.0)` → `"60 мин"`
  static String formatMinutes(double totalMinutes) {
    if (totalMinutes == totalMinutes.roundToDouble()) {
      return '${totalMinutes.round()} мин';
    }
    return '${totalMinutes.toStringAsFixed(1)} мин';
  }

  /// Converts seconds to minutes as a double, rounded to 1 decimal.
  ///
  /// Пример: 125 секунд → 2.1 (а не 2.0, как было с roundToDouble)
  static double secondsToMinutes(int seconds) {
    return (seconds / 60.0 * 10).roundToDouble() / 10;
  }

  /// Formats an ISO 8601 date string (e.g., "2026-05-08T...") to "dd.MM".
  ///
  /// Used for chart axis labels.
  static String formatDateShort(String isoDate) {
    // Extract just the date part
    final datePart = isoDate.length >= 10 ? isoDate.substring(0, 10) : isoDate;
    final parts = datePart.split('-');
    if (parts.length >= 3) {
      return '${parts[2]}.${parts[1]}';
    }
    return datePart;
  }

  /// Formats an ISO 8601 date string to a readable day name (short).
  ///
  /// Examples: "2026-05-08" → "Пт", "2026-05-09" → "Сб"
  static String formatDayShort(String isoDate) {
    final datePart = isoDate.length >= 10 ? isoDate.substring(0, 10) : isoDate;
    final parts = datePart.split('-');
    if (parts.length < 3) return datePart;

    final date = DateTime.tryParse(datePart);
    if (date == null) return datePart;

    // Russian short day names
    const days = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
    return days[date.weekday % 7];
  }
}
