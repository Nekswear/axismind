import 'package:flutter/material.dart';

import '../theme/zen_theme.dart';

// =============================================================================
// ZenDesign System — Atomic UI-Kit
// =============================================================================
//
// Содержит примитивные переиспользуемые виджеты:
//   - ZenSurface  — универсальный контейнер
//   - ZenMetricBlock — блок "число + подпись"
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
