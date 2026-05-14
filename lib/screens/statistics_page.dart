import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../core/theme/zen_theme.dart';
import '../core/widgets/zen_ui.dart';
import '../data/analytics_repository.dart';
import '../data/database_provider.dart';
import '../data/sync_repository.dart';
import '../services/auth_service.dart';
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

/// Период отображения графика.
enum _ChartPeriod { days7, days14, days30 }

class _StatisticsPageState extends State<StatisticsPage>
    with TickerProviderStateMixin {
  AnalyticsRepository? _repository;
  _PageState _pageState = _PageState.loading;
  ExtendedStatisticsDTO? _data;
  String _errorMessage = '';
  _ChartPeriod _selectedPeriod = _ChartPeriod.days7;

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

  int get _chartDays => switch (_selectedPeriod) {
        _ChartPeriod.days7 => 7,
        _ChartPeriod.days14 => 14,
        _ChartPeriod.days30 => 30,
      };

  /// Полная загрузка всей статистики (init, pull-to-refresh, retry).
  /// Показывает ShimmerLoading и сбрасывает скролл.
  Future<void> _loadStatistics() async {
    setState(() => _pageState = _PageState.loading);

    try {
      final db = await DatabaseProvider.instance();
      final auth = AuthService();
      final syncRepo = SyncRepository(localDb: db, auth: auth);
      _repository = AnalyticsRepository(syncRepo);

      final now = DateTime.now();
      final days = _chartDays;
      final start = DateTime(now.year, now.month, now.day - (days - 1));
      final range = DateRange(start: start, end: now);

      final result = await _repository!.fetchStatistics(
        range,
        chartDays: days,
      );

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

  /// Лёгкое обновление только данных графика при смене периода.
  /// Не сбрасывает _pageState и не трогает скролл.
  Future<void> _reloadChartData() async {
    if (_repository == null) return;

    try {
      final now = DateTime.now();
      final days = _chartDays;
      final start = DateTime(now.year, now.month, now.day - (days - 1));
      final range = DateRange(start: start, end: now);

      final result = await _repository!.fetchStatistics(
        range,
        chartDays: days,
      );

      if (!mounted) return;

      final dto = result.data;

      setState(() {
        _data = dto;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is StaleRequestException) return;
      debugPrint('Ошибка обновления графика: $e');
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
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progression.rank,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Уровень ${progression.level}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
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
              label: 'Рост за $_chartDays дней',
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
  // Activity Overview — комбинированный блок: мини-календарь + точечный график
  // ===========================================================================

  /// Комбинированная секция «Активность за 30 дней».
  ///
  /// Содержит:
  ///   1. Мини-календарь — компактная сетка 5×6 с цветовыми ячейками
  ///      и подписями дат слева.
  ///   2. Точечный график (dot chart) — динамика минут за 30 дней.
  ///   3. Сводка: серия дней, среднее, лучший день.
  Widget _buildHeatmapSection(
    ThemeData theme,
    ZenStyles zen,
    List<HeatmapDay> data,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    // Находим максимум минут для нормализации интенсивности
    final maxMinutes = data.fold<double>(
      0.0,
      (max, d) => d.minutes > max ? d.minutes : max,
    );

    // Рассчитываем статистику
    final totalMinutes = data.fold<double>(0.0, (sum, d) => sum + d.minutes);
    final average = data.isEmpty ? 0.0 : totalMinutes / data.length;
    final bestDay = data.fold<HeatmapDay?>(null, (best, d) {
      if (best == null || d.minutes > best.minutes) return d;
      return best;
    });
    final daysWithActivity = data.where((d) => d.minutes > 0).length;
    final regularity = data.isEmpty
        ? 0.0
        : daysWithActivity / data.length;

    return ZenSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок секции
          Text(
            'Активность за 30 дней',
            style: theme.textTheme.titleMedium?.copyWith(
              color: onSurface,
            ),
          ),
          SizedBox(height: zen.spacingUnit * 2),

          // 1. Мини-календарь
          _buildMiniCalendar(theme, zen, data, maxMinutes, primaryColor),

          SizedBox(height: zen.spacingUnit * 2),

          // 2. Точечный график
          _buildDotChart(theme, zen, data, primaryColor),

          SizedBox(height: zen.spacingUnit * 2),

          // 3. Сводка
          _buildActivitySummary(
            theme, zen,
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

  /// Мини-календарь — компактная сетка 5×6 (или 6×5) с цветовыми ячейками.
  ///
  /// Слева — подписи с датами начала недели (например, «12.04», «19.04»).
  /// Ячейки окрашены по интенсивности медитации.
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

    // Группируем данные по неделям
    final List<List<HeatmapDay?>> weeks = [];
    List<HeatmapDay?> currentWeek = [];

    // Добавляем пустые ячейки до первого дня недели
    final firstWeekday = firstDate.weekday; // 1=Пн ... 7=Вс
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

    // Дополняем последнюю неделю
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(null);
      }
      weeks.add(currentWeek);
    }

    // Подписи дней недели (сокращённые)
    const dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Шапка с днями недели
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const SizedBox(width: 40), // место для подписи даты
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

        // Строки календаря
        ...weeks.asMap().entries.map((entry) {
          final week = entry.value;

          // Дата начала недели (первый не-null день в неделе)
          final weekStartDate = week.firstWhere(
            (d) => d != null,
            orElse: () => null,
          );
          final weekLabel = weekStartDate != null
              ? _formatShortDate(weekStartDate.date)
              : '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                // Подпись даты слева
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
                // Ячейки недели
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

  /// Форматирует ISO-дату в короткий формат «ДД.ММ».
  String _formatShortDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  /// Ячейка мини-календаря (28×28).
  Widget _buildCalendarCell(
    ThemeData theme,
    HeatmapDay? day,
    double maxMinutes,
    Color primaryColor,
  ) {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
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
              ? Border.all(
                  color: primaryColor,
                  width: 2,
                )
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

  /// Точечный график (dot chart) — динамика минут за 30 дней.
  ///
  /// Каждая точка — один день. Точки соединены линией.
  /// Высота графика — 60px, компактно помещается под календарём.
  Widget _buildDotChart(
    ThemeData theme,
    ZenStyles zen,
    List<HeatmapDay> data,
    Color primaryColor,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxMinutes = data.fold<double>(
      0.0,
      (max, d) => d.minutes > max ? d.minutes : max,
    );
    final chartMaxY = maxMinutes < 5 ? 5.0 : maxMinutes * 1.2;

    // Среднее значение для reference line
    final total = data.fold<double>(0.0, (sum, d) => sum + d.minutes);
    final average = total / data.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Подпись графика
        Text(
          'Динамика',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(height: zen.spacingUnit),
        // Контейнер графика
        SizedBox(
          height: 60,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final stepX = data.length > 1
                  ? width / (data.length - 1)
                  : width;

              // Нормализуем значения по высоте
              final points = <Offset>[];
              for (int i = 0; i < data.length; i++) {
                final x = i * stepX;
                final normalizedY = chartMaxY > 0
                    ? (data[i].minutes / chartMaxY)
                    : 0.0;
                // Инвертируем Y (0 внизу, max вверху) + отступ 4px
                final y = 56 - (normalizedY * 52).clamp(0.0, 52.0);
                points.add(Offset(x, y));
              }

              // Y позиция средней линии
              final avgY = chartMaxY > 0
                  ? 56 - ((average / chartMaxY) * 52).clamp(0.0, 52.0)
                  : 56.0;

              return CustomPaint(
                size: Size(width, 60),
                painter: _DotChartPainter(
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

  /// Сводка активности — серия дней, регулярность, среднее, лучший день.
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
        // Регулярность
        Expanded(
          child: _buildSummaryItem(
            theme: theme,
            icon: Icons.spa_outlined,
            iconColor: theme.colorScheme.primary,
            value: '${(regularity * 100).round()}%',
            label: 'регулярность',
          ),
        ),
        // Среднее
        Expanded(
          child: _buildSummaryItem(
            theme: theme,
            icon: Icons.timer_outlined,
            iconColor: Colors.green,
            value: TimeUtils.formatMinutes(average),
            label: 'в среднем',
          ),
        ),
        // Лучший день
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

  /// Элемент сводки: иконка + значение + подпись.
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
          // Заголовок + переключатель периода
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Последние $_chartDays дней',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              _buildPeriodToggle(theme, zen),
            ],
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

  /// Переключатель периода графика: 7д / 14д / 30д.
  Widget _buildPeriodToggle(ThemeData theme, ZenStyles zen) {
    return ToggleButtons(
      isSelected: [
        _selectedPeriod == _ChartPeriod.days7,
        _selectedPeriod == _ChartPeriod.days14,
        _selectedPeriod == _ChartPeriod.days30,
      ],
      onPressed: (index) {
        setState(() {
          _selectedPeriod = _ChartPeriod.values[index];
        });
        _reloadChartData();
      },
      borderRadius: BorderRadius.circular(zen.cardRadius / 2),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 28),
      textStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
      selectedColor: theme.colorScheme.primary,
      fillColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      children: const [
        Text('7д'),
        Text('14д'),
        Text('30д'),
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
        clipData: FlClipData.all(),
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

  /// Блок "В среднем X в день" с анимированным счётчиком.
  ///
  /// Число анимированно увеличивается от 0 до финального значения
  /// при появлении блока или смене периода.
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
      child: _AnimatedMetricBlock(
        target: average,
        label: 'в среднем в день',
        valueStyle: theme.textTheme.headlineLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// =============================================================================
// Анимированный блок метрики
// =============================================================================

/// Блок метрики с анимированным счётчиком от 0 до [target].
///
/// Использует [TweenAnimationBuilder] для плавного увеличения числа
/// при появлении или смене значения [target].
class _AnimatedMetricBlock extends StatelessWidget {
  /// Целевое значение, до которого анимируется счётчик.
  final double target;

  /// Подпись под числом.
  final String label;

  /// Стиль для числа.
  final TextStyle? valueStyle;

  const _AnimatedMetricBlock({
    required this.target,
    required this.label,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final zen = Theme.of(context).extension<ZenStyles>() ?? ZenStyles.defaults;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Анимированное число
        FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 0),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(target),
              tween: Tween<double>(begin: 0, end: target),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Text(
                  TimeUtils.formatMinutes(value),
                  style: (valueStyle ??
                          theme.textTheme.displayLarge ?? const TextStyle())
                      .copyWith(
                    fontWeight: zen.metricWeight,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );
              },
            ),
          ),
        ),
        SizedBox(height: zen.spacingUnit), // 8px
        // Подпись
        Text(
          label,
          style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
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

/// Мини-карточка для отображения Streak / Growth.
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

// =============================================================================
// Dot Chart Painter
// =============================================================================

/// Кастомный painter для точечного графика динамики активности.
///
/// Рисует:
/// - Пунктирную линию среднего значения
/// - Соединительные линии между точками
/// - Кружки-точки для каждого дня
/// - Градиентную заливку под линией
class _DotChartPainter extends CustomPainter {
  final List<Offset> points;
  final double averageY;
  final Color primaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;

  _DotChartPainter({
    required this.points,
    required this.averageY,
    required this.primaryColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // 1. Рисуем пунктирную линию среднего значения
    final dashPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Рисуем пунктир вручную
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, averageY),
        Offset((startX + dashWidth).clamp(0, size.width), averageY),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // 2. Рисуем градиентную заливку под линией
    if (points.length >= 2) {
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withValues(alpha: 0.12),
            primaryColor.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      final fillPath = Path();
      fillPath.moveTo(points.first.dx, 56);
      for (final point in points) {
        fillPath.lineTo(point.dx, point.dy);
      }
      fillPath.lineTo(points.last.dx, 56);
      fillPath.close();

      canvas.drawPath(fillPath, gradientPaint);
    }

    // 3. Рисуем соединительные линии
    if (points.length >= 2) {
      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    // 4. Рисуем точки
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final isActive = point.dy < 54; // есть активность (не 0)

      if (isActive) {
        // Внешний круг (белый)
        canvas.drawCircle(point, 3.5, Paint()
          ..color = surfaceColor
          ..style = PaintingStyle.fill);
        // Внутренний круг (primary)
        canvas.drawCircle(point, 2.5, dotPaint);
      } else {
        // Маленькая точка для дней без активности
        canvas.drawCircle(point, 1.5, Paint()
          ..color = onSurfaceColor.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.averageY != averageY;
  }
}
