import 'dart:math';

/// Статический калькулятор прогресса пользователя.
///
/// Содержит чистую доменную логику расчёта уровня, ранга,
/// серии (streak) и роста (growth) на основе данных практики.
/// Не имеет зависимостей от инфраструктурных слоёв (БД, UI).
class ProgressCalculator {
  ProgressCalculator._();

  /// Рассчитывает уровень на основе общего количества минут.
  ///
  /// Формула: floor(sqrt((minutes * 10) / 100)).
  /// Уровень растёт логарифмически с увеличением практики.
  static int calculateLevel(int minutes) {
    return sqrt((minutes * 10) / 100).floor();
  }

  /// Возвращает название ранга по уровню.
  ///
  /// Маппинг привязан к уровню (не к минутам), что обеспечивает
  /// единообразие с системой уровней:
  ///   0       → "Новичок осознанности"
  ///   1–2     → "Искатель спокойствия"
  ///   3–5     → "Хранитель тишины"
  ///   6–8     → "Мастер баланса"
  ///   9–11    → "Странник глубин"
  ///   12–14   → "Пробуждённый"
  ///   15–18   → "Мудрец"
  ///   19–23   → "Просветлённый"
  ///   24–29   → "Легенда"
  ///   30–37   → "Бессмертный"
  ///   38+     → "Божественный"
  static String getRank(int level) {
    if (level >= 38) return 'Божественный';
    if (level >= 30) return 'Бессмертный';
    if (level >= 24) return 'Легенда';
    if (level >= 19) return 'Просветлённый';
    if (level >= 15) return 'Мудрец';
    if (level >= 12) return 'Пробуждённый';
    if (level >= 9) return 'Странник глубин';
    if (level >= 6) return 'Мастер баланса';
    if (level >= 3) return 'Хранитель тишины';
    if (level >= 1) return 'Искатель спокойствия';
    return 'Новичок осознанности';
  }

  /// Рассчитывает текущую серию (streak) — количество дней подряд
  /// с медитацией, считая с последней даты.
  ///
  /// Алгоритм O(n):
  /// 1. Парсим все даты, нормализуем до DateTime(год, месяц, день).
  /// 2. Убираем дубликаты через Set.
  /// 3. Сортируем по возрастанию.
  /// 4. Идём с конца: пока разница между соседними днями == 1 → streak++.
  /// 5. Если последняя дата не сегодня и не вчера → streak = 0.
  ///
  /// [dateStrings] — список ISO-дат (например, "2026-05-08").
  /// Возвращает 0, если нет данных или серия прервана.
  static int calculateStreak(List<String> dateStrings) {
    if (dateStrings.isEmpty) return 0;

    // Нормализуем все даты до полуночи и убираем дубликаты
    final uniqueDates = dateStrings
        .map((s) => DateTime.tryParse(s.length >= 10 ? s.substring(0, 10) : s))
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    if (uniqueDates.isEmpty) return 0;

    // Сортируем по возрастанию
    final sorted = uniqueDates.toList()..sort();

    // Считаем streak с конца
    int streak = 1;
    for (int i = sorted.length - 1; i > 0; i--) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    // Проверяем, что streak не прерван: последняя дата должна быть сегодня или вчера
    // Используем toLocal() для явного указания, что работаем в локальном TZ
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final mostRecent = sorted.last;
    final daysSinceLast = today.difference(mostRecent).inDays;

    if (daysSinceLast > 1) return 0;

    return streak;
  }

  /// Рассчитывает относительный рост практики между двумя периодами.
  ///
  /// Возвращает double в диапазоне [-1.0, 10.0]:
  ///   - `null`, если нет данных для сравнения (оба периода пусты).
  ///   - `1.0`, если предыдущий период пуст, а текущий > 0 (резкий старт).
  ///   - `-1.0`, если текущий период пуст, а предыдущий > 0 (полный спад).
  ///   - иначе `(current - previous) / previous`, clamped в [-1.0, 10.0].
  ///
  /// [currentMinutes] — сумма минут за текущий период (например, последние 7 дней).
  /// [previousMinutes] — сумма минут за предыдущий период (например, предыдущие 7 дней).
  static double? calculateGrowth(int currentMinutes, int previousMinutes) {
    // Оба периода пусты — нет данных для расчёта
    if (previousMinutes <= 0 && currentMinutes <= 0) return null;

    // Предыдущий период пуст, но текущий > 0 — резкий старт
    if (previousMinutes <= 0) return 1.0;

    // Текущий период пуст, но предыдущий > 0 — полный спад
    if (currentMinutes <= 0) return -1.0;

    // Нормальный расчёт: (текущее - предыдущее) / предыдущее
    final growth = (currentMinutes - previousMinutes) / previousMinutes;
    return growth.clamp(-1.0, 10.0);
  }
}
