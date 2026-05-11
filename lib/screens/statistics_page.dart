import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../core/theme/zen_theme.dart';
import '../core/widgets/zen_ui.dart';
import '../data/analytics_repository.dart';
import '../data/database_provider.dart';
import '../utils/time_utils.dart';
import '../widgets/empty_dashboard.dart';
import '../widgets/error_view.dart';
import '../widgets/shimmer_loading.dart';

/// Страница статистики с визуализацией прогресса медитации.
///
/// Компоненты:
/// - 4 состояния: ShimmerLoading → EmptyDashboard / ErrorView / ActiveDashboard
/// - Hero-секция: градиентная карточка с RankIcon, XP-Bar, Streak
/// - Summary Cards: карточки с общими минутами и сессиями
/// - Streak/Growth: мини-карточки над графиком
/// - Heatmap: календарь активности за последние 30 дней
/// - Area Chart: график с градиентной заливкой за 7 дней
/// - Average Metric: блок среднего времени в день
///
/// Типографика: через Theme.of(context).textTheme.
/// Цвета: строго через Theme.of(context).colorScheme.
/// Отступы: через ZenStyles.spacingUnit.
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

/// Состояния загрузки страницы статистики.
enum _PageState { loading, empty, error, active }

class _StatisticsPageState extends State<StatisticsPage>
    with TickerProviderStateMixin {
  AnalyticsRepository? _repository;
  _PageState _pageState = _PageState.loading;
  ExtendedStatisticsDTO? _data;
  String _errorMessage = '';

  /// Контроллеры для staggered-анимации появления блоков.
  late final List<AnimationController> _animControllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _initAnimations();
  }

  void _initAnimations() {
    _animControllers = List.generate(6, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
    });
    _fadeAnimations = _animControllers.map((c) {
      return CurvedAnimation(parent: c, curve: Curves.easeOut);
    }).toList();
    _slideAnimations = _animControllers.map((c) {
      return Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic));
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _animControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Запускает staggered-анимацию появления блоков.
  void _startStaggeredAnimation() {
    for (int i = 0; i < _animControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 80 * i), () {
        if (mounted) _animControllers[i].forward();
      });
    }
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
        _startStaggeredAnimation();
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
    final zen = theme.extension<ZenStyles>() ?? ZenStyles.defaults;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Статистика',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: _buildBody(theme, zen),
    );
  }

  Widget _buildBody(ThemeData theme, ZenStyles zen) {
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
            padding: EdgeInsets.symmetric(horizontal: zen.spacingUnit * 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: zen.spacingUnit),

                // 1. Hero-секция: градиент + RankIcon + XP-Bar + Streak
                _AnimatedSection(
                  animation: _fadeAnimations[0],
                  slideAnimation: _slideAnimations[0],
                  child: _buildHeroSection(theme, zen, dto),
                ),

                SizedBox(height: zen.gap(3)),

                // 2. Summary cards
                _AnimatedSection(
                  animation: _fadeAnimations[1],
                  slideAnimation: _slideAnimations[1],
                  child: _buildSummaryCards(theme, zen, dto),
                ),

                SizedBox(height: zen.gap(3)),

                // 3. Streak + Growth мини-карточки
                _AnimatedSection(
                  animation: _fadeAnimations[2],
                  slideAnimation: _slideAnimations[2],
                  child: _buildStreakGrowthCards(theme, zen, dto),
                ),

                SizedBox(height: zen.gap(4)),

                // 4. Heatmap — календарь активности
                _AnimatedSection(
                  animation: _fadeAnimations[3],
                  slideAnimation: _slideAnimations[3],
                  child: _buildHeatmapSection(theme, zen, dto.heatmapData),
                ),

                SizedBox(height: zen.gap(4)),

                // 5. Area Chart
                _AnimatedSection(
                  animation: _fadeAnimations[4],
                  slideAnimation: _slideAnimations[4],
                  child: _buildChartSection(theme, zen, dto),
                ),

                SizedBox(height: zen.gap(3)),

                // 6. Average metric
                _AnimatedSection(
                  animation: _fadeAnimations[5],
                  slideAnimation: _slideAnimations[5],
                  child: _buildAverageMetric(theme, zen, dto),
                ),

                SizedBox(height: zen.gap(5)),
              ],
            ),
          ),
        );
    }
  }

  // ===========================================================================
  // Hero-секция
  // ===========================================================================

  /// Hero-секция с градиентом, рангом, XP bar и streak.
  Widget _buildHeroSection(
    ThemeData theme,
    ZenStyles zen,
    ExtendedStatisticsDTO dto,
  ) {
    final progression = dto.progression;
    final xp = dto.xpProgress;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: zen.focusGradient,
        borderRadius: BorderRadius.circular(zen.cardRadius),
      ),
      padding: EdgeInsets.all(zen.spacingUnit * 3),
      child: Column(
        children: [
          // Ранг + иконка
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RankIcon(level: progression.level, size: 48),
              SizedBox(width: zen.spacingUnit * 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progression.rank,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Уровень ${progression.level}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: zen.gap(3)),

          // XP Progress Bar (анимированный)
          _buildHeroXpBar(theme, zen, xp),

          SizedBox(height: zen.gap(2)),

          // Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.orange[300],
                size: 24,
              ),
              SizedBox(width: zen.spacingUnit),
              Text(
                '${dto.streak} дней подряд',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// XP Progress Bar с анимированным заполнением (на градиентном фоне).
  Widget _buildHeroXpBar(ThemeData theme, ZenStyles zen, XpProgress xp) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: xp.progress),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.9),
                ),
              );
            },
          ),
        ),
        SizedBox(height: zen.spacingUnit),
        Text(
          'Осталось ${xp.remainingMinutes} мин до следующего уровня',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Summary Cards
  // ===========================================================================

  /// Summary cards row, обёрнутая в ZenSurface.
  Widget _buildSummaryCards(
    ThemeData theme,
    ZenStyles zen,
    ExtendedStatisticsDTO dto,
  ) {
    return ZenSurface(
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              theme: theme,
              zen: zen,
              label: 'Всего минут',
              value: TimeUtils.formatMinutes(dto.totalMinutes.toDouble()),
              icon: Icons.timer_outlined,
            ),
          ),
          SizedBox(width: zen.spacingUnit * 1.5),
          Expanded(
            child: _SummaryCard(
              theme: theme,
              zen: zen,
              label: 'Сессий',
              value: '${dto.sessionCount}',
              icon: Icons.spa_outlined,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Streak + Growth mini-cards
  // ===========================================================================

  /// Карточки Streak и Growth, обёрнутые в ZenSurface.
  Widget _buildStreakGrowthCards(
    ThemeData theme,
    ZenStyles zen,
    ExtendedStatisticsDTO dto,
  ) {
    return ZenSurface(
      child: Row(
        children: [
          Expanded(
            child: _MiniCard(
              theme: theme,
              zen: zen,
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.deepOrange,
              label: 'Серия дней',
              value: '${dto.streak}',
              unit: dto.streak == 1 ? 'день' : 'дней',
            ),
          ),
          SizedBox(width: zen.spacingUnit * 1.5),
          Expanded(
            child: _MiniCard(
              theme: theme,
              zen: zen,
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
      ),
    );
  }

  // ===========================================================================
  // Heatmap
  // ===========================================================================

  /// Секция Heatmap — календарь активности за последние 30 дней.
  Widget _buildHeatmapSection(
    ThemeData theme,
    ZenStyles zen,
    List<HeatmapDay> data,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    final primaryColor = theme.colorScheme.primary;

    // Находим максимум минут для нормализации интенсивности
    final maxMinutes = data.fold<double>(
      0.0,
      (max, d) => d.minutes > max ? d.minutes : max,
    );

    return ZenSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок секции
          Text(
            'Активность за 30 дней',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: zen.spacingUnit * 2),

          // Сетка heatmap
          ..._buildHeatmapGrid(theme, data, maxMinutes, primaryColor),

          SizedBox(height: zen.spacingUnit),

          // Легенда интенсивности
          Row(
            children: [
              const Spacer(),
              _buildLegendChip(theme, 'Меньше', primaryColor.withValues(alpha: 0.1)),
              const SizedBox(width: 4),
              _buildLegendChip(theme, '', primaryColor.withValues(alpha: 0.3)),
              const SizedBox(width: 4),
              _buildLegendChip(theme, '', primaryColor.withValues(alpha: 0.55)),
              const SizedBox(width: 4),
              _buildLegendChip(theme, '', primaryColor.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              _buildLegendChip(theme, 'Больше', primaryColor),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
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

    // Подписи дней недели
    const dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return [
      // Шапка с днями недели
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            const SizedBox(width: 32),
            ...dayLabels.map((label) {
              return Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),

      // Строки heatmap
      ...weeks.asMap().entries.map((entry) {
        final week = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: week.map((day) {
              return Expanded(
                child: Center(
                  child: _buildHeatmapCell(day, maxMinutes, primaryColor),
                ),
              );
            }).toList(),
          ),
        );
      }),
    ];
  }

  /// Ячейка heatmap (увеличенная до 24×24).
  Widget _buildHeatmapCell(
    HeatmapDay? day,
    double maxMinutes,
    Color primaryColor,
  ) {
    if (day == null || day.minutes == 0) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final intensity = maxMinutes > 0
        ? (day.minutes / maxMinutes).clamp(0.1, 1.0)
        : 0.1;

    return Tooltip(
      message: '${day.date}: ${TimeUtils.formatMinutes(day.minutes)}',
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: intensity * 0.85),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.minutes.toInt()}',
          style: TextStyle(
            fontSize: 8,
            color: intensity > 0.5
                ? Colors.white
                : primaryColor.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // Chart Section
  // ===========================================================================

  /// Секция с графиком и заголовком.
  Widget _buildChartSection(
    ThemeData theme,
    ZenStyles zen,
    ExtendedStatisticsDTO dto,
  ) {
    return ZenSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            'Последние 7 дней',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: zen.gap(2)),

          // Area Chart
          SizedBox(
            height: 240,
            child: _buildAreaChart(theme, dto.dailyStats),
          ),
        ],
      ),
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
    final chartMaxY = (maxY < 5 ? 5.0 : maxY) * 1.3;

    // Среднее значение
    final average = stats.fold<double>(0.0, (sum, s) => sum + s.minutes) /
        stats.length;

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
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMaxY > 10 ? 5 : 2,
          getDrawingHorizontalLine: (value) {
            // Reference line для среднего значения
            if ((value - average).abs() < 0.5) {
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
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: chartMaxY > 10 ? 5 : 2,
              getTitlesWidget: (value, meta) {
                if (value == meta.min) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${value.toInt()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                );
              },
            ),
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
        // Подпись reference line
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: average,
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
                    'сред. ${TimeUtils.formatMinutes(average)}',
              ),
            ),
          ],
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  // ===========================================================================
  // Average Metric
  // ===========================================================================

  /// Блок "В среднем X в день" в виде ZenMetricBlock.
  Widget _buildAverageMetric(
    ThemeData theme,
    ZenStyles zen,
    ExtendedStatisticsDTO dto,
  ) {
    final average = dto.dailyStats.isEmpty
        ? 0.0
        : dto.dailyStats.fold<double>(0.0, (sum, d) => sum + d.minutes) /
            dto.dailyStats.length;

    return Center(
      child: ZenMetricBlock(
        value: TimeUtils.formatMinutes(average),
        label: 'в среднем в день',
        valueStyle: theme.textTheme.headlineLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// =============================================================================
// Анимированная секция
// =============================================================================

/// Оборачивает дочерний виджет в staggered-анимацию появления.
class _AnimatedSection extends StatelessWidget {
  final Animation<double> animation;
  final Animation<Offset> slideAnimation;
  final Widget child;

  const _AnimatedSection({
    required this.animation,
    required this.slideAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}

// =============================================================================
// Мини-карточка
// =============================================================================

/// Мини-карточка для отображения streak/growth.
class _MiniCard extends StatelessWidget {
  final ThemeData theme;
  final ZenStyles zen;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _MiniCard({
    required this.theme,
    required this.zen,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Иконка
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
        // Текст
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(height: zen.spacingUnit / 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: zen.metricWeight,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Summary Card
// =============================================================================

/// Карточка summary (всего минут / сессий).
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
