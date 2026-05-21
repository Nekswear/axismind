import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../data/meditation_goal.dart';
import '../goal_settings_screen.dart';
import 'goal_progress_card.dart';

// =============================================================================
// GoalsPanel — панель целей для домашнего экрана
// =============================================================================
//
// Отображает список целей с прогрессом и кнопку настройки.
// Если целей нет — показывает заглушку с предложением создать первую цель.
//
// Используется в HomeScreen (мобильная версия) и WidescreenLayout (десктоп).
// =============================================================================

/// Панель целей для домашнего экрана.
class GoalsPanel extends StatelessWidget {
  /// Список целей с прогрессом.
  final List<GoalWithProgress> goalsProgress;

  /// Callback после изменения целей (для обновления данных).
  final VoidCallback? onGoalsChanged;

  const GoalsPanel({
    super.key,
    required this.goalsProgress,
    this.onGoalsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = theme.extension<ZenStyles>() ?? ZenStyles.defaults;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Заголовок секции
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.flag_rounded,
                color: zen.goldGradient.colors.first,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.goalsTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // Кнопка настройки целей
              TextButton.icon(
                onPressed: () => _openGoalSettings(context),
                icon: const Icon(Icons.settings_rounded, size: 16),
                label: Text(AppLocalizations.of(context)!.setup),
                style: TextButton.styleFrom(
                  foregroundColor: zen.goldGradient.colors.first,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Список целей или заглушка
        if (goalsProgress.isEmpty)
          _buildEmptyState(context, theme, zen)
        else
          ...goalsProgress.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GoalProgressCard(goalWithProgress: goal),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(
      BuildContext context, ThemeData theme, ZenStyles zen) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.flag_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.goalsNoGoals,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.goalsNoGoalsSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _openGoalSettings(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(AppLocalizations.of(context)!.goalsCreate),
              style: FilledButton.styleFrom(
                foregroundColor: zen.goldGradient.colors.first,
                backgroundColor:
                    zen.goldGradient.colors.first.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoalSettings(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const GoalSettingsScreen(),
      ),
    );

    if (result == true && context.mounted) {
      onGoalsChanged?.call();
    }
  }
}
