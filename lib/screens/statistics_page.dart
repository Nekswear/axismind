import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/analytics_repository.dart';
import '../data/database_provider.dart';
import '../domain/analytics_result.dart';
import '../utils/time_utils.dart';
import '../widgets/empty_dashboard.dart';
import '../widgets/error_view.dart';
import '../widgets/shimmer_loading.dart';

/// Страница статистики с визуализацией прогресса медитации.
///
/// Компоненты:
/// - 4 состояния: ShimmerLoading → EmptyDashboard / ErrorView / ActiveDashboard
/// - Streak/Growth: мини-карточки над графиком
/// - XP-Bar: шкала опыта под уровнем пользователя
/// - Summary Cards: карточки с общими минутами и сессиями
/// - Heatmap: календарь активности за последние 30 дней
/// - Area Chart: график с градиентной заливкой за 7 дней
///
/// Типографика: GoogleFonts.roboto с адаптивным FontWeight.
/// Цвета: строго через Theme.of(context).colorScheme.
/// Отступы: Gap вместо SizedBox.
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

/// Состояния загрузки страницы статистики.
enum _PageState { loading, empty, error, active }

class _StatisticsPageState extends State<StatisticsPage> {
  AnalyticsRepository? _repository;
  _PageState _pageState = _PageState.loading;
  ExtendedStatisticsDTO? _data;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _pageState = _PageState.loading);

    try {
      final db = await DatabaseProvider.instance();
      _repository = AnalyticsRepository(db);

      // Сегодняшняя дата и 7 дней назад
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - 6);
      final range = DateRange(start: start, end: now);

      final result = await _repository!.fetchStatistics(range);

      if (!mounted) return;

      final dto = result.data;

      if (!dto.hasData) {
        setState(() {
          _data = dto;
          _pageState = _PageState.empty;
        });
      } else {
        setState(() {
          _data = dto;
          _pageState = _PageState.active;
        });
      }
    } catch (e) {
      if (!mounted) return;

      // StaleRequest — не показываем ошибку, просто ждём новый запрос
      if (e is StaleRequestException) return;

      setState(() {
        _errorMessage = ErrorView.formatError(
          e,
          fallback: 'Не удалось загрузить статистику. Попробуйте снова.',
        );
        _pageState = _PageState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _data != null
              ? '${_data!.progression.rank} · Ур. ${_data!.progression.level}'
              : 'Статистика',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_pageState) {
      case _PageState.loading:
        return const ShimmerLoading();

      case _PageState.empty:
        return const EmptyDashboard();

      case _PageState.error:
        return ErrorView(
          message: _errorMessage,
          onRetry: _loadStatistics,
        );

      case _PageState.active:
        final dto = _data!;
        return RefreshIndicator(
          onRefresh: _loadStatistics,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(8),

                // XP-Bar — шкала опыта под уровнем
                _buildXpBar(theme, dto),

                const Gap(24),

                // Summary cards
                _buildSummaryCards(theme, dto),

                const Gap(24),

                // Streak + Growth мини-карточки
                _buildStreakGrowthCards(theme, dto),

                const Gap(32),

                // Heatmap — календарь активности
                _buildHeatmapSection(theme, dto.heatmapData),

                const Gap(32),

                // Chart title
                Text(
                  'Последние 7 дней',
                  style: _adaptiveTextStyle(
                    theme: theme,
                    size: 18,
                    weight: FontWeight.w600,
                  ),
                ),
                const Gap(16),

                // Area Chart
                SizedBox(
                  height: 220,
                  child: _buildAreaChart(theme, dto.dailyStats),
                ),
                const Gap(24),

                // Average info
                Center(
                  child: Text(
                    'В среднем ${TimeUtils.formatMinutes(dto.dailyStats.isEmpty ? 0.0 : dto.dailyStats.fold<double>(0.0, (sum, d) => sum + d.minutes) / dto.dailyStats.length)} в день',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const Gap(40),
              ],
            ),
          ),
        );
    }
  }

  /// Возвращает адаптивный стиль текста с GoogleFonts.roboto.
  ///
  /// FontWeight зависит от MediaQuery.textScaleFactor:
  ///   - > 1.2 → w900
  ///   - > 1.0 → w800
  ///   - иначе → w700
  TextStyle _adaptiveTextStyle({
    required ThemeData theme,
    required double size,
    required FontWeight weight,
    Color? color,
  }) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final adaptiveWeight = textScale > 1.2
        ? FontWeight.w900
        : textScale > 1.0
            ? FontWeight.w800
            : weight;

    return GoogleFonts.roboto(
      fontSize: size,
      fontWeight: adaptiveWeight,
      color: color ?? theme.colorScheme.onSurface,
    );
  }

  /// XP-Bar: шкала опыта до следующего уровня.
  Widget _buildXpBar(ThemeData theme, ExtendedStatisticsDTO dto) {
    final xp = dto.xpProgress;
    final primaryColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Текст уровня
        Text(
          'Ур. ${dto.progression.level}',
          style: _adaptiveTextStyle(
            theme: theme,
            size: 20,
            weight: FontWeight.w600,
          ),
        ),
        const Gap(10),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: xp.progress,
            minHeight: 8,
            backgroundColor: primaryColor.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(
              primaryColor.withValues(alpha: 0.7),
            ),
          ),
        ),
        const Gap(6),

        // Микро-текст: остаток до следующего уровня
        Text(
          'До следующего уровня: ${xp.remainingMinutes} мин',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// Карточки Streak и Growth.
  Widget _buildStreakGrowthCards(ThemeData theme, ExtendedStatisticsDTO dto) {
    final primary = theme.colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: _MiniCard(
            theme: theme,
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.deepOrange,
            label: 'Серия дней',
            value: '${dto.streak}',
            unit: dto.streak == 1 ? 'день' : 'дней',
          ),
        ),
        const Gap(12),
        Expanded(
          child: _MiniCard(
            theme: theme,
            icon: dto.growth != null && dto.growth! >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            iconColor: dto.growth != null && dto.growth! >= 0
                ? Colors.green
                : theme.colorScheme.error,
            label: 'Рост за неделю',
            value: dto.growth != null
                ? '${(dto.growth! * 100).round()}%'
                : '—',
            unit: dto.growth != null
                ? dto.growth! >= 0
                    ? 'больше'
                    : 'меньше'
                : 'нет данных',
          ),
        ),
      ],
    );
  }

  /// Summary cards row.
  Widget _buildSummaryCards(ThemeData theme, ExtendedStatisticsDTO dto) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            theme: theme,
            label: 'Всего минут',
            value: TimeUtils.formatMinutes(dto.totalMinutes.toDouble()),
            icon: Icons.timer_outlined,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _SummaryCard(
            theme: theme,
            label: 'Сессий',
            value: '${dto.sessionCount}',
            icon: Icons.spa_outlined,
          ),
        ),
      ],
    );
  }

  /// Секция Heatmap — календарь активности за последние 30 дней.
  Widget _buildHeatmapSection(ThemeData theme, List<HeatmapDay> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final primaryColor = theme.colorScheme.primary;

    // Находим максимум минут для нормализации интенсивности
    final maxMinutes = data.fold<double>(
      0.0,
      (max, d) => d.minutes > max ? d.minutes : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Активность за 30 дней',
          style: _adaptiveTextStyle(
            theme: theme,
            size: 18,
            weight: FontWeight.w600,
          ),
        ),
        const Gap(12),

        // Легенда: дни недели
        Row(
          children: [
            const SizedBox(width: 28),
            ...List.generate(7, (i) {
              const dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
              return Expanded(
                child: Center(
                  child: Text(
                    dayLabels[i],
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const Gap(4),

        // Сетка heatmap
        ..._buildHeatmapGrid(theme, data, maxMinutes, primaryColor),

        const Gap(8),

        // Легенда интенсивности
        Row(
          children: [
            const Spacer(),
            _buildLegendChip(theme, 'Меньше', primaryColor.withValues(alpha: 0.1)),
            const Gap(4),
            _buildLegendChip(theme, '', primaryColor.withValues(alpha: 0.3)),
            const Gap(4),
            _buildLegendChip(theme, '', primaryColor.withValues(alpha: 0.55)),
            const Gap(4),
            _buildLegendChip(theme, '', primaryColor.withValues(alpha: 0.8)),
            const Gap(4),
            _buildLegendChip(theme, 'Больше', primaryColor),
            const Gap(4),
          ],
        ),
      ],
    );
  }

  /// Строит строки heatmap-сетки.
  List<Widget> _buildHeatmapGrid(
    ThemeData theme,
    List<HeatmapDay> data,
    double maxMinutes,
    Color primaryColor,
  ) {
    if (data.isEmpty) return [];

    final firstDate = DateTime.tryParse(data.first.date);
    if (firstDate == null) return [];

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

    return weeks.asMap().entries.map((entry) {
      final weekIndex = entry.key;
      final week = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                'Н${weekIndex + 1}',
                style: TextStyle(
                  fontSize: 9,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            ...week.map((day) {
              return Expanded(
                child: Center(
                  child: _buildHeatmapCell(day, maxMinutes, primaryColor),
                ),
              );
            }),
          ],
        ),
      );
    }).toList();
  }

  /// Ячейка heatmap.
  Widget _buildHeatmapCell(
    HeatmapDay? day,
    double maxMinutes,
    Color primaryColor,
  ) {
    if (day == null || day.minutes == 0) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }

    final intensity = maxMinutes > 0
        ? (day.minutes / maxMinutes).clamp(0.1, 1.0)
        : 0.1;

    return Tooltip(
      message: '${day.date}: ${TimeUtils.formatMinutes(day.minutes)}',
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: intensity * 0.85),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  /// Чип легенды heatmap.
  Widget _buildLegendChip(ThemeData theme, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (label.isNotEmpty) ...[
          const Gap(3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }

  /// Area Chart — график с градиентной заливкой под линией.
  Widget _buildAreaChart(ThemeData theme, List<DailyStats> stats) {
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    final primaryColor = theme.colorScheme.primary;

    final maxY = stats.fold<double>(
      0.0,
      (max, s) => s.minutes > max ? s.minutes : max,
    );
    final chartMaxY = (maxY < 5 ? 5.0 : maxY) * 1.2;

    final peakIndices = <int>{};
    if (maxY > 0) {
      for (int i = 0; i < stats.length; i++) {
        if (stats[i].minutes == maxY) {
          peakIndices.add(i);
        }
      }
    }

    final spots = stats.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.minutes);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
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
                    style: TextStyle(
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
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}

/// Мини-карточка для отображения streak/growth.
class _MiniCard extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _MiniCard({
    required this.theme,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Иконка
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const Gap(12),
          // Текст
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.roboto(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Gap(4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        unit,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка summary (всего минут / сессий).
class _SummaryCard extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
          const Gap(8),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Gap(2),
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
