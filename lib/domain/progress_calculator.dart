import 'dart:math';

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
  static List<RankTier> get allTiers => [
        RankTier(
          minLevel: 0,
          maxLevel: 0,
          title: 'Новичок осознанности',
          emoji: '🌱',
          description: 'Первый шаг на пути к осознанности',
          minutesRequired: 0,
        ),
        RankTier(
          minLevel: 1,
          maxLevel: 2,
          title: 'Искатель спокойствия',
          emoji: '🌿',
          description: 'Поиск внутренней гармонии',
          minutesRequired: 10,
        ),
        RankTier(
          minLevel: 3,
          maxLevel: 5,
          title: 'Хранитель тишины',
          emoji: '🪷',
          description: 'Умение находить тишину внутри',
          minutesRequired: 90,
        ),
        RankTier(
          minLevel: 6,
          maxLevel: 8,
          title: 'Мастер баланса',
          emoji: '🌸',
          description: 'Баланс между усилием и покоем',
          minutesRequired: 360,
        ),
        RankTier(
          minLevel: 9,
          maxLevel: 11,
          title: 'Странник глубин',
          emoji: '🕊️',
          description: 'Исследование глубин сознания',
          minutesRequired: 810,
        ),
        RankTier(
          minLevel: 12,
          maxLevel: 14,
          title: 'Пробуждённый',
          emoji: '☀️',
          description: 'Пробуждение внутреннего света',
          minutesRequired: 1440,
        ),
        RankTier(
          minLevel: 15,
          maxLevel: 18,
          title: 'Мудрец',
          emoji: '🏔️',
          description: 'Мудрость, рождённая практикой',
          minutesRequired: 2250,
        ),
        RankTier(
          minLevel: 19,
          maxLevel: 23,
          title: 'Просветлённый',
          emoji: '✨',
          description: 'Свет осознанности ведёт вас',
          minutesRequired: 3610,
        ),
        RankTier(
          minLevel: 24,
          maxLevel: 29,
          title: 'Легенда',
          emoji: '🔥',
          description: 'Ваш путь вдохновляет других',
          minutesRequired: 5760,
        ),
        RankTier(
          minLevel: 30,
          maxLevel: 37,
          title: 'Бессмертный',
          emoji: '⚡',
          description: 'Вневременная практика',
          minutesRequired: 9000,
        ),
        RankTier(
          minLevel: 38,
          maxLevel: null,
          title: 'Божественный',
          emoji: '👑',
          description: 'Вы достигли просветления',
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

// =============================================================================
// RankTier — модель тира ранга для Roadmap
// =============================================================================

/// Модель одного тира (уровня/ранга) в Roadmap прогресса.
///
/// Содержит информацию о диапазоне уровней, названии, эмодзи,
/// описании и количестве минут, необходимых для достижения.
class RankTier {
  /// Минимальный уровень для этого тира (включительно).
  final int minLevel;

  /// Максимальный уровень для этого тира (включительно).
  /// `null` означает, что верхней границы нет (например, "Божественный").
  final int? maxLevel;

  /// Название ранга (например, "Новичок осознанности").
  final String title;

  /// Эмодзи-иконка ранга.
  final String emoji;

  /// Короткое описание тира.
  final String description;

  /// Примерное количество минут медитации для достижения этого тира.
  final int minutesRequired;

  const RankTier({
    required this.minLevel,
    this.maxLevel,
    required this.title,
    required this.emoji,
    required this.description,
    required this.minutesRequired,
  });

  /// Возвращает строку с диапазоном уровней (например, "1–2 ур." или "38+ ур.").
  String get levelRange {
    if (maxLevel == null) return '$minLevel+ ур.';
    if (minLevel == maxLevel) return '$minLevel ур.';
    return '$minLevel–$maxLevel ур.';
  }

  /// Форматирует минуты в читаемый вид (например, "1 440+ мин").
  String get minutesFormatted {
    final n = minutesRequired;
    if (n >= 1000) {
      final thousands = (n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1);
      return '$thousands тыс. мин';
    }
    return '$n мин';
  }
}
