import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';
import '../../core/widgets/zen_ui.dart';
import '../../utils/time_utils.dart';

/// Summary cards row — total minutes and session count.
class SummaryCards extends StatelessWidget {
  final int totalMinutes;
  final int sessionCount;

  const SummaryCards({
    super.key,
    required this.totalMinutes,
    required this.sessionCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;

    return ZenSurface(
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              theme: theme,
              zen: zen,
              label: 'Всего минут',
              value: TimeUtils.formatMinutes(totalMinutes.toDouble()),
              icon: Icons.timer_outlined,
            ),
          ),
          SizedBox(width: zen.spacingUnit * 1.5),
          Expanded(
            child: _SummaryCard(
              theme: theme,
              zen: zen,
              label: 'Сессий',
              value: '$sessionCount',
              icon: Icons.spa_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ThemeData theme;
  final ZenStyles zen;
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.theme,
    required this.zen,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
        SizedBox(height: zen.spacingUnit),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: zen.metricWeight,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: zen.spacingUnit / 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// Streak and Growth mini-cards.
class StreakGrowthCards extends StatelessWidget {
  final int streak;
  final double? growth;
  final int chartDays;

  const StreakGrowthCards({
    super.key,
    required this.streak,
    this.growth,
    required this.chartDays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;

    return ZenSurface(
      child: Row(
        children: [
          Expanded(
            child: _MiniCard(
              theme: theme,
              zen: zen,
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.deepOrange,
              label: 'Серия',
              subtitle: null,
              value: '$streak',
              unit: streak == 1 ? 'день' : 'дней',
            ),
          ),
          SizedBox(width: zen.spacingUnit * 1.5),
          Expanded(
            child: _MiniCard(
              theme: theme,
              zen: zen,
              icon: growth != null
                  ? (growth! >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded)
                  : Icons.remove_rounded,
              iconColor: growth != null
                  ? (growth! >= 0 ? Colors.green : theme.colorScheme.error)
                  : Colors.grey,
              label: 'Рост',
              subtitle: 'за $chartDays д.',
              value: growth != null ? '${(growth! * 100).round()}%' : '—',
              unit: '',
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final ThemeData theme;
  final ZenStyles zen;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final String value;
  final String unit;

  const _MiniCard({
    required this.theme,
    required this.zen,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(zen.spacingUnit * 1.5),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        SizedBox(width: zen.spacingUnit * 1.5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              SizedBox(height: zen.spacingUnit / 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: zen.metricWeight,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    SizedBox(width: zen.spacingUnit / 2),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text(
                        unit,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
