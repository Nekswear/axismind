import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/zen_theme.dart';
import '../../core/widgets/zen_ui.dart';
import '../../data/analytics_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/time_utils.dart';
import '../statistics_cubit.dart';

/// Chart section with period toggle and area chart.
class ChartSection extends StatelessWidget {
  final List<FlSpot> spots;
  final List<DailyStats> dailyStats;
  final double chartMaxY;
  final List<int> peakIndices;
  final double chartAverage;
  final ChartPeriod selectedPeriod;
  final ValueChanged<ChartPeriod> onPeriodChanged;

  const ChartSection({
    super.key,
    required this.spots,
    required this.dailyStats,
    required this.chartMaxY,
    required this.peakIndices,
    required this.chartAverage,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  int get _chartDays => switch (selectedPeriod) {
        ChartPeriod.days7 => 7,
        ChartPeriod.days14 => 14,
        ChartPeriod.days30 => 30,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;

    return ZenSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.statsLastDays(_chartDays.toString()),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              _buildPeriodToggle(context, theme, zen),
            ],
          ),
          SizedBox(height: zen.gap(2)),
          RepaintBoundary(
            child: SizedBox(
              height: 240,
              child: _buildAreaChart(context, theme, dailyStats),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle(BuildContext context, ThemeData theme, ZenStyles zen) {
    return ToggleButtons(
      isSelected: [
        selectedPeriod == ChartPeriod.days7,
        selectedPeriod == ChartPeriod.days14,
        selectedPeriod == ChartPeriod.days30,
      ],
      onPressed: (index) {
        onPeriodChanged(ChartPeriod.values[index]);
      },
      borderRadius: BorderRadius.circular(zen.cardRadius / 2),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 28),
      textStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
      selectedColor: theme.colorScheme.primary,
      fillColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      children: [
        Text(AppLocalizations.of(context)!.statsPeriod7),
        Text(AppLocalizations.of(context)!.statsPeriod14),
        Text(AppLocalizations.of(context)!.statsPeriod30),
      ],
    );
  }

  Widget _buildAreaChart(BuildContext context, ThemeData theme, List<DailyStats> stats) {
    if (stats.isEmpty || stats.length < 2) {
      return const SizedBox.shrink();
    }

    final primaryColor = theme.colorScheme.primary;

    return LineChart(
      LineChartData(
        clipData: FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMaxY > 10 ? 5 : 2,
          getDrawingHorizontalLine: (value) {
            if ((value - chartAverage).abs() < 0.5) {
              return FlLine(
                color: primaryColor.withValues(alpha: 0.3),
                strokeWidth: 1.5,
                dashArray: [6, 4],
              );
            }
            return FlLine(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= stats.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    stats[index].dayLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        minY: 0,
        maxY: chartMaxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                theme.colorScheme.onSurface.withValues(alpha: 0.85),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.spotIndex;
                final stat = stats[index];
                return LineTooltipItem(
                  '${stat.dayLabel}\n${TimeUtils.formatMinutes(stat.minutes)}',
                  TextStyle(
                    color: theme.colorScheme.surface,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.4,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: primaryColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                if (peakIndices.contains(index)) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: primaryColor,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.35),
                  primaryColor.withValues(alpha: 0.08),
                  primaryColor.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: chartAverage,
              color: primaryColor.withValues(alpha: 0.4),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                style: TextStyle(
                  color: primaryColor.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                labelResolver: (_) =>
                    AppLocalizations.of(context)!.statsAvgLabel(TimeUtils.formatMinutes(chartAverage)),
              ),
            ),
          ],
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}
