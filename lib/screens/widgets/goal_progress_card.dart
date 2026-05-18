import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';
import '../../data/meditation_goal.dart';

// =============================================================================
// GoalProgressCard — карточка прогресса одной цели
// =============================================================================
//
// Отображает:
//   - Название цели (type.displayName)
//   - Прогресс-бар (текущее / целевое значение)
//   - Текст "12 / 30 мин" или "3 / 5 сессий"
//   - Иконку выполнения (галочка) при достижении цели
//   - Бонус XP за выполнение
//
// Используется внутри GoalsPanel и GoalSettingsScreen.
// =============================================================================

/// Карточка прогресса одной цели.
class GoalProgressCard extends StatelessWidget {
  /// Прогресс цели (содержит саму цель + прогресс).
  final GoalWithProgress goalWithProgress;

  /// Показывать ли бонус XP.
  final bool showBonusXp;

  const GoalProgressCard({
    super.key,
    required this.goalWithProgress,
    this.showBonusXp = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = theme.extension<ZenStyles>() ?? ZenStyles.defaults;
    final goal = goalWithProgress.goal;
    final isCompleted = goalWithProgress.isCompleted;
    final progress = goalWithProgress.progress;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCompleted
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isCompleted
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Верхняя строка: название + бонус XP
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.type.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showBonusXp && !isCompleted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: zen.goldGradient.colors.first
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${goal.bonusXp} XP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: zen.goldGradient.colors.first,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isCompleted)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Прогресс-бар
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor:
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted
                      ? theme.colorScheme.primary
                      : zen.goldGradient.colors.first,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Нижняя строка: текущее / целевое значение
            Row(
              children: [
                Text(
                  _formatValue(goalWithProgress.currentValue, goal.type),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  ' / ${_formatTarget(goal.targetValue, goal.type)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Форматирует текущее значение с единицей измерения.
  String _formatValue(double value, GoalType type) {
    switch (type) {
      case GoalType.dailyMinutes:
      case GoalType.weeklyMinutes:
        return '${value.toInt()} мин';
      case GoalType.weeklySessions:
        return '${value.toInt()} сесс.';
      case GoalType.streakDays:
        return '${value.toInt()} дн.';
    }
  }

  /// Форматирует целевое значение с единицей измерения.
  String _formatTarget(double value, GoalType type) {
    switch (type) {
      case GoalType.dailyMinutes:
        return '${value.toInt()} мин';
      case GoalType.weeklyMinutes:
        return '${value.toInt()} мин';
      case GoalType.weeklySessions:
        return '${value.toInt()} сесс.';
      case GoalType.streakDays:
        return '${value.toInt()} дн.';
    }
  }
}
