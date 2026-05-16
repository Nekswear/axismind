import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';
import '../../core/widgets/zen_ui.dart';
import '../../data/analytics_repository.dart';
import '../../utils/time_utils.dart';
import 'dot_chart_painter.dart';

/// Combined activity overview: mini-calendar + dot chart + summary.
class HeatmapSection extends StatelessWidget {
  final List<HeatmapDay> data;
  final double maxMinutes;
  final double regularity;
  final double average;
  final HeatmapDay? bestDay;
  final int daysWithActivity;

  const HeatmapSection({
    super.key,
    required this.data,
    required this.maxMinutes,
    required this.regularity,
    required this.average,
    this.bestDay,
    required this.daysWithActivity,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;
    final primaryColor = theme.colorScheme.primary;

    return ZenSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Активность за 30 дней',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: zen.spacingUnit * 2),
          _buildMiniCalendar(theme, zen, data, maxMinutes, primaryColor),
          SizedBox(height: zen.spacingUnit * 2),
          _buildDotChart(theme, zen, data, primaryColor),
          SizedBox(height: zen.spacingUnit * 2),
          _buildActivitySummary(
            theme,
            zen,
            regularity: regularity,
            average: average,
            bestDay: bestDay,
            daysWithActivity: daysWithActivity,
            totalDays: data.length,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCalendar(
    ThemeData theme,
    ZenStyles zen,
    List<HeatmapDay> data,
    double maxMinutes,
    Color primaryColor,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    final firstDate = DateTime.tryParse(data.first.date);
    if (firstDate == null) return const SizedBox.shrink();

    final List<List<HeatmapDay?>> weeks = [];
    List<HeatmapDay?> currentWeek = [];

    final firstWeekday = firstDate.weekday;
    for (int i = 1; i < firstWeekday; i++) {
      currentWeek.add(null);
    }

    for (final day in data) {
      final date = DateTime.tryParse(day.date);
      if (date == null) continue;

      currentWeek.add(day);

      if (date.weekday == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }

    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(null);
      }
      weeks.add(currentWeek);
    }

    const dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const SizedBox(width: 40),
              ...dayLabels.map((label) {
                return Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        ...weeks.asMap().entries.map((entry) {
          final week = entry.value;
          final weekStartDate = week.firstWhere(
            (d) => d != null,
            orElse: () => null,
          );
          final weekLabel = weekStartDate != null
              ? TimeUtils.formatDateShort(weekStartDate.date)
              : '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    weekLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                ...week.map((day) {
                  return Expanded(
                    child: Center(
                      child: _buildCalendarCell(
                        theme, day, maxMinutes, primaryColor,
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCalendarCell(
    ThemeData theme,
    HeatmapDay? day,
    double maxMinutes,
    Color primaryColor,
  ) {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isToday = day != null && day.date == todayStr;

    if (day == null || day.minutes == 0) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isToday
                ? primaryColor.withValues(alpha: 0.5)
                : primaryColor.withValues(alpha: 0.08),
            width: isToday ? 2 : 1,
          ),
        ),
      );
    }

    final intensity = maxMinutes > 0
        ? (day.minutes / maxMinutes).clamp(0.15, 1.0)
        : 0.15;

    return Tooltip(
      message: '${day.date}: ${TimeUtils.formatMinutes(day.minutes)}',
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: intensity * 0.9),
          borderRadius: BorderRadius.circular(6),
          border: isToday
              ? Border.all(color: primaryColor, width: 2)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.minutes.toInt()}',
          style: TextStyle(
            fontSize: 9,
            color: intensity > 0.35
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDotChart(
    ThemeData theme,
    ZenStyles zen,
    List<HeatmapDay> data,
    Color primaryColor,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    final chartMaxMinutes = data.fold<double>(
      0.0,
      (max, d) => d.minutes > max ? d.minutes : max,
    );
    final chartMaxY = chartMaxMinutes < 5 ? 5.0 : chartMaxMinutes * 1.2;

    final total = data.fold<double>(0.0, (sum, d) => sum + d.minutes);
    final average = total / data.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Динамика',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(height: zen.spacingUnit),
        SizedBox(
          height: 60,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final stepX =
                  data.length > 1 ? width / (data.length - 1) : width;

              final points = <Offset>[];
              for (int i = 0; i < data.length; i++) {
                final x = i * stepX;
                final normalizedY =
                    chartMaxY > 0 ? (data[i].minutes / chartMaxY) : 0.0;
                final y = 56 - (normalizedY * 52).clamp(0.0, 52.0);
                points.add(Offset(x, y));
              }

              final avgY = chartMaxY > 0
                  ? 56 - ((average / chartMaxY) * 52).clamp(0.0, 52.0)
                  : 56.0;

              return CustomPaint(
                size: Size(width, 60),
                painter: DotChartPainter(
                  points: points,
                  averageY: avgY,
                  primaryColor: primaryColor,
                  surfaceColor: theme.colorScheme.surface,
                  onSurfaceColor: theme.colorScheme.onSurface,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySummary(
    ThemeData theme,
    ZenStyles zen, {
    required double regularity,
    required double average,
    required HeatmapDay? bestDay,
    required int daysWithActivity,
    required int totalDays,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryItem(
            theme: theme,
            icon: Icons.spa_outlined,
            iconColor: theme.colorScheme.primary,
            value: '${(regularity * 100).round()}%',
            label: 'регулярность',
          ),
        ),
        Expanded(
          child: _buildSummaryItem(
            theme: theme,
            icon: Icons.timer_outlined,
            iconColor: Colors.green,
            value: TimeUtils.formatMinutes(average),
            label: 'в среднем',
          ),
        ),
        Expanded(
          child: _buildSummaryItem(
            theme: theme,
            icon: Icons.emoji_events_outlined,
            iconColor: Colors.amber.shade700,
            value: bestDay != null
                ? TimeUtils.formatMinutes(bestDay.minutes)
                : '—',
            label: 'лучший',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor.withValues(alpha: 0.7)),
        SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
