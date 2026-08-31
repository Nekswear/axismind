import 'dart:math';

/// Все возможные ранги пользователя (геймификация).
///
/// Enum вместо строк — чтобы названия и описания рангов
/// локализовались в UI-слое через [Rank.title]/[Rank.description].
enum Rank {
  novice,
  seeker,
  guardian,
  master,
  wanderer,
  awakened,
  sage,
  enlightened,
  legend,
  immortal,
  divine,
}

/// Статический калькулятор прогресса пользователя.
///
/// Содержит чистую доменную логику расчёта уровня, ранга,
/// серии (streak) и роста (growth) на основе данных практики.
/// Не имеет зависимостей от инфраструктурных слоёв (БД, UI).
class ProgressCalculator {
  ProgressCalculator._();

  /// Все доступные тиры рангов в порядке возрастания.
  ///
  /// Используется для отображения Roadmap рангов в UI.
  /// Название и описание берутся из локализации по [Rank].
  static List<RankTier> get allTiers => [
        RankTier(
          minLevel: 0,
          maxLevel: 0,
          rank: Rank.novice,
          emoji: '🌱',
          minutesRequired: 0,
        ),
        RankTier(
          minLevel: 1,
          maxLevel: 2,
          rank: Rank.seeker,
          emoji: '🌿',
          minutesRequired: 10,
        ),
        RankTier(
          minLevel: 3,
          maxLevel: 5,
          rank: Rank.guardian,
          emoji: '🪷',
          minutesRequired: 90,
        ),
        RankTier(
          minLevel: 6,
          maxLevel: 8,
          rank: Rank.master,
          emoji: '🌸',
          minutesRequired: 360,
        ),
        RankTier(
          minLevel: 9,
          maxLevel: 11,
          rank: Rank.wanderer,
          emoji: '🕊️',
          minutesRequired: 810,
        ),
        RankTier(
          minLevel: 12,
          maxLevel: 14,
          rank: Rank.awakened,
          emoji: '☀️',
          minutesRequired: 1440,
        ),
        RankTier(
          minLevel: 15,
          maxLevel: 18,
          rank: Rank.sage,
          emoji: '🏔️',
          minutesRequired: 2250,
        ),
        RankTier(
          minLevel: 19,
          maxLevel: 23,
          rank: Rank.enlightened,
          emoji: '✨',
          minutesRequired: 3610,
        ),
        RankTier(
          minLevel: 24,
          maxLevel: 29,
          rank: Rank.legend,
          emoji: '🔥',
          minutesRequired: 5760,
        ),
        RankTier(
          minLevel: 30,
          maxLevel: 37,
          rank: Rank.immortal,
          emoji: '⚡',
          minutesRequired: 9000,
        ),
        RankTier(
          minLevel: 38,
          maxLevel: null,
          rank: Rank.divine,
          emoji: '👑',
          minutesRequired: 14440,
        ),
      ];

  /// Рассчитывает уровень на основе общего количества минут.
  ///
  /// Формула: floor(sqrt((minutes * 10) / 100)).
  /// Уровень растёт логарифмически с увеличением практики.
  static int calculateLevel(int minutes) {
    return sqrt((minutes * 10) / 100).floor();
  }

  /// Возвращает ранг по уровню.
  ///
  /// Маппинг привязан к уровню (не к минутам), что обеспечивает
  /// единообразие с системой уровней:
  ///   0       → [Rank.novice]
  ///   1–2     → [Rank.seeker]
  ///   3–5     → [Rank.guardian]
  ///   6–8     → [Rank.master]
  ///   9–11    → [Rank.wanderer]
  ///   12–14   → [Rank.awakened]
  ///   15–18   → [Rank.sage]
  ///   19–23   → [Rank.enlightened]
  ///   24–29   → [Rank.legend]
  ///   30–37   → [Rank.immortal]
  ///   38+     → [Rank.divine]
  static Rank getRank(int level) {
    if (level >= 38) return Rank.divine;
    if (level >= 30) return Rank.immortal;
    if (level >= 24) return Rank.legend;
    if (level >= 19) return Rank.enlightened;
    if (level >= 15) return Rank.sage;
    if (level >= 12) return Rank.awakened;
    if (level >= 9) return Rank.wanderer;
    if (level >= 6) return Rank.master;
    if (level >= 3) return Rank.guardian;
    if (level >= 1) return Rank.seeker;
    return Rank.novice;
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

// =============================================================================
// RankTier — модель тира ранга для Roadmap
// =============================================================================

/// Модель одного тира (уровня/ранга) в Roadmap прогресса.
///
/// Содержит информацию о диапазоне уровней, ранге (для локализации),
/// эмодзи и количестве минут, необходимых для достижения.
class RankTier {
  /// Минимальный уровень для этого тира (включительно).
  final int minLevel;

  /// Максимальный уровень для этого тира (включительно).
  /// `null` означает, что верхней границы нет (например, "Божественный").
  final int? maxLevel;

  /// Ранг тира — используется для получения локализованного названия
  /// и описания через [Rank.title]/[Rank.description].
  final Rank rank;

  /// Эмодзи-иконка ранга.
  final String emoji;

  /// Примерное количество минут медитации для достижения этого тира.
  final int minutesRequired;

  const RankTier({
    required this.minLevel,
    this.maxLevel,
    required this.rank,
    required this.emoji,
    required this.minutesRequired,
  });
}
