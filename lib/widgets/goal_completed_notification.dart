import 'package:flutter/material.dart';

import '../core/theme/zen_theme.dart';
import '../data/meditation_goal.dart';

// =============================================================================
// GoalCompletedNotification — уведомление о выполнении цели
// =============================================================================
//
// Показывается после завершения сессии, если была выполнена хотя бы одна цель.
// Отображает список выполненных целей с бонусными XP.
//
// Используется в TimerPage._saveSession после processSessionEnd.
// =============================================================================

/// Уведомление о выполнении целей после сессии.
class GoalCompletedNotification extends StatelessWidget {
  /// Список выполненных целей.
  final List<GoalWithProgress> completedGoals;

  const GoalCompletedNotification({
    super.key,
    required this.completedGoals,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = theme.extension<ZenStyles>() ?? ZenStyles.defaults;

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Иконка
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: zen.goldGradient,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),

          // Заголовок
          Text(
            'Цель выполнена!',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: zen.goldGradient.colors.first,
            ),
          ),
          const SizedBox(height: 12),

          // Список выполненных целей
          ...completedGoals.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal.goal.type.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: zen.goldGradient.colors.first
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${goal.goal.bonusXp} XP',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: zen.goldGradient.colors.first,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 16),

          // Кнопка
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Отлично!'),
          ),
        ],
      ),
    );
  }
}
