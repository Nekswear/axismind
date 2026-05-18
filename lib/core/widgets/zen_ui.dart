import 'package:flutter/material.dart';

import '../theme/zen_theme.dart';

// =============================================================================
// ZenDesign System — Atomic UI-Kit
// =============================================================================
//
// Содержит примитивные переиспользуемые виджеты:
//   - ZenSurface       — универсальный контейнер
//   - ZenMetricBlock   — блок "число + подпись"
//   - RankIcon         — иконка ранга по уровню
//   - DurationPreset   — карточка выбора длительности
//
// Все виджеты получают токены через ZenStyles, а не хардкод.
// =============================================================================

// ---------------------------------------------------------------------------
// ZenSurface
// ---------------------------------------------------------------------------

/// Универсальный контейнер с адаптивным padding и скруглением.
///
/// Использует [ZenStyles.cardRadius] и [ZenStyles.spacingUnit].
/// [padding] кратен spacingUnit (по умолчанию 8px).
class ZenSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? customRadius;
  final Color? color;

  const ZenSurface({
    super.key,
    required this.child,
    this.padding,
    this.customRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;

    return ClipRRect(
      borderRadius: BorderRadius.circular(customRadius ?? zen.cardRadius),
      child: Container(
        padding: padding ?? EdgeInsets.all(zen.spacingUnit * 2), // 16px
        color: color ?? Theme.of(context).colorScheme.surface,
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ZenMetricBlock
// ---------------------------------------------------------------------------

/// Блок "число сверху, подпись снизу".
///
/// Инкапсулирует логику отображения метрики:
/// - Число использует [ZenStyles.metricWeight] (FontWeight.w900).
/// - Подпись использует bodySmall из TextTheme.
/// - FittedBox защищает от переполнения.
/// - Если текст сжимается ниже 12px — показываем многоточие.
class ZenMetricBlock extends StatelessWidget {
  /// Отображаемое число (как строка, чтобы поддержать форматирование).
  final String value;

  /// Подпись под числом.
  final String label;

  /// Дополнительный стиль для числа (поверх токенов).
  final TextStyle? valueStyle;

  /// Дополнительный стиль для подписи.
  final TextStyle? labelStyle;

  const ZenMetricBlock({
    super.key,
    required this.value,
    required this.label,
    this.valueStyle,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Число — FittedBox для защиты от переполнения
        FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 0),
            child: Text(
              value,
              style: (valueStyle ?? theme.textTheme.displayLarge ?? const TextStyle())
                  .copyWith(
                fontWeight: zen.metricWeight,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        SizedBox(height: zen.spacingUnit), // 8px
        // Подпись
        Text(
          label,
          style: (labelStyle ?? theme.textTheme.bodySmall ?? const TextStyle())
              .copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// RankIcon
// ---------------------------------------------------------------------------

/// Иконка ранга, меняющаяся в зависимости от уровня пользователя.
///
/// Маппинг:
///   0       → 🌱 (Новичок осознанности)
///   1–2     → 🌿 (Искатель спокойствия)
///   3–5     → 🪷 (Хранитель тишины)
///   6–8     → 🌸 (Мастер баланса)
///   9–11    → 🕊️ (Странник глубин)
///   12–14   → ☀️ (Пробуждённый)
///   15–18   → 🏔️ (Мудрец)
///   19–23   → ✨ (Просветлённый)
///   24–29   → 🔥 (Легенда)
///   30–37   → ⚡ (Бессмертный)
///   38+     → 👑 (Божественный)
class RankIcon extends StatelessWidget {
  /// Текущий уровень пользователя.
  final int level;

  /// Размер иконки (по умолчанию 48).
  final double size;

  const RankIcon({super.key, required this.level, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final emoji = _emojiForLevel(level);
    return Text(
      emoji,
      style: TextStyle(fontSize: size),
    );
  }

  String _emojiForLevel(int level) {
    if (level >= 38) return '👑';
    if (level >= 30) return '⚡';
    if (level >= 24) return '🔥';
    if (level >= 19) return '✨';
    if (level >= 15) return '🏔️';
    if (level >= 12) return '☀️';
    if (level >= 9) return '🕊️';
    if (level >= 6) return '🌸';
    if (level >= 3) return '🪷';
    if (level >= 1) return '🌿';
    return '🌱';
  }
}

// ---------------------------------------------------------------------------
// DurationPreset
// ---------------------------------------------------------------------------

/// Карточка-пресет для выбора длительности медитации.
///
/// Отображает иконку, длительность, название и подпись.
/// В выбранном состоянии — обводка primary цветом и тень.
class DurationPreset extends StatelessWidget {
  /// Длительность в минутах.
  final int minutes;

  /// Иконка пресета.
  final IconData icon;

  /// Короткое название (например, "Быстрая").
  final String label;

  /// Подпись (например, "Перерыв").
  final String subtitle;

  /// Выбран ли данный пресет.
  final bool isSelected;

  /// Коллбэк при нажатии.
  final VoidCallback onTap;

  const DurationPreset({
    super.key,
    required this.minutes,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: zen.animationDuration,
        curve: zen.animationCurve,
        width: 80,
        padding: EdgeInsets.symmetric(
          vertical: zen.spacingUnit * 1.5,
          horizontal: zen.spacingUnit,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(zen.cardRadius / 2),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: zen.elevationLevels[2],
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: zen.elevationLevels[1],
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? primaryColor : Colors.grey[600]),
            SizedBox(height: zen.spacingUnit),
            Text(
              '$minutes мин',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? primaryColor : null,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? primaryColor : Colors.grey[600],
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
